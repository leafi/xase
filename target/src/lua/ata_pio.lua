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
  else
    devstat = xstatus(ds)
    while devstat.busy do devstat = xstatus(kx.inb(bus.dcr)) end
    local lbm = kx.inb(bus.albamid)
    local lbh = kx.inb(bus.albahi)
    if lbm ~= 0 or lbh ~= 0 then
      local guess = 'unknown'
      -- sending IDENTIFY DEVICE instead of IDENTIFY PACKET DEVICE to an atapi device causes these signatures to appear...
      if lbm == 0x14 and lbh == 0xeb then guess = 'PATAPI' end
      if lbm == 0x69 and lbh == 0x96 then guess = 'SATAPI' end
      -- vv wouldn't expect this to trigger, but...
      if lbm == 0x3c and lbh == 0xc3 then guess = 'SATA' end
      dprint(' > ' .. sdev .. ': not real ata device (guess: ' .. guess .. '; ' .. lbm .. ', ' .. lbh .. '); ignoring.\n')
    else
      while not (devstat.error or devstat.dataready) do devstat = xstatus(kx.inb(bus.dcr)) end
      if devstat.error then
        dprint(' > ' .. sdev .. ': error while responding to IDENTIFY\n')
      else
        local iq = {}
        for i = 1,256 do iq[i] = kx.inw(bus.adata) end
        dprint(' > ' .. sdev .. ': IDENTIFY: ' .. iq[1] .. ' / ' .. iq[84] .. ' / ' .. iq[89] .. ' / ' .. iq[94] .. '\n')
      end
    end
  end
end

local function interrogate(bus)
  interrodrv(bus, false)
  interrodrv(bus, true)
end

function ata_pio.init()
  dprint("\nata_pio.init entry\n")

  -- hmm... TODO: reset first?

  local pristat = kx.inb(pri.acmdstatus)
  if pristat == 0xff then
    dprint('primary bus floating; no drives\n')
  else
    dprint('primary bus:\n')
    interrogate(pri)
  end
  local sndstat = kx.inb(snd.acmdstatus)
  if sndstat == 0xff then
    dprint('secondary bus floating; no drives\n')
  else
    dprint('secondary bus:\n')
    interrogate(snd)
  end

  

  dprint("ata_pio.init return\n")
end

-- woo!
ata_pio.init()

_G['ata_pio'] = ata_pio

return ata_pio
