export PREFIX="$HOME/opt/cross"
export PATH="$PATH:$PREFIX/bin"

# SHOULD BE -mno-sse as we're not enabled properly, but it should be ok
export CC="$HOME/opt/cross/bin/x86_64-elf-gcc -ffreestanding -mno-red-zone -mno-mmx -mno-sse2 -Wall"

luacc ()
{
  echo $1
  $CC -Ilibs2/lua-5.3.1/src -Ilibs2/minic -o build/lua/${1}.o -c libs2/lua-5.3.1/src/${1}.c
}

minicc ()
{
  echo minic/$1
  $CC -Ilibs2/minic -o build/minic/${1}.o -c libs2/minic/${1}.c
}


mkdir build >/dev/null 2>&1
mkdir build/minic >/dev/null 2>&1
mkdir build/base >/dev/null 2>&1
mkdir build/lua >/dev/null 2>&1

luacc lapi || exit 1
luacc lcode || exit 1
luacc lctype || exit 1
luacc ldebug || exit 1
luacc ldo || exit 1
luacc ldump || exit 1
luacc lfunc || exit 1
luacc lgc || exit 1
luacc llex || exit 1
luacc lmem || exit 1
luacc lobject || exit 1
luacc lopcodes || exit 1
luacc lparser || exit 1
luacc lstate || exit 1
luacc lstring || exit 1
luacc ltable || exit 1
luacc ltm || exit 1
luacc lundump || exit 1
luacc lvm || exit 1
luacc lzio || exit 1

luacc lauxlib || exit 1
luacc lbaselib || exit 1
luacc lbitlib || exit 1
luacc lcorolib || exit 1
luacc ldblib || exit 1
# luacc liolib || exit 1
# luacc lmathlib || exit 1
# luacc loslib || exit 1
luacc lstrlib || exit 1
luacc ltablib || exit 1
luacc lutf8lib || exit 1
luacc loadlib || exit 1
luacc linit || exit 1

minicc math || exit 1
minicc stdio || exit 1
minicc stdlib || exit 1
minicc string || exit 1
minicc errno || exit 1

echo "minic/setjmp (ASM)"
$CC -o build/minic/setjmp.o -c libs2/minic/setjmp.S || exit 1

echo "(root).start"
$CC -o build/base/start.o -c start.c || exit 1

echo "(root).lua"
$CC -Ilibs2/lua-5.3.1/src -Ilibs2/minic -o build/base/lua2.o -c lua2.c || exit 1

echo "(root).lcode"
mono tools/LuaToHex/LuaToHex/bin/Debug/LuaToHex.exe lcode.lua >build/lcode.c || exit 1
$CC -o build/base/lcode.o -c build/lcode.c || exit 1

# NO libtcc1

echo "Linking..."

export P="build/lua/"
export B="build/base/"
export M="build/minic/"
$CC -ffreestanding -T linker.ld -nostdlib -lgcc -o build/KERNEL64.SYS ${B}start.o ${B}lua2.o ${B}lcode.o ${P}lapi.o ${P}lauxlib.o ${P}lbaselib.o ${P}lbitlib.o ${P}lcode.o ${P}lcorolib.o ${P}lctype.o ${P}ldblib.o ${P}ldebug.o ${P}ldo.o ${P}ldump.o ${P}lfunc.o ${P}lgc.o ${P}linit.o ${P}llex.o ${P}lmem.o ${P}loadlib.o ${P}lobject.o ${P}lopcodes.o ${P}lparser.o ${P}lstate.o ${P}lstring.o ${P}lstrlib.o ${P}ltable.o ${P}ltablib.o ${P}ltm.o ${P}lundump.o ${P}lutf8lib.o ${P}lvm.o ${P}lzio.o ${M}math.o ${M}setjmp.o ${M}stdio.o ${M}stdlib.o ${M}string.o ${M}errno.o

echo "Composing..."
cp tools/empty_64mb_fat32.img fat.img
mmd -i fat.img ::/EFI
mmd -i fat.img ::/EFI/BOOT
mmd -i fat.img ::/XASE
cp xase-uefi/XaseUefi.efi build/BOOTX64.EFI
mcopy -i fat.img build/BOOTX64.EFI ::/EFI/BOOT
mcopy -i fat.img build/KERNEL64.SYS ::/XASE

