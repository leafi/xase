dd if=/dev/zero of=empty_64mb_fat32.img bs=1k count=64000
hdiutil attach -imagekey diskimage-class=CRawDiskImage -nomount empty_64mb_fat32.img

echo NOW DO newfs_msdos -F 32 /dev/disk5   , WHERE /dev/disk5 IS THE DEVICE ECHOED ABOVE
echo AFTERWARDS, DO e.g. hdiutil detach /dev/disk5

