kx.printk("hi from lua! <3\n")

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

	return "0x" .. s
end

kx.printk("ultramem: ptr ")
kx.printk(toHex(y))
kx.printk(" (")
kx.printk(toHex(y - 0x800000))
kx.printk(" bytes, ")
kx.printk(toHex(n))
kx.printk(" allocs, ")
kx.printk(toHex(fr))
kx.printk(" free attempts)\n")
