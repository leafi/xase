local glue = require('glue')
local pp = require('pp')
local utf8 = require('utf8')

return function(path)
  local f = io.open(path, 'rb')
  local fcontents = f:read('*a')
  f:close()

  local toks = {}

  local accum = ''

  local keywords = {'function', 'if', 'then', 'end', 'else', 'elseif'}

  local function matchAccum()
    if accum ~= '' then
      local matched_kw = nil
      for i = 1,#keywords do
        if accum == keywords[i] then matched_kw = accum end
      end
      if matched_kw ~= nil then
        toks[#toks+1] = {'KW_' .. string.upper(matched_kw)}
      elseif string.match(accum, '[^%d]') == nil then
        toks[#toks+1] = {'INTEGER', accum}
      elseif #accum > 2 and string.find(accum, '0x') == 1 and string.match(accum, '[^%x]', 3) == nil then
        toks[#toks+1] = {'HEX', accum}
      elseif string.match(accum, '[^%d%.]') == nil then
        toks[#toks+1] = {'DECIMAL', accum}
      elseif string.match(accum, '[^%w_]') == nil then
        toks[#toks+1] = {'IDENTIFIER', accum}
      else
        error('Lexer: Could not classify accum entry "' .. accum .. '"')
      end
    end
    accum = ''
  end

  local brackets = {'(', ')', '[', ']', '{', '}', ':', ';', '+', '*', ','}
  local mode = 'normal'

  local function normalModeParse(byteidx, c)
    if string.match(c, '[%w_]') ~= nil then
      accum = accum .. c
    elseif c == '.' then
      -- decimal or .?
      if #accum > 0 and string.match(accum, '[^%d]') == nil then
        accum = accum .. '.'
      else
        matchAccum()
        toks[#toks+1] = {'.'}
      end
    else
      matchAccum()
      
      local fb = nil
      for i = 1,#brackets do
        if brackets[i] == c then fb = c end
      end

      if string.match(c, '%s') then
        -- just matching is fine
        -- unless it's \n. hue
        if c == '\n' then
          toks[#toks+1] = {';'}
        end
      elseif fb ~= nil then
        toks[#toks+1] = {fb}
      elseif c == '/' then
        -- -> maybe comment? mode
        mode = 'slash'
      elseif c == '"' then
        -- -> string mode
        mode = 'stringthick'
      elseif c == "'" then
        -- -> string mode
        mode = 'stringthin'
      else
        print('unrecognized char: ' .. c)
      end
    end
  end

  local function escChar(c)
    if c == 'r' then
      return '\r'
    elseif c == 'n' then
      return '\n'
    elseif c == '\r' then
      return nil -- suppress
    elseif c == '\n' then
      return '\n' -- continuation character (sorta kinda maybe)
    elseif c == 't' then
      return '\t'
    elseif c == '0' then
      return string.char(0)
    else
      return c
    end
  end

  --for byteidx, c in utf8.codes(fcontents) do
  for i = 1,#fcontents do
    local byteidx = i
    local c = string.sub(fcontents, i, i)

    if mode == 'normal' then
      normalModeParse(byteidx, c)
    elseif mode == 'slash' then
      if c == '*' then
        mode = 'slashstar'
      elseif c == '/' then
        mode = 'slashslash'
      else
        toks[#toks+1] = {'/'}
        mode = 'normal'
        normalModeParse(byteidx, c)
      end
    elseif mode == 'slashstar' then
      if c == '*' then mode = 'slashstarstar' end
    elseif mode == 'slashstarstar' then
      if c == '/' then
        mode = 'normal'
      else
        mode = 'slashstar'
      end
    elseif mode == 'slashslash' then
      if c == '\n' then mode = 'normal'; toks[#toks+1] = {';'} end
    elseif mode == 'stringthin' then
      if c == "'" then
        toks[#toks+1] = {'STRING_THIN', accum}
        accum = ''
        mode = 'normal'
      elseif c == '\\' then
        mode = 'stringthinEscape'
      else
        accum = accum .. c
      end
    elseif mode == 'stringthinEscape' then
      local ec = escChar(c)
      if ec ~= nil then
        accum = accum .. ec
        mode = 'stringthin'
      end
    elseif mode == 'stringthick' then
      if c == '"' then
        toks[#toks+1] = {'STRING_THICK', accum}
        accum = ''
        mode = 'normal'
      elseif c == '\\' then
        mode = 'stringthickEscape'
      else
        accum = accum .. c
      end
    elseif mode == 'stringthickEscape' then
      local ec = escChar(c)
      if ec ~= nil then
        accum = accum .. ec
        mode = 'stringthick'
      end
    else
      error('Lexer internal error: unimplemented lex mode ' .. mode)
    end
  end

  -- dedupe semicolons
  local tmp = toks
  toks = {}
  local lastsc = true
  for i = 1,#tmp do
    if tmp[i][1] == ';' then
      if not lastsc then toks[#toks+1] = tmp[i] end
      lastsc = true
    else
      lastsc = false
      toks[#toks+1] = tmp[i]
    end
  end


  return toks
end
