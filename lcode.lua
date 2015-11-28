print("hi from lua! <3")

local y, n, fr = kx.ultramem()

local function toHex(x)
	local s = ""

	local function toHexDigit(i)
		if i == 0 then
			return "0"
		elseif i == 1 then
			return "1"
		elseif i == 2 then
			return "2"
		elseif i == 3 then
			return "3"
		elseif i == 4 then
			return "4"
		elseif i == 5 then
			return "5"
		elseif i == 6 then
			return "6"
		elseif i == 7 then
			return "7"
		elseif i == 8 then
			return "8"
		elseif i == 9 then
			return "9"
		elseif i == 10 then
			return "a"
		elseif i == 11 then
			return "b"
		elseif i == 12 then
			return "c"
		elseif i == 13 then
			return "d"
		elseif i == 14 then
			return "e"
		elseif i == 15 then
			return "f"
		else
			return "Z"
		end
	end

	while x > 0 do
		s = toHexDigit(x & 15) .. s
		x = x >> 4
	end
	
	if s == "" then
    return "0x0"
	end

	return "0x" .. s
end

print(string.format("ultramem: ptr 0x%x (%d bytes, %d allocs, %d free attempts)", y, y - 0x800000, n, fr))
print(string.format("peeks: ub 0x%x, uw 0x%x, ud 0x%x, sq 0x%x", kx.peekub(0x600000), kx.peekuw(0x600000), kx.peekud(0x600000), kx.peeksq(0x600000)))

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
  kx.printk(string.format("ven 0x%x dev 0x%x", ven, dev))
end

local function checkUsb(bus, slot, fun)
  local progif = (pciread(bus, slot, fun, 0x8) >> 8) & 0xff
  if progif == 0x00 then
    kx.printk("USB1 UHCI")
  elseif progif == 0x10 then
    kx.printk("USB1 OHCI")
  elseif progif == 0x20 then
    kx.printk("USB2 EHCI")
  elseif progif == 0x80 then
    kx.printk("USB ? (0x80)")
  elseif progif == 0xfe then
    kx.printk("USB (Not Host Controller) (0xfe)")
  else
    kx.printk("USB????? ")
    kx.printk(toHex(progif))
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
  kx.printk("\n")
  kx.printk(toHex(baseClass))
  kx.printk(":")
  kx.printk(toHex(subClass))
  kx.printk(" ")
  kx.printk(pciByClass[baseClass][subClass][1])
  local cf = pciByClass[baseClass][subClass][2]
  if cf then
    kx.printk("\n    ")
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
  kx.printk("Multifunction device. TODO: CODE FOR THIS!!!")
  return
else
  kx.printk("pci 0 is single-function; OK\n")
  checkBus(0)
end
