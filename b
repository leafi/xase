export PREFIX="$HOME/opt/cross"
export PATH="$PATH:$PREFIX/bin"

# SHOULD BE -mno-sse as we're not enabled properly, but it should be ok
export CC="$HOME/opt/cross/bin/x86_64-elf-gcc -ffreestanding -mno-red-zone -mno-mmx -mno-sse2 -Wall"

libluacc ()
{
  echo 3rdparty/lua-5.3.1/src/$1
  $CC -Itarget/3rdparty/lua-5.3.1/src -Itarget/3rdparty/minic -o build/lua/${1}.o -c target/3rdparty/lua-5.3.1/src/${1}.c
}

minicc ()
{
  echo 3rdparty/minic/$1
  $CC -Itarget/3rdparty/minic -o build/minic/${1}.o -c target/3rdparty/minic/${1}.c
}

syslua ()
{
  echo src/lua/${1}
  mono host/tools/LuaToHex/LuaToHex/bin/Debug/LuaToHex.exe target/src/lua/${1} >>build/syslua.h
  echo "  lua_pushstring(L, target_src_lua_${2});" >>build/syslua_kxdata_meta.h
  echo "  lua_setfield(L, tableidx, \"luasrc_${2}\");" >>build/syslua_kxdata_meta.h
  echo "  " >>build/syslua_kxdata_meta.h
}

mkdir build >/dev/null 2>&1
mkdir build/minic >/dev/null 2>&1
mkdir build/base >/dev/null 2>&1
mkdir build/lua >/dev/null 2>&1

libluacc lapi || exit 1
libluacc lcode || exit 1
libluacc lctype || exit 1
libluacc ldebug || exit 1
libluacc ldo || exit 1
libluacc ldump || exit 1
libluacc lfunc || exit 1
libluacc lgc || exit 1
libluacc llex || exit 1
libluacc lmem || exit 1
libluacc lobject || exit 1
libluacc lopcodes || exit 1
libluacc lparser || exit 1
libluacc lstate || exit 1
libluacc lstring || exit 1
libluacc ltable || exit 1
libluacc ltm || exit 1
libluacc lundump || exit 1
libluacc lvm || exit 1
libluacc lzio || exit 1

libluacc lauxlib || exit 1
libluacc lbaselib || exit 1
libluacc lbitlib || exit 1
libluacc lcorolib || exit 1
libluacc ldblib || exit 1
# libluacc liolib || exit 1
# libluacc lmathlib || exit 1
# libluacc loslib || exit 1
libluacc lstrlib || exit 1
libluacc ltablib || exit 1
libluacc lutf8lib || exit 1
libluacc loadlib || exit 1
libluacc linit || exit 1

minicc math || exit 1
minicc stdio || exit 1
minicc stdlib || exit 1
minicc string || exit 1
minicc errno || exit 1

echo "minic/setjmp (ASM)"
$CC -o build/minic/setjmp.o -c target/3rdparty/minic/setjmp.S || exit 1

echo "src/base/start"
$CC -o build/base/start.o -c target/src/base/start.c || exit 1

echo "clumping syslua"
rm build/syslua.h >/dev/null 2>&1
rm build/syslua_kxdata_meta.h >/dev/null 2>&1

syslua lcode.lua lcode_lua || exit 1
syslua ps2.lua ps2_lua || exit 1
syslua bdf_font.lua bdf_font_lua || exit 1
syslua bisqit.lua bisqit_lua || exit 1

syslua gohufont11.bdf gohufont11_bdf || exit 1
syslua gohufont14.bdf gohufont14_bdf || exit 1

echo "src/base/lua2 (with included syslua)"
$CC -Itarget/3rdparty/lua-5.3.1/src -Itarget/3rdparty/minic -Ibuild -o build/base/lua2.o -c target/src/base/lua2.c || exit 1

# NO libtcc1

echo "Linking..."

export P="build/lua/"
export B="build/base/"
export M="build/minic/"
$CC -ffreestanding -T target/src/base/linker.ld -nostdlib -lgcc -o build/KERNEL64.SYS ${B}start.o ${B}lua2.o ${P}lapi.o ${P}lauxlib.o ${P}lbaselib.o ${P}lbitlib.o ${P}lcorolib.o ${P}lctype.o ${P}ldblib.o ${P}ldebug.o ${P}ldo.o ${P}ldump.o ${P}lfunc.o ${P}lgc.o ${P}linit.o ${P}llex.o ${P}lmem.o ${P}loadlib.o ${P}lobject.o ${P}lopcodes.o ${P}lparser.o ${P}lstate.o ${P}lstring.o ${P}lstrlib.o ${P}ltable.o ${P}ltablib.o ${P}ltm.o ${P}lcode.o ${P}lundump.o ${P}lutf8lib.o ${P}lvm.o ${P}lzio.o ${M}math.o ${M}setjmp.o ${M}stdio.o ${M}stdlib.o ${M}string.o ${M}errno.o || exit 1

echo "Composing..."
cp host/tools/empty_64mb_fat32.img fat.img
mmd -i fat.img ::/EFI
mmd -i fat.img ::/EFI/BOOT
mmd -i fat.img ::/XASE
cp target/xase-uefi/XaseUefi.efi build/BOOTX64.EFI
mcopy -i fat.img build/BOOTX64.EFI ::/EFI/BOOT
mcopy -i fat.img build/KERNEL64.SYS ::/XASE


