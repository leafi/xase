local glue = require('glue')
local lfs = require('lfs')
local tuple = require('tuple')
local pp = require('pp')
local time = require('time')
local xxhash = require('xxhash')

-- threading TODO....

require('strict')

-- is a shell available?
if os.execute() == 0 then error('os.execute() reported no shell available') end

local nos = require('ffi').os
local win = nos == 'Windows'
local osx = nos == 'OSX'
local linux = (nos == 'Linux') or (nos == 'BSD') or (nos == 'POSIX') or (nos == 'Other')
nos = nil

if win then error('No windows support yet :(') end

local cc = os.getenv('HOME') .. '/opt/cross/bin/x86_64-elf-gcc -ffreestanding -mno-red-zone -mno-mmx -mno-sse2 -Wall '

local out_base = {}
local out_minic = {}
local out_lua = {}

local function checkmkdir(path)
  if lfs.attributes(path) == nil then
    print('Creating directory ' .. path)
    if not lfs.mkdir(path) then error('Failed to create dir') end
  end
end

local function trycc(xtra)
  local retval = os.execute(cc .. xtra)
  if retval ~= 0 then error('CC returned status code ' .. retval) end
end

checkmkdir 'target/.build'
checkmkdir 'target/.build/3rdparty'
checkmkdir 'target/.build/3rdparty/lua-5.3.1'
checkmkdir 'target/.build/3rdparty/minic'
checkmkdir 'target/.build/base'

-- left out: liolib, lmathlib, loslib
local libluas = {
  'lapi', 'lcode', 'lctype', 'ldebug', 'ldo', 'ldump', 'lfunc',
  'lgc', 'llex', 'lmem', 'lobject', 'lopcodes', 'lparser', 'lstate',
  'lstring', 'ltable', 'ltm', 'lundump', 'lvm', 'lzio', 'lauxlib',
  'lbaselib', 'lbitlib', 'lcorolib', 'ldblib', 'lstrlib', 'ltablib',
  'lutf8lib', 'loadlib', 'linit'
}

for _,s in ipairs(libluas) do
  print('3rdparty/lua-5.3.1/src/' .. s)
  trycc('-Itarget/3rdparty/lua-5.3.1/src -Itarget/3rdparty/minic -o target/.build/3rdparty/lua-5.3.1/' .. s .. '.o -c target/3rdparty/lua-5.3.1/src/' .. s .. '.c')
  out_lua[#out_lua+1] = 'target/.build/3rdparty/lua-5.3.1/' .. s .. '.o'
end

local minics = {'math', 'stdio', 'stdlib', 'string', 'errno'}

for _,s in ipairs(minics) do
  print('3rdparty/minic/' .. s)
  trycc('-Itarget/3rdparty/minic -o target/.build/3rdparty/minic/' .. s .. '.o -c target/3rdparty/minic/' .. s .. '.c')
  out_minic[#out_minic+1] = 'target/.build/3rdparty/minic/' .. s .. '.o'
end

print('3rdparty/minic/setjmp (ASM)')
trycc('-o target/.build/3rdparty/minic/setjmp.o -c target/3rdparty/minic/setjmp.S')
out_minic[#out_minic+1] = 'target/.build/3rdparty/minic/setjmp.o'

print('src/base/start')
trycc('-o target/.build/base/start.o -c target/src/base/start.c')
out_base[#out_base+1] = 'target/.build/base/start.o'

print('Composing syslua...')
local syslua_h = io.open('target/.build/syslua.h', 'w+b')
local syslua_kxdata_h = io.open('target/.build/syslua_kxdata_meta.h', 'w+b')

local sysluas = {
  'lcode.lua', 'ps2.lua', 'bdf_font.lua', 'bisqit.lua', 'gohufont11.bdf', 'gohufont14.bdf',
  'ata_pio.lua'
}

for _,path in ipairs(sysluas) do
  local fullpath = 'target/src/lua/' .. path
  local notfullpath = 'src/lua/' .. path

  local nom = 'luasrc_' .. path
  local fromto = {
    {'%.', '_'},
    {'/', '_'},
    {'\\', '_'},
    {' ', '_'}
  }
  for _, ft in ipairs(fromto) do nom = string.gsub(nom, ft[1], ft[2]) end

  print(' > ' .. nom .. ': ' .. notfullpath)

  local f = io.open(fullpath, 'rb')
  local fcontents = f:read('*a')
  f:close()

  -- mono host/tools/LuaToHex/LuaToHex/bin/Debug/LuaToHex.exe target/src/lua/${1} >>build/syslua.h

  local pah = {}
  for i = 1,#fcontents do
    local x = string.byte(fcontents, i)
    pah[#pah+1] = '0x' .. string.format('%02x', x)
  end
  -- add null terminator for c string
  pah[#pah+1] = '0x00'
  local bigpah = table.concat(pah, ', ')
  syslua_h:write('char ' .. nom .. '[] = {' .. bigpah .. '};\n')

  syslua_kxdata_h:write('  lua_newtable(L);\n')
  syslua_kxdata_h:write('  tmp = lua_gettop(L);\n')
  syslua_kxdata_h:write('  lua_pushstring(L, "' .. notfullpath .. '");\n')
  syslua_kxdata_h:write('  lua_setfield(L, tmp, "path");\n')
  syslua_kxdata_h:write('  lua_pushstring(L, ' .. nom .. ');\n')
  syslua_kxdata_h:write('  lua_setfield(L, tmp, "bin");\n')
  syslua_kxdata_h:write('  lua_setfield(L, tableidx, "' .. path .. '");\n')
  syslua_kxdata_h:write('  \n')
end

syslua_h:flush()
syslua_kxdata_h:flush()
syslua_h:close()
syslua_kxdata_h:close()

print('src/base/lua2 (with clumped syslua)')
trycc('-Itarget/3rdparty/lua-5.3.1/src -Itarget/3rdparty/minic -Itarget/.build -o target/.build/base/lua2.o -c target/src/base/lua2.c')
out_base[#out_base+1] = 'target/.build/base/lua2.o'

local linkcc = '-T target/src/base/linker.ld -nostdlib -lgcc -o target/.build/KERNEL64.SYS '
for _,obj in ipairs(out_base) do linkcc = linkcc .. obj .. ' ' end
for _,obj in ipairs(out_lua) do linkcc = linkcc .. obj .. ' ' end
for _,obj in ipairs(out_minic) do linkcc = linkcc .. obj .. ' ' end
print('Linking...') -- (' .. cc .. linkcc .. ')')
trycc(linkcc)

print('Composing...')
if lfs.attributes('fat.img') ~= nil then os.remove('fat.img') end
if lfs.attributes('target/.build/BOOTX64.EFI') ~= nil then os.remove('target/.build/BOOTX64.EFI') end
local compose_steps = {
  'cp host/tools/empty_64mb_fat32.img fat.img',
  'mmd -i fat.img ::/EFI',
  'mmd -i fat.img ::/EFI/BOOT',
  'mmd -i fat.img ::/XASE',
  'cp target/xase-uefi/XaseUefi.efi target/.build/BOOTX64.EFI',
  'mcopy -i fat.img target/.build/BOOTX64.EFI ::/EFI/BOOT',
  'mcopy -i fat.img target/.build/KERNEL64.SYS ::/XASE'
}
for _,s in ipairs(compose_steps) do
  if os.execute(s) ~= 0 then error('Failed: ' .. s) end
end

print('OK')


