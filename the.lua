local gb = bc.unsmuggleGOPBase()
local gs = bc.unsmuggleGOPSize()

for i = gb,gb+gs-1,4 do
    bc.pokeb(i+3, bc.peekb(i+2))
    bc.pokeb(i+2, 0)
end

