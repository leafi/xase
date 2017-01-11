local ata_pio = {}

local pri = {
  base = 0x1f0,
  dcr = 0x3f6
}
local snd = {
  base = 0x170,
  dcr = 0x376
}
--[[local bus3 = {
  base = 0x1e8,
  dcr = 0x3e6
}
local bus4 = {
  base = 0x168,
  dcr = 0x366
}]]--

local function prep(bus)
  bus.adata = bus.base
  bus.afeatures = bus.base + 1
  bus.asectorcount = bus.base + 2
  bus.albalo = bus.base + 3
  bus.albamid = bus.base + 4
  bus.albahi = bus.base + 5
  bus.adrivesel = bus.base + 6
  bus.acmdstatus = bus.base + 7
  
  bus.devices = {}
end

prep(pri)
prep(snd)

local function rdata(bus)
  return kx.inb(bus.adata)
end
local function wdata(bus, b)
  kx.outb(bus.adata, b)
end

local function xstatus(stb)
  return {
    error = stb & 1 == 1,
    dataready = stb & 8 == 8,
    overlap = stb & 16 == 16,
    fault = stb & 32 == 32,
    ready = stb & 64 == 64,
    busy = stb & 128 == 128
  }
end

local function interrodrv(bus, slave)
  local device = {
    bus = bus,
    master = not slave,
    slave = slave,
    ok = false,
    type = 'unknown'
  }

  local sdev = slave and 'slave' or 'master'
  -- select master device
  kx.outb(bus.adrivesel, slave and 0xb0 or 0xa0)
  -- 400ns delay
  for i = 1,4 do kx.inb(bus.dcr) end
  local devstat = xstatus(kx.inb(bus.dcr))
  while devstat.busy do devstat = xstatus(kx.inb(bus.dcr)) end
  -- prep IDENTIFY
  kx.outb(bus.asectorcount, 0)
  kx.outb(bus.albalo, 0)
  kx.outb(bus.albamid, 0)
  kx.outb(bus.albahi, 0)
  kx.outb(bus.acmdstatus, 0xec) -- IDENTIFY
  local ds = kx.inb(bus.dcr)
  if ds == 0 then
    dprint(' > ' .. sdev .. ' does not exist\n')
    device = nil
  else
    devstat = xstatus(ds)
    while devstat.busy do devstat = xstatus(kx.inb(bus.dcr)) end
    local lbm = kx.inb(bus.albamid)
    local lbh = kx.inb(bus.albahi)
    if lbm ~= 0 or lbh ~= 0 then
      local guess = 'unknown'
      -- sending IDENTIFY DEVICE instead of IDENTIFY PACKET DEVICE to an atapi device causes these signatures to appear...
      if lbm == 0x14 and lbh == 0xeb then guess = 'patapi' end
      if lbm == 0x69 and lbh == 0x96 then guess = 'satapi' end
      -- vv wouldn't expect this to trigger, but...
      if lbm == 0x3c and lbh == 0xc3 then guess = 'sata' end
      dprint(' > ' .. sdev .. ': not real ata device (guess: ' .. guess .. '; ' .. lbm .. ', ' .. lbh .. '); ignoring.\n')
      device.type = guess
      device.ok = false
    else
      device.type = 'ata'
      while not (devstat.error or devstat.dataready) do devstat = xstatus(kx.inb(bus.dcr)) end
      if devstat.error then
        dprint(' > ' .. sdev .. ': error while responding to IDENTIFY\n')
        device.ok = false
      else
        local iq = {}
        for i = 1,256 do iq[i] = kx.inw(bus.adata) end
        dprint(' > ' .. sdev .. ': IDENTIFY: ' .. iq[1] .. ' / ' .. iq[84] .. ' / ' .. iq[89] .. ' / ' .. iq[94] .. '\n')
        device.ok = true
        device.ata_identify = iq
      end
    end
  end

  bus.devices[#bus.devices+1] = device

  if device ~= nil then
    device.hint = ((device.bus == pri) and 'Primary:' or 'Secondary:') .. (device.master and 'master' or 'slave')
  end
end

local function interrogate(bus)
  interrodrv(bus, false)
  interrodrv(bus, true)
end

function ata_pio.init()
  -- hmm... TODO: reset first?

  dprint('ATA PIO primary bus: ')
  local pristat = kx.inb(pri.acmdstatus)
  if pristat == 0xff then
    dprint('floating; no drives\n')
  else
    dprint('interrogating...\n')
    interrogate(pri)
  end

  dprint('ATA PIO secondary bus: ')
  local sndstat = kx.inb(snd.acmdstatus)
  if sndstat == 0xff then
    dprint('floating; no drives\n')
  else
    dprint('interrogating...\n')
    interrogate(snd)
  end

  if #pri.devices + #snd.devices == 0 then
    dprint('[ERR] No recognized hard disks! Cannot continue.\n')
  else
    ata_pio.find_xase()
  end
end

function ata_pio.interrogate_device_IDENTIFY(dev)
  dev.supported = {
    modes = {}
  }
  dev.mode = 'ata_pio_lba48'

  local function id(wordidx) return dev.ata_identify[wordidx+1] end

  -- data isn't incomplete b/c powered down..... please?
  if id(0) & 4 == 4 then
    dprint('[ERR] Device ' .. dev.hint .. ' is powered down! TODO: Implement SET FEATURES to spin up device & reinterrogate\n')
    return false
  end
  if id(0) & 0x8000 ~= 0 then
    dprint('[ERR] Device ' .. dev.hint .. ' said in IDENTIFY it is not really an ATA device. (bit 15 of word 0 not 0) Skipping...\n')
    return false
  end

  dev.names = {
    firmwarerevision = '',
    modelnumber = '',
    serialnumber = ''
  }

  local function word2c(w)
    local fst = w & 0xff
    local snd = (w >> 8) & 0xff
    return string.char(fst ~= 0 and fst or 0x20, snd ~= 0 and snd or 0x20)
  end

  for i=10,19 do
    dev.names.serialnumber = dev.names.serialnumber .. word2c(id(i))
  end

  for i=23,26 do
    dev.names.firmwarerevision = dev.names.firmwarerevision .. word2c(id(i))
  end

  for i=27,46 do
    dev.names.modelnumber = dev.names.modelnumber .. word2c(id(i))
  end

  -- maybe TODO word 47 READ/WRITE MULTIPLE limit?

  dev.supported.lba = (id(49) & 0x200) == 0x200
  if not dev.supported.lba then
    dprint('[WARN] Device ' .. dev.hint .. ' doesn\'t support LBA addressing?!\n')
    dev.ok = false
  end
  dev.supported.dma = (id(49) & 0x100) == 0x100

  local is64to70valid = (id(53) & 2) == 2
  -- note: expect above to be true!

  if not is64to70valid then
    dprint('[ERR] Device ' .. dev.hint .. ' says words 64..70 are invalid. CompactFlash...? Whatever, this device sucks.\n')
    return false
  end

  dev.supported.ultradma = (id(53) & 4) == 4
  -- ^ indicates whether word 88 is valid

  dev.supported.lba28max = (id(60) << 16) | id(61)
  -- ^ 1+max user addressable LBA for 28-bit commands
  dev.supported.lba28overflow = (dev.supported.lba28max == 0x0fffffff)
  -- => words 100..103 contain total number of user-addressable LBAs (48 bit i assume)

  -- Multiword DMA
  if dev.supported.dma then
    if id(63) & 0x4 == 0x4 then dev.supported.mdma2 = true; dev.supported.mdma1 = true; dev.supported.mdma0 = true end
    if id(63) & 0x2 == 0x2 then dev.supported.mdma1 = true; dev.supported.mdma0 = true end
    if id(63) & 0x1 == 0x1 then dev.supported.mdma0 = true end

    if id(63) & 0x400 == 0x400 then dev.mdmamode = 2 end
    if id(63) & 0x200 == 0x200 then dev.mdmamode = 1 end
    if id(63) & 0x100 == 0x100 then dev.mdmamode = 0 end
    -- Note: If an Ultra DMA mode is enabled, then no Multiword DMA mode shall be enabled.
  end

  if is64to70valid then
    if id(64) & 2 == 2 then dev.supported.pio4 = true end
    if id(64) & 1 == 1 then dev.supported.pio3 = true end

    -- skipping word 65: min multiword dma transfer cycle time per word
    -- skipping word 66: device recommended multiword dma transfer cycle time
    -- skipping word 67: min PIO transfer cycle time without IORDY flow control
    -- skipping word 68: min PIO transfer cycle time *with* IORDY flow control

    -- skipping TRIM, long physical sector alignment error reporting control parts of word 69

    if id(69) & 0x1000 == 0x1000 then
      dev.supported.deviceConfigurationIdentifyDma = true
      dev.supported.deviceConfigurationSetDma = true
    end
    if id(69) & 0x800 == 0x800 then dev.supported.readBufferDma = true end
    if id(69) & 0x400 == 0x400 then dev.supported.writeBufferDma = true end
    if id(69) & 0x100 == 0x100 then dev.supported.downloadMicrocodeDma = true end
  end

  -- skipping word 75: queue depth (TCQ, NCQ???)
  -- skipping word 76: SATA capabilities
  -- skipping word 78: Serial ATA features supported
  -- skipping word 79: Serial ATA features enabled

  if id(80) ~= 0 and id(80) ~= 0xffff then
    dev.ata_major = id(80)
    dev.ata_minor = id(81)
  end

  -- oh god, so much shit in words 82..84!!!!!!

  -- oh god, oh god, 85..87 too.......

  if dev.supported.ultradma then
    if (id(88) & (1 << 13)) > 0 then dev.udmamode = 6 end
    if (id(88) & (1 << 12)) > 0 then dev.udmamode = 5 end
    if (id(88) & (1 << 11)) > 0 then dev.udmamode = 4 end
    if (id(88) & (1 << 10)) > 0 then dev.udmamode = 3 end
    if (id(88) & (1 << 9)) > 0 then dev.udmamode = 2 end
    if (id(88) & (1 << 8)) > 0 then dev.udmamode = 1 end
    if (id(88) & (1 << 7)) > 0 then dev.udmamode = 0 end

    dev.supported.udma6 = id(88) & 0x40 == 0x40
    dev.supported.udma5 = id(88) & 0x20 == 0x20
    dev.supported.udma4 = id(88) & 0x10 == 0x10
    dev.supported.udma3 = id(88) & 0x08 == 0x08
    dev.supported.udma2 = id(88) & 0x04 == 0x04
    dev.supported.udma1 = id(88) & 0x02 == 0x02
    dev.supported.udma0 = id(88) & 0x01 == 0x01
    if id(88) & 0xff == 0 then dev.supported.ultradma = false end
  end

  if dev.supported.lba28overflow then
    dev.supported.lba48maxhi = id(100) << 16 | id(101)
    dev.supported.lba48maxlo = id(102) << 16 | id(103)
  end

  if (id(217) > 0x0400) and (id(217) < 0xffff) then dev.rpm = id(217) end




  return dev.ok
end

function ata_pio.check1_xase_device(dev)
  if not ata_pio.interrogate_device_IDENTIFY(dev) then return false end

  return true
end

function ata_pio.find_xase()
  local maybe = {}
  for _,device in ipairs(pri.devices) do
    if device.ok and device.type == 'ata' then maybe[#maybe+1] = device end
  end
  for _,device in ipairs(snd.devices) do
    if device.ok and device.type == 'ata' then maybe[#maybe+1] = device end
  end

  local maybe2 = {}
  for _,device in ipairs(maybe) do
    if ata_pio.check1_xase_device(device) then maybe2[#maybe2+1] = device end
  end

  for _,device in ipairs(maybe2) do
  end
end

-- woo!
ata_pio.init()

_G['ata_pio'] = ata_pio

return ata_pio
