local bdf = {}

function bdf.parse(s)
  local t = {}

  -- iterate over lines in buffer, ignoring empty lines
  local lines = string.gmatch(s, "[^\r\n]+")

  for line in lines do
    local word = string.match(line, "(%a+)")

    -- TODO: sizing, ascent/descent, all the meta shit...

    if word == "STARTCHAR" then
      local c = {comment=string.match(line, "%a+ ?(.*)")}
      for cline in lines do
        local cword = string.match(cline, "(%a+)")
        if cword == "ENCODING" then
          c.encoding = string.match(cline, "ENCODING (%d+)")
        elseif cword == "BBX" then
          local x1, x2, x3, x4 = string.match(cline, "BBX (%d+) (%d+) ([%-%d]+) ([%-%d]+)")
          c.w = x1
          c.h = x2
          c.x = x3
          c.y = x4
        elseif cword == "BITMAP" then
          c.bitmap = {}
          for bmpline in lines do
            if bmpline == "ENDCHAR" then break end
            c.bitmap[#c.bitmap+1] = bmpline
          end
          break
        end
      end
      t[tonumber(c.encoding)] = c
    end

  end

  return t
end

function bdf.init()
  bdf.font = bdf.parse(kx.gohufont11())
end

function bdf.test()
  local f = bdf.font
  local vid = kx.getgopbase()
  local msg = "hi there..."

  local stride = 800*4

  for y=1,15 do
    kx.pokeub(vid+stride*y, 255)
    kx.pokeub(vid+1+stride*y, 255)
    kx.pokeub(vid+2+stride*y, 255)
    --kx.pokeub(vid+3+stride*y, 255)
  end
  
end



-- hax for now
_G["bdf"] = bdf

return bdf

