local bdf = {}

function bdf.parse(s)
  local t = {}

  -- iterate over lines in buffer, ignoring empty lines
  local lines = string.gmatch(s, "[^\r\n]+")

  for line in lines do
    local word = string.match(line, "(%a+)")

    -- TODO: sizing, ascent/descent, all the meta shit...
    
    if word == "FONTBOUNDINGBOX" then
      local x1, x2 = string.match(line, "FONTBOUNDINGBOX (%d+) (%d+)")
      t.w = x1
      t.h = x2
    elseif word == "STARTCHAR" then
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
            c.bitmap[#c.bitmap+1] = tonumber(bmpline, 16)
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
  bdf.font = bdf.parse(kxdata.luasrc_gohufont14_bdf)
end

-- bleh persistent vars for crappy print func
local c = 0
local screen_width = 800

function bdf.print(msg)
  local f = bdf.font
  local vid = kx.getgopbase()
  --local msg = "Hi there, world(!)\n\nthis is a test\nof the system\to"

  local stride = screen_width*4

  local longs = screen_width//f.w

  local doublejump = stride * f.h

  --local c = 0
  for i=1,#msg do
    if string.sub(msg,i,i) == "\n" then
      c = ((c//longs)+1)*longs
    else
      local lst = vid+doublejump*(c//longs)+(c%longs)*4*f.w
      local ch = f[string.byte(string.sub(msg,i,i))]
      if not ch then ch = f[string.byte("?")] end
      lst = lst + ch.x * 4
      lst = lst + stride*(f.h-ch.h)
      lst = lst + stride*(-ch.y)
      if lst < vid then lst = lst - stride*(-ch.y) end

      --print("pri ch x,y,w,h " .. ch.x .. " " .. ch.y .. " " .. ch.w .. " " .. ch.h)

      for _, row in ipairs(ch.bitmap) do
        local pad = 8-(ch.w%8)
        if pad == 8 then pad = 0 end
        local t = 1 << (ch.w-1+pad)
        for x=1,ch.w do
          if (row & t) > 0 then
            kx.pokeub(lst+(x-1)*4, 255)
            kx.pokeub(lst+(x-1)*4+1, 255)
            kx.pokeub(lst+(x-1)*4+2, 255)
          end
          t = t >> 1
        end

        lst = lst + stride
      end


      c = c + 1
    end
  end

end



-- hax for now
_G["bdf"] = bdf

return bdf

