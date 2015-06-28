#mono tools/XSharp.Compiler/XSC.exe init.xs

# build EFI part
# TODO

# clone empty fat32 image & add files
# (uses mtools!)
cp tools/empty_64mb_fat32.img fat.img
mmd -i fat.img ::/EFI
mmd -i fat.img ::/EFI/BOOT
mmd -i fat.img ::/XASE

cp XaseUefi.efi BOOTX64.EFI
mcopy -i fat.img BOOTX64.EFI ::/EFI/BOOT

cp ~/because/tmp/kernel64.sys KERNEL64.SYS
mcopy -i fat.img KERNEL64.SYS ::/XASE

#mkdir iso
#cp fat.img iso/
#xorriso -as mkisofs -R -f -e fat.img -no-emul-boot -o cdimage.iso iso

# boot as if usb stick
qemu-system-x86_64 -pflash OVMF.fd -usb -usbdevice disk::fat.img

