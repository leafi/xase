
void printki(long num);
void printkid(long num);
void printk(char* s);

extern void outb(unsigned short port, unsigned char val);
extern unsigned char inb(unsigned short port);

//extern void pci_thing();

//extern void some_ps2_stuff();

//extern void some_serial_stuff();

//extern void setup_apic();
//extern void setup_apic_notreally();

//extern void setup_pic();

//extern void setup_ata_pio();

//extern void setup_bga();

//extern void lua_stuff();

//extern void serial_printk(char* s);

// imagine dragons - radioactive

void* kmstart;
void* kmlimit;

// end symbol - from linker script
extern const void end;

//void call_lua_int(long l) { }

void* kmalloc(long bytes);

typedef struct {
    unsigned char* GOPBase;
    long GOPSize;
} Smuggle;

void _start()
{
  Smuggle* smuggled = (Smuggle*) 0x400000;

  unsigned char* fb = smuggled->GOPBase;
  unsigned char* fbend = smuggled->GOPBase;
  fbend += smuggled->GOPSize;
  for (; fb < fbend; fb += 4) {
    fb[1] = fb[0];
    fb[0] = 0;
    fb[2] = 0;

  }

  // VERY HACK
  kmstart = (void*)0x200000;
  kmlimit = (void*)0x300000;

  lua_stuff();

  while (1) { }

}

// Simple memory allocation.
// 'Real' memory allocation is performed after setup is done by taking
//  control of a huge chunk of memory, and another malloc func does caretaking.
void* kmalloc(long bytes) {
  void* m = kmstart;
  kmstart += bytes;
  if (kmstart >= kmlimit) {
    //printk("OUT OF MEMORY!\n");
    while(1) {}
  }
  return m;
}

void printk(char* t) {
}

