print("hi from lua! <3")

print("load bdf..")

-- global!
function dprint(s)
  kx.printk(s)
  bdf.print(s)
end

function requiron(subpath)
  local kxd = kxdata[subpath]
  assert(load(kxd.bin, kxd.path))()
end

requiron('bdf_font.lua')
--assert(load(kxdata.luasrc_bdf_font_lua, "luasrc/bdf_font.lua"))()

bdf.init()
dprint("graphical framebuffer & bdf font up\n")
dprint("ps2 init...\n")

requiron('ps2.lua')
--assert(load(kxdata.luasrc_ps2_lua, "luasrc/ps2.lua"))()
ps2.init()

dprint("PS2 OK\n")

dprint("bisqit...\n")

requiron('bisqit.lua')
--assert(load(kxdata.luasrc_bisqit_lua, "luasrc/bisqit.lua"))()
bisqit.init()


local y, n, fr = kx.ultramem()

dprint(string.format("ultramem: ptr 0x%x (%d bytes, %d allocs, %d free attempts)\n", y, y - 0x800000, n, fr))
dprint(string.format("peeks: ub 0x%x, uw 0x%x, ud 0x%x, sq 0x%x\n", kx.peekub(0x600000), kx.peekuw(0x600000), kx.peekud(0x600000), kx.peeksq(0x600000)))

-------------------------
-- enumerating pci bus.. 
-------------------------

-- read dword (uint32) from pci config space
local function pciread(bus, slot, fun, offset)
  local address = (bus << 16) | (slot << 11) | (fun << 8) | (offset & 0xfc) | 0x80000000
  kx.outd(0xcf8, address)
  return kx.ind(0xcfc)
end

local function pciGetHeaderType(bus, slot, fun)
  local bhlc = pciread(bus, slot, fun, 0x0c)
  return (bhlc >> 16) & 0xff
end

local function pciGetVendor(bus, slot, fun)
  return pciread(bus, slot, fun, 0) & 0xffff
end

local function checkIde(bus, slot, fun)
  
end

local function checkNet(bus, slot, fun)
  local vd = pciread(bus, slot, fun, 0)
  local ven = vd & 0xffff
  local dev = (vd >> 16) & 0xffff
  dprint(string.format("ven 0x%x dev 0x%x", ven, dev))
end

local function checkUsb(bus, slot, fun)
  local progif = (pciread(bus, slot, fun, 0x8) >> 8) & 0xff
  if progif == 0x00 then
    dprint("USB1 UHCI")
  elseif progif == 0x10 then
    dprint("USB1 OHCI")
  elseif progif == 0x20 then
    dprint("USB2 EHCI")
  elseif progif == 0x80 then
    dprint("USB ? (0x80)")
  elseif progif == 0xfe then
    dprint("USB (Not Host Controller) (0xfe)")
  else
    dprint("USB????? ")
    dprint(string.format("0x%x", progif))
  end
end 

local pciByClass = {
  [0x1]={
    [0x1]={"IDE Controller",checkIde}
  },
  [0x2]={[0x0]={"Ethernet Controller",checkNet}},
  [0x3]={[0x0]={"VGA-Compatible Controller/8512-Compatible Controller",nil}},
  [0x6]={[0x0]={"Host Bridge",nil}, [0x1]={"ISA Bridge",nil}, [0x80]={"Other Bridge Device",nil}},
  [0xc]={[0x3]={"USB",checkUsb}}
}

local function checkFunc(bus, slot, fun)
  local thing8 = pciread(bus, slot, fun, 0x8)
  local baseClass = thing8 >> 24
  local subClass = (thing8 >> 16) & 0xff
  dprint("\n")
  dprint(string.format("0x%x", baseClass))
  dprint(":")
  dprint(string.format("0x%x", subClass))
  dprint(" ")
  dprint(pciByClass[baseClass][subClass][1])
  local cf = pciByClass[baseClass][subClass][2]
  if cf then
    dprint("\n    ")
    cf(bus, slot, fun)
  end
  
  
  -- TODO: check if pci bridge!
end

local function checkSlot(bus, slot)
  local vendorId = pciGetVendor(bus, slot, 0)
  if vendorId ~= 0xffff then
    checkFunc(bus, slot, 0)
    if (pciGetHeaderType(bus, slot, 0) & 0x80) > 0 then
      -- multi-func!
      for fun=1,8 do
        if pciGetVendor(bus, slot, fun) ~= 0xffff then
          checkFunc(bus, slot, fun)
        end
      end
    end
  end
end

local function checkBus(bus)
  for i=0,31 do
    checkSlot(bus, i)
  end
end

local isMulti = (pciGetHeaderType(0,0,0) & 0x80) > 0 

if isMulti then
  dprint("Multifunction device. TODO: CODE FOR THIS!!!")
  return
else
  dprint("pci 0 is single-function; OK\n")
  checkBus(0)
end

dprint("\nEnd.")


