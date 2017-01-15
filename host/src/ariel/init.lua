local glue = require('glue')
local tuple = require('tuple')
local pp = require('pp')
local time = require('time')

-- threading TODO??? maybe :s

require('strict')

local i_need_an_adult = false

if #arg < 1 then i_need_an_adult = true end

-- TODO: proper command line parser...
-- i'm about to write a programming language parser, and i don't really want to start
-- that off by writing a command line parser before i even begin. just, no-one has time for that shit...

local valid = {
  ["help"] = 1,
  ["lex"] = 2
}

if #arg >= 1 then
  if arg[1] == nil then
    print(arg[1] .. ': unrecognized sub-command')
    i_need_an_adult = true
  elseif #arg ~= valid[arg[1]] then
    print(arg[1] .. ': wrong number of args (expected ' .. valid[arg[1]] .. 'inc. sub-command, saw ' .. #arg .. ')')
    i_need_an_adult = true
  end
end

if arg[1] == 'help' then i_need_an_adult = true end

local function showhelp()
  print [[
Commands:
  ariel help -- Shows this help message
  ariel lex file.ari -- Lex crap...!
]]
end

if i_need_an_adult then
  showhelp()
elseif arg[1] == 'lex' then
  pp.print(require('host/src/ariel/lexer')(arg[2]))
end
