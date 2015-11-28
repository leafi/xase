#include <Uefi.h>
#include <Guid/FileInfo.h>
#include <Library/UefiApplicationEntryPoint.h>
#include <Library/UefiLib.h>
#include <Protocol/LoadedImage.h>
#include <Protocol/SimpleFileSystem.h>

//UINT8 Buffer[1000000];

void reportError(EFI_STATUS err);
void waitKey();
void chk(EFI_STATUS status);

void after_write(char* string);

UINT8 Part2FileInfoBuffer[4096];
EFI_MEMORY_DESCRIPTOR memoryMap[4096];

EFI_SYSTEM_TABLE* ST;

typedef struct {
    void* GOPBase;
    UINT64 GOPSize;
    UINT32 GOPHorizontalResolution;
    UINT32 GOPVerticalResolution;
    UINT32 GOPPixelsPerScanLine;
} Smuggle;

/**
  The user Entry Point for Application. The user code starts with this function
  as the real entry point for the application.

  @param[in] ImageHandle    The firmware allocated handle for the EFI image.  
  @param[in] SystemTable    A pointer to the EFI System Table.
  
  @retval EFI_SUCCESS       The entry point is executed successfully.
  @retval other             Some error occurs when executing this entry point.

**/
EFI_STATUS
EFIAPI
UefiMain (
  IN EFI_HANDLE        ImageHandle,
  IN EFI_SYSTEM_TABLE  *SystemTable
  )
{
    UINT32 Index;
    EFI_LOADED_IMAGE_PROTOCOL* ImageInfo;
    EFI_GUID gEfiLoadedImageProtocol = EFI_LOADED_IMAGE_PROTOCOL_GUID;
    EFI_GUID gEfiSimpleFileSystemProtocol = EFI_SIMPLE_FILE_SYSTEM_PROTOCOL_GUID;
    EFI_GUID gEfiFileInfoGuid = EFI_FILE_INFO_ID;
    EFI_GUID gEfiGraphicsOutputProtocol = EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID;
    EFI_HANDLE* GopHandleBuffer;
    UINTN GopHandleCount;
    EFI_GRAPHICS_OUTPUT_PROTOCOL* Gop;
    EFI_SIMPLE_FILE_SYSTEM_PROTOCOL* SfsProt;
    EFI_FILE_PROTOCOL* Root;
    EFI_FILE_PROTOCOL* Part2;
    EFI_FILE_INFO* Part2FileInfo;
    UINTN Part2FileInfoSize = sizeof(Part2FileInfoBuffer);
    UINT8* buffer;
    //UINTN BufferSize = sizeof(Buffer);
    UINTN sz;

    // memory map
    EFI_STATUS getMmapStatus;
    UINTN memoryMapSize;
    UINTN mapKey;
    UINTN descriptorSize;
    UINT32 descriptorVersion;

    EFI_STATUS exitBootServicesStatus;

    UINT32 once = 0;

    ST = SystemTable;

    Index = 0;

    Print(L"XASE uefi loader\nI will load (EFI System Partition)\\XASE\\KERNEL64.SYS at 0x100000.\n");
    

    chk(SystemTable->BootServices->OpenProtocol(
            ImageHandle,
            &gEfiLoadedImageProtocol,
            &ImageInfo,
            ImageHandle,
            NULL,
            EFI_OPEN_PROTOCOL_GET_PROTOCOL));

    Print(L" Image base: 0x%lx\n", ImageInfo->ImageBase);

    Print(L"sfsp ");

    chk(SystemTable->BootServices->LocateHandleBuffer(
            ByProtocol,
            &gEfiGraphicsOutputProtocol,
            NULL,
            &GopHandleCount,
            &GopHandleBuffer));

    Print(L"gopHB ");

    if (GopHandleCount < 1) {
        Print(L"\nERR: NO GOP HANDLES FOUND!\n");
        waitKey();
        return EFI_SUCCESS;
    }

    chk(SystemTable->BootServices->OpenProtocol(
            GopHandleBuffer[0],
            &gEfiGraphicsOutputProtocol,
            &Gop,
            ImageHandle,
            NULL,
            EFI_OPEN_PROTOCOL_GET_PROTOCOL));

    Print(L"gop ");

    chk(SystemTable->BootServices->OpenProtocol(
            ImageInfo->DeviceHandle,
            &gEfiSimpleFileSystemProtocol,
            &SfsProt,
            ImageHandle,
            NULL,
            EFI_OPEN_PROTOCOL_GET_PROTOCOL));

    Print(L"ov ");

    chk(SfsProt->OpenVolume(
            SfsProt,
            &Root));

    Print(L"Root: 0x%lx ", Root);


    chk(Root->Open(
            Root,
            &Part2,
            L"\\XASE\\KERNEL64.SYS",
            EFI_FILE_MODE_READ,
            0));

    Print(L"P2 File Handle: 0x%lx ", Part2);

    chk(Part2->GetInfo(
            Part2,
            &gEfiFileInfoGuid,
            &Part2FileInfoSize,
            &Part2FileInfoBuffer));

    Part2FileInfo = (EFI_FILE_INFO*) Part2FileInfoBuffer;

    Print(L"\n\\XASE\\KERNEL64.SYS is %d bytes\n", Part2FileInfo->FileSize);

    chk(SystemTable->BootServices->AllocatePool(
            0x80000000,
            Part2FileInfo->FileSize,
            &buffer));

    Print(L"alloc@0x%lx to 0x%lx\n", buffer, buffer + Part2FileInfo->FileSize);

    sz = Part2FileInfo->FileSize;
    
    chk(Part2->Read(
            Part2,
            &sz,
            buffer));

    Print(L"Read %d bytes\n", sz);

    chk(Part2->Close(Part2));

    Print(L"Closed file.\n");

    Print(L"FileSize==sz                         ?? ");

    if (Part2FileInfo->FileSize == sz) {
        Print(L"OK\n");
    } else {
        Print(L"ERR: Did not read whole file.\n");
        waitKey();
        return EFI_SUCCESS;
    }

    Print(L"ImageInfo->ImageBase > 0x100000 + sz ?? ");

    if ((UINTN)(ImageInfo->ImageBase) > 0x100000 + sz) {
        Print(L"OK\n");
    } else {
        Print(L"ERR: Loader's in the way!\n");
        waitKey();
        return EFI_SUCCESS;
    }

    Print(L"buffer > 0x100000 + sz               ?? ");

    if ((UINTN)buffer > 0x100000 + sz) {
        Print(L"OK\n");
    } else {
        Print(L"ERR: buffer is in way\n");
        waitKey();
        return EFI_SUCCESS;
    }

    Print(L"Grabbing memory map & ExitBootServices\n");

    while (1) {
        memoryMapSize = sizeof(memoryMap);
        getMmapStatus = SystemTable->BootServices->GetMemoryMap(
            &memoryMapSize,
            memoryMap,
            &mapKey,
            &descriptorSize,
            &descriptorVersion);

        if (getMmapStatus != EFI_SUCCESS) {
            break;
        }

        exitBootServicesStatus = SystemTable->BootServices->ExitBootServices(
            ImageHandle,
            mapKey);

        if (exitBootServicesStatus == EFI_SUCCESS) {
            break;
        }

        if (once == 0) {
            Print(L"Again\n");
        }
        once++;
    }

    if (getMmapStatus != EFI_SUCCESS) {
        Print(L"memoryMapSize: %d\n", memoryMapSize);
        chk(getMmapStatus);
        return EFI_SUCCESS;
    }

    UINT8* dst = (UINT8*) 0x100000;

    // copy buffer to 0x100000
    for (UINTN i = 0; i < sz; i++) {
        dst[i] = buffer[i];
    }

    void (*start2) ();

    start2 = (void (*)())0x100000;

    Smuggle* smuggle = (Smuggle*) 0x400000;
    smuggle->GOPBase = (void*) Gop->Mode->FrameBufferBase;
    smuggle->GOPSize = (UINT64) Gop->Mode->FrameBufferSize;
    smuggle->GOPHorizontalResolution = (UINT32) Gop->Mode->Info->HorizontalResolution;
    smuggle->GOPVerticalResolution = (UINT32) Gop->Mode->Info->VerticalResolution;
    smuggle->GOPPixelsPerScanLine = (UINT32) Gop->Mode->Info->PixelsPerScanLine;

    for (UINT64 j = Gop->Mode->FrameBufferBase; j < Gop->Mode->FrameBufferBase + Gop->Mode->FrameBufferSize; j += 4) {
        UINT8* x = (UINT8*)j;
        //*x = 128;
        x++;
        *x = 0;
        x++;
        //*x = 128;
    }

    start2();

    while (1) {
        after_write("X");
    }
}

