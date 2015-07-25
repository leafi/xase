char *_ultramem = (char *)0x800000;
int _allocs = 0;
int _frees = 0;

typedef __SIZE_TYPE__ size_t;

void free(void *ptr);

void *malloc(size_t size);

void _start();

void _outb(unsigned short port, unsigned char val);

void printk(const char *s);

extern void the_lua(void);

typedef struct {
	unsigned char *GOPBase;
	long GOPSize;
} Smuggle;

Smuggle* oldSmuggle;

Smuggle newSmuggle;

unsigned char* fb1;

void _start()
{
	long long * test = (long long *)0x600000;
	*test = 0x123456789abcdef;

	//outb(0xe9, 'a');
	oldSmuggle = (Smuggle*)0x400000;
	newSmuggle.GOPBase = oldSmuggle->GOPBase;
	newSmuggle.GOPSize = oldSmuggle->GOPSize;

	Smuggle* smuggled = &newSmuggle;

	printk("fb1");

	unsigned char* fb = smuggled->GOPBase;
	unsigned char* fbend = fb;
	//fbend += 2000;
	fbend += smuggled->GOPSize;
	for (; fb < fbend; fb += 4) {
		fb[1] = 127;
		fb[0] = 0;
		fb[2] = 0;

	}

	printk("..2 ");

	the_lua();

	while (1) {}
}

void _outb(unsigned short port, unsigned char val)
{
	__asm__ __volatile__("outb %0, %1" : : "a"(val), "d"(port));
}

void printk(const char *s)
{
	for (const char *t = s; *t != 0; t++)
	{
		if (*t == '\n')
			_outb(0xe9, '\r');
		_outb(0xe9, *t);
	}
}

void free(void *ptr) {
	// ok.. fine
	_frees++;
}

void *malloc(size_t size) {
	void *mem = (void *)_ultramem;
	_ultramem += size;
	_allocs++;
	return mem;
}
