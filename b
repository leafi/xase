#mono tools/XSharp.Compiler/XSC.exe init.xs

rm -rf build/ 2>&1 >/dev/null
mkdir build || exit

# build EFI part
# TODO

# build KERNEL64.SYS
echo compiling kernel64.sys

echo  kernel.c
$HOME/opt/cross/bin/x86_64-elf-gcc -m64 -o build/kernel.o -c kernel.c -Wall -Wextra -nostdlib -nostartfiles -nodefaultlibs -nostdinc -ffreestanding || exit
echo  lua.c
$HOME/opt/cross/bin/x86_64-elf-gcc -m64 -o build/lua.o -c lua.c -Wall -Wextra -nostdlib -nostartfiles -nodefaultlibs -nostdinc -ffreestanding -I ./libs/newlib/include -I ./libs/lua-5.3/include -I $HOME/opt/cross/lib/gcc/x86_64-elf/4.8.1/include || exit

echo  bits.asm
/usr/local/bin/nasm -f elf64 -o build/bits.o bits.asm || exit

echo linking kernel64.sys
$HOME/opt/cross/bin/x86_64-elf-ld -T linker64.ld -o KERNEL64.SYS build/kernel.o build/bits.o build/lua.o libs/lua-5.3/lib/liblua.a libs/newlib/lib/libm.a libs/newlib/lib/libc.a libs/newlib/lib/libnosys.a || exit


# clone empty fat32 image & add files
# (uses mtools!)
cp tools/empty_64mb_fat32.img fat.img
mmd -i fat.img ::/EFI
mmd -i fat.img ::/EFI/BOOT
mmd -i fat.img ::/XASE

cp XaseUefi.efi BOOTX64.EFI
mcopy -i fat.img BOOTX64.EFI ::/EFI/BOOT

mcopy -i fat.img KERNEL64.SYS ::/XASE

#mkdir iso
#cp fat.img iso/
#xorriso -as mkisofs -R -f -e fat.img -no-emul-boot -o cdimage.iso iso

# boot as if usb stick
qemu-system-x86_64 -pflash OVMF.fd -usb -usbdevice disk::fat.img