void after_write(char* string)
{
    volatile char* video = (volatile char*)0xb8000;
    while (*string != 0)
    {
        *video++ = *string++;
        video++;
    }
}

void chk(EFI_STATUS status)
{
    if (status != EFI_SUCCESS) {
        reportError(status);
    }
}

void waitKey()
{
    EFI_INPUT_KEY Key;
    Print(L"\n(press any key)\n");
    ST->ConIn->Reset(ST->ConIn, FALSE);
    while ((ST->ConIn->ReadKeyStroke(ST->ConIn, &Key)) == EFI_NOT_READY) ;
}

void reportError(EFI_STATUS err)
{
    switch (err) {
        case EFI_SUCCESS:
            Print(L"EFI_SUCCESS (The operation completed successfully.)");
            break;
        case EFI_LOAD_ERROR:
            Print(L"EFI_LOAD_ERROR (The image failed to load.)");
            break;
        case EFI_INVALID_PARAMETER:
            Print(L"EFI_INVALID_PARAMETER (A parameter was incorrect.)");
            break;
        case EFI_UNSUPPORTED:
            Print(L"EFI_UNSUPPORTED (The operation is not supported.)");
            break;
        case EFI_BAD_BUFFER_SIZE:
            Print(L"EFI_BAD_BUFFER_SIZE (The buffer was not the proper size for the request.)");
            break;
        case EFI_BUFFER_TOO_SMALL:
            Print(L"EFI_BUFFER_TOO_SMALL (The buffer is not large enough to hold the requested data.)");
            break;
        case EFI_NOT_READY:
            Print(L"EFI_NOT_READY (There is no data pending upon return.)");
            break;
        case EFI_DEVICE_ERROR:
            Print(L"EFI_DEVICE_ERROR (The physical device reported an error while attempting the operation.)");
            break;
        case EFI_WRITE_PROTECTED:
            Print(L"EFI_WRITE_PROTECTED (The device cannot be written to.)");
            break;
        case EFI_OUT_OF_RESOURCES:
            Print(L"EFI_OUT_OF_RESOURCES (A resource has run out.)");
            break;
        case EFI_VOLUME_CORRUPTED:
            Print(L"EFI_VOLUME_CORRUPTED (An inconsistency was detected on the file system, causing the operation ta fail.)");
            break;
        case EFI_VOLUME_FULL:
            Print(L"EFI_VOLUME_FULL (There is no more space on the file system.)");
            break;
        case EFI_NO_MEDIA:
            Print(L"EFI_NO_MEDIA (The device does not contain any medium to perform the operation.)");
            break;
        case EFI_MEDIA_CHANGED:
            Print(L"EFI_MEDIA_CHANGED (The medium in the device has changed since the last access.)");
            break;
        case EFI_NOT_FOUND:
            Print(L"EFI_NOT_FOUND (The item was not found.)");
            break;
        case EFI_ACCESS_DENIED:
            Print(L"EFI_ACCESS_DENIED (Access was denied.)");
            break;
        case EFI_NO_RESPONSE:
            Print(L"EFI_NO_RESPONSE (The server was not found or did not respond to the request.)");
            break;
        case EFI_NO_MAPPING:
            Print(L"EFI_NO_MAPPING (A mapping to the device does not exist.)");
            break;
        case EFI_TIMEOUT:
            Print(L"EFI_TIMEOUT (Timeout expired.)");
            break;
        case EFI_NOT_STARTED:
            Print(L"EFI_NOT_STARTED (The protocol has not been started.)");
            break;
        case EFI_ALREADY_STARTED:
            Print(L"EFI_ALREADY_STARTED (The protocol has already been started.)");
            break;
        case EFI_ABORTED:
            Print(L"EFI_ABORTED (The operation was aborted.)");
            break;
        case EFI_ICMP_ERROR:
            Print(L"EFI_ICMP_ERROR (An ICMP error occurred during the network operation.)");
            break;
        case EFI_TFTP_ERROR:
            Print(L"EFI_TFTP_ERROR (A TFTP error occurred during the network operation.)");
            break;
        case EFI_PROTOCOL_ERROR:
            Print(L"EFI_PROTOCOL_ERROR (A protocol error occurred during the network operation.)");
            break;
        case EFI_INCOMPATIBLE_VERSION:
            Print(L"EFI_INCOMPATIBLE_VERSION (The function encountered an internal version that was incompatible with the version requested by the caller.)");
            break;
        case EFI_SECURITY_VIOLATION:
            Print(L"EFI_SECURITY_VIOLATION (The function was not performed due to a security violation.)");
            break;
        case EFI_CRC_ERROR:
            Print(L"EFI_CRC_ERROR (A CRC error was detected.)");
            break;
        case EFI_END_OF_MEDIA:
            Print(L"EFI_END_OF_MEDIA (Beginning or end of media was reached.)");
            break;
        case EFI_END_OF_FILE:
            Print(L"EFI_END_OF_FILE (The end of the file was reached.)");
            break;
        case EFI_WARN_UNKNOWN_GLYPH:
            Print(L"EFI_WARN_UNKNOWN_GLYPH (The Unicode string contained one or more characters that the device could not render, and were skipped.)");
            break;
        case EFI_WARN_DELETE_FAILURE:
            Print(L"EFI_WARN_DELETE_FAILURE (The handle was closed, but the file was not deleted.)");
            break;
        case EFI_WARN_WRITE_FAILURE:
            Print(L"EFI_WARN_WRITE_FAILURE (The handle was closed, but the data was not flushed to the file correctly.");
            break;
        default:
            Print(L"Unknown EFI status (very broken?): %d", err);
            break;
    }
    waitKey();
}
