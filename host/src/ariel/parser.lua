local vararg = require('vararg')

-- takes lexings, make parsings

return function(toks)
  local tidx = 1

  local last_matched = {}

  local function match(...)
    local p = vararg.pack(...)
    if tidx + p('#') > #toks then
      return false
    end
    for i=1,p('#') do
      if toks[tidx+i-1][1] ~= p(i) then return false end
    end

    local matched = {}
    for i=1,p('#') do
      matched[i] = toks[tidx+i-1]
    end
    tidx = tidx + p('#') - 1
    last_matched = matched
    return true
  end

  local function ident(nom)
    return {
      type = 'identifier',
      name = nom
    }
  end

  local function inequality(lhs, cmp, rhs)
    return {
      type = 'inequality',
      cmp = cmp,
      lhs = lhs,
      rhs = rhs
    }
  end

  local function defn(fargs, fbody)
    return {
      type = 'defn',
      fargs = fargs,
      fbody = fbody
    }
  end

  local function defncalln(fargs, fbody, callargs)
    return {
      type = 'defncalln',
      fargs = fargs,
      fbody = fbody,
      callargs = callargs
    }
  end

  local function index(what, how)
    return {
      type = 'index',
      lhs = what,
      rhs = how
    }
  end

  local function readargs()
    local exprs = {}

    while true do
      if match(')') then
        return exprs
      else
        local ex = expr()
        if ex == nil then
          error('did not expect dead expr here (readargs)')
        end
        exprs[#exprs+1] = ex
        if match(')') then
          return exprs
        elseif match(',') then
          -- nothing, continue
        else
          error('no , but no ) in args list!')
        end
      end
      if tidx > #toks then error('ran out of tokens (=> EOF) while parsing args list') end
    end
  end

  local function expr()
    if match('INTEGER') then
      return {
        type = 'constant',
        subtype = 'integer',
        value = last_matched[1][2]
      }
    elseif match('HEX') then
      return {
        type = 'constant',
        subtype = 'hex',
        value = last_matched[1][2]
      }
    elseif match('DECIMAL') then
      return {
        type = 'constant',
        subtype = 'decimal',
        value = last_matched[1][2]
      }
    elseif match('IDENTIFIER') then
      return ident(last_matched[1][2])
    
    local inequalities = {'!=', '==', '<=', '<', '>=', '>', '~='}
    for i=1,#inequalities do
      if match('IDENTIFIER', inequalities[i]) then
        return inequality(ident(last_matched[1][2]), inequalities[i], expr())
      end
    end

    if match('KW_FUNCTION', '(') then
      local fargs = readargs()
      local fbody = nil
      if match('{') then
        fbody = cmdlist('}')
      else
        fbody = cmdlist('KW_END')
      end
      if match('(') then
        local cargs = readargs()
        return defncalln(fargs, fbody, cargs)
      else
        return defn(fargs, fbody)
      end
    end

    if match('IDENTIFIER', '[') then
      local iexpr = index(last_matched[1][2], expr())
      if match(']') ~= true then error() end
      return iexpr
    end

    if match('IDENTIFIER', '(') then
    end



    if match('IDENTIFIER', '!=') then
      return inequality(ident(last_matched[1][2]), '!=', expr())
    elseif match('IDENTIFIER', '==') then

    end
  end

  local function newvar(identifier, rhs)
  end

  local function setvar(identifier, rhs)
  end

  local function cmdlist(need_end)
    local cl = {}
    local function appendcmd(cmd) cl[#cl+1] = cmd end

    while tidx <= #toks do
      if match('KW_LOCAL', 'IDENTIFIER', '=') then
        appendcmd(newvar(last_matched[2][2]))
      elseif match('IDENTIFIER', '=') then
        appendcmd(setvar(last_matched[1]))
      elseif match('KW_END') then
        return cl
      else
        error('couldn\'t match token ' .. toks[tidx][1] .. ' inside parser.cmdlist')
      end
    end

    if need_end ~= nil and need_end ~= false then error('KW_END missing') end
  end

  local parsed = {}

  while tidx < #toks do
    if match('KW_LOCAL', 'IDENTIFIER', '=') then
    elseif match('IDENTIFIER', '=') then
    else
      error("couldn't match token " .. toks[tidx][1] .. " at this time")
    end
  end

  return parsed
end
