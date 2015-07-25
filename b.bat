@echo off
set CC=tools\tcc-win64-elf\tcc.exe
set QEMU="c:\program files (x86)\qemu\qemu-system-x86_64.exe"

mkdir build >/dev/null 2>&1
mkdir build\minic >/dev/null 2>&1
mkdir build\base >/dev/null 2>&1
mkdir build\lua >/dev/null 2>&1

rem library: lapi.c lcode.c lctype.c ldebug.c ldo.c ldump.c lfunc.c lgc.c llex.c lmem.c lobject.c lopcodes.c lparser.c lstate.c lstring.c ltable.c ltm.c lundump.c lvm.c lzio.c
rem lauxlib.c lbaselib.c lbitlib.c lcorolib.c ldblib.c liolib.c lmathlib.c loslib.c lstrlib.c ltablib.c lutf8lib.c loadlib.c linit.c

call:cc lapi
call:cc lcode
call:cc lctype
call:cc ldebug
call:cc ldo
call:cc ldump
call:cc lfunc
call:cc lgc
call:cc llex
call:cc lmem
call:cc lobject
call:cc lopcodes
call:cc lparser
call:cc lstate
call:cc lstring
call:cc ltable
call:cc ltm
call:cc lundump
call:cc lvm
call:cc lzio

call:cc lauxlib
call:cc lbaselib
call:cc lbitlib
call:cc lcorolib
call:cc ldblib
REM call:cc liolib
REM call:cc lmathlib
REM call:cc loslib
call:cc lstrlib
call:cc ltablib
call:cc lutf8lib
call:cc loadlib
call:cc linit

call:minicc math
call:minicc stdio
call:minicc stdlib
call:minicc string

echo minic/setjmp (ASM)
%CC% -Wall -o build\minic\setjmp.o -c libs2\minic\setjmp.S || pause

echo (root).start
%CC% -Wall -o build\base\start.o -c start.c || pause

echo (root).lua
%CC% -Wall -Ilibs2\lua-5.3.1\src -Ilibs2\minic -o build\base\lua2.o -c lua2.c || pause

echo (root).lcode
tools\LuaToHex\LuaToHex\bin\Debug\LuaToHex.exe lcode.lua >build\lcode.c || pause
%CC% -Wall -o build\base\lcode.o -c build\lcode.c || pause

echo libtcc1
%CC% -Wall -Ilibs2\minic -o build\libtcc1.o -c libs2\libtcc1.c || pause

echo Linking...
set P=build\lua\
set B=build\base\
set M=build\minic\
%CC% -nostdlib -Wl,-Ttext,0x100000 -Wl,--oformat,binary -static %B%start.o build\libtcc1.o %B%lua2.o %B%lcode.o %P%lapi.o %P%lauxlib.o %P%lbaselib.o %P%lbitlib.o %P%lcode.o %P%lcorolib.o %P%lctype.o %P%ldblib.o %P%ldebug.o %P%ldo.o %P%ldump.o %P%lfunc.o %P%lgc.o %P%linit.o %P%llex.o %P%lmem.o %P%loadlib.o %P%lobject.o %P%lopcodes.o %P%lparser.o %P%lstate.o %P%lstring.o %P%lstrlib.o %P%ltable.o %P%ltablib.o %P%ltm.o %P%lundump.o %P%lutf8lib.o %P%lvm.o %P%lzio.o %M%math.o %M%setjmp.o %M%stdio.o %M%stdlib.o %M%string.o -o build\KERNEL64.SYS

echo Composing...
copy /y tools\empty_64mb_fat32.img fat.img
tools\mtools-win\mmd -i fat.img ::/EFI
tools\mtools-win\mmd -i fat.img ::/EFI/BOOT
tools\mtools-win\mmd -i fat.img ::/XASE
copy /y xase-uefi\XaseUefi.efi build\BOOTX64.EFI
tools\mtools-win\mcopy -i fat.img build\BOOTX64.EFI ::/EFI/BOOT
tools\mtools-win\mcopy -i fat.img build\KERNEL64.SYS ::/XASE

%QEMU% -debugcon vc -pflash tools\OVMF.fd -usb -usbdevice disk::fat.img

goto:eof

:cc
echo %~1
%CC% -Wall -Ilibs2\lua-5.3.1\src -Ilibs2\minic -o build\lua\%~1.o -c libs2\lua-5.3.1\src\%~1.c || pause
goto:eof

:minicc
echo minic/%~1
%CC% -Wall -Ilibs2\minic -o build\minic\%~1.o -c libs2\minic\%~1.c || pause
goto:eof
