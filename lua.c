#include <lua.h>
#include <lapi.h>
#include <lauxlib.h>
#include <lualib.h>

#include <stdio.h>
#include <stdlib.h>

extern void printk(char* s);
extern void printki(long n);
extern void printkid(long n);

extern void* kmalloc(long len);

/*extern unsigned char rdiskb(unsigned long offset);
extern unsigned short rdiskw(unsigned long offset);
extern unsigned int rdiski(unsigned long offset);
extern unsigned long rdiskl(unsigned long offset);*/

extern unsigned char inb(unsigned short port);
extern unsigned short inw(unsigned short port);
extern unsigned int ind(unsigned short port);
extern void outb(unsigned short port, unsigned char val);
extern void outw(unsigned short port, unsigned short val);
extern void outd(unsigned short port, unsigned int val);

extern void irq_mask(unsigned char irq, unsigned char mask);

extern void io_wait();

typedef struct {
    unsigned char* GOPBase;
    long GOPSize;
} Smuggle;

extern Smuggle* smuggled;

extern const char* lcode;

static int lunsmuggleGOPBase(lua_State *L)
{
    lua_pushunsigned(L, (lua_Unsigned) smuggled->GOPBase);
    return 1;
}

static int lunsmuggleGOPSize(lua_State *L)
{
    lua_pushunsigned(L, (lua_Unsigned) smuggled->GOPSize);
    return 1;
}

static int lmalloc(lua_State *L)
{
	lua_pushunsigned(L, (lua_Unsigned) malloc(lua_tounsigned(L, 1)));
	return 1;
}

static int lcalloc(lua_State *L)
{
	lua_pushunsigned(L, (lua_Unsigned) calloc(lua_tounsigned(L, 1), lua_tounsigned(L, 2)));
	return 1;
}

static int lfree(lua_State *L)
{
	free(lua_tounsigned(L, 1));
	return 0;
}

static int lkmalloc(lua_State *L)
{
	lua_pushunsigned(L, (lua_Unsigned) kmalloc(lua_tounsigned(L, 1)));
	return 1;
}

static int lpeekb(lua_State *L)
{
	lua_pushunsigned(L, (lua_Unsigned) *((unsigned char*)lua_tounsigned(L, 1)));
	return 1;
}

static int lpeekw(lua_State *L)
{
	lua_pushunsigned(L, (lua_Unsigned) *((unsigned short*)lua_tounsigned(L, 1)));
	return 1;
}

static int lpeeki(lua_State *L)
{
	lua_pushunsigned(L, (lua_Unsigned) *((unsigned int*)lua_tounsigned(L, 1)));
	return 1;
}

static int lpeekl(lua_State *L)
{
	lua_pushunsigned(L, (lua_Unsigned) *((unsigned long*)lua_tounsigned(L, 1)));
	return 1;
}

static int lpokeb(lua_State *L)
{
	*((unsigned char*)lua_tounsigned(L, 1)) = (unsigned char) lua_tounsigned(L, 2);
	return 0;
}

static int lpokew(lua_State *L)
{
	*((unsigned short*)lua_tounsigned(L, 1)) = (unsigned short) lua_tounsigned(L, 2);
	return 0;
}

static int lpokei(lua_State *L)
{
	*((unsigned int*)lua_tounsigned(L, 1)) = (unsigned int) lua_tounsigned(L, 2);
	return 0;
}

static int lpokel(lua_State *L)
{
	*((unsigned long*)lua_tounsigned(L, 1)) = (unsigned long) lua_tounsigned(L, 2);
	return 0;
}

static int linb(lua_State *L)
{
	lua_pushunsigned(L, (lua_Unsigned) inb((unsigned short) lua_tounsigned(L, 1)));
	return 1;
}

static int linw(lua_State *L)
{
	lua_pushunsigned(L, (lua_Unsigned) inw((unsigned short) lua_tounsigned(L, 1)));
	return 1;
}

static int lini(lua_State *L)
{
	lua_pushunsigned(L, (lua_Unsigned) ind((unsigned short) lua_tounsigned(L, 1)));
	return 1;
}

static int loutb(lua_State *L)
{
	outb((unsigned short) lua_tounsigned(L, 1), (unsigned char) lua_tounsigned(L, 2));
	return 0;
}

static int loutw(lua_State *L)
{
	outw((unsigned short) lua_tounsigned(L, 1), (unsigned short) lua_tounsigned(L, 2));
	return 0;
}

static int louti(lua_State *L)
{
	outd((unsigned short) lua_tounsigned(L, 1), (unsigned int) lua_tounsigned(L, 2));
	return 0;
}

/*static int lrdiskb(lua_State *L)
{
	int n = lua_gettop(L);
	if (lua_gettop(L) < 1 || !lua_isinteger(L, n) || !lua_isnumber(L, n)) {
		lua_pushstring(L, "lrdiskb incorrect argument");
		lua_error(L);
	}
	lua_pushunsigned(L, (lua_Unsigned) rdiskb(lua_tounsigned(L, n)));
	return 1;
}

static int lrdiskw(lua_State *L)
{
	int n = lua_gettop(L);
	if (lua_gettop(L) < 1 || !lua_isinteger(L, n) || !lua_isnumber(L, n)) {
		lua_pushstring(L, "lrdiskw incorrect argument");
		lua_error(L);
	}
	lua_pushunsigned(L, (lua_Unsigned) rdiskw(lua_tounsigned(L, n)));
	return 1;
}

static int lrdiski(lua_State *L)
{
	int n = lua_gettop(L);
	if (lua_gettop(L) < 1 || !lua_isinteger(L, n) || !lua_isnumber(L, n)) {
		lua_pushstring(L, "lrdiski incorrect argument");
		lua_error(L);
	}
	lua_pushunsigned(L, (lua_Unsigned) rdiski(lua_tounsigned(L, n)));
	return 1;
}

static int lrdiskl(lua_State *L)
{
	int n = lua_gettop(L);
	if (lua_gettop(L) < 1 || !lua_isinteger(L, n) || !lua_isnumber(L, n)) {
		lua_pushstring(L, "lrdiskl incorrect argument");
		lua_error(L);
	}
	lua_pushunsigned(L, (lua_Unsigned) rdiskl(lua_tounsigned(L, n)));
	return 1;
}

static int lirqmask(lua_State *L)
{
	irq_mask((unsigned char) lua_tounsigned(L, 1), (unsigned char) lua_tounsigned(L, 2));
	return 0;
}

static int liowait(lua_State *L)
{
	io_wait();
	return 0;
}*/

lua_State *globalL;

/*void call_lua_int(long inte)
{
	lua_State *L = globalL;

	lua_getglobal(L, "call_lua_int_2");
	lua_pushinteger(L, (lua_Integer) inte);
	lua_call(L, 1, 0);
}

void reportlua(lua_State *L)
{
	const char* c = lua_tostring(L, lua_gettop(L));

	int i;
	int j = 0;
	char prefix[256];

	for (i = 0; i < 255; i++) {
		prefix[i] = c[i];
		if (c[i] == ':') {
			j++;
			if (j == 4) {
				i++;
				break;
			}
		}
	}
	if (j == 4) {
		prefix[i] = 0;
		c += i;
		printk(prefix);
		printk("\n   ");
	}
	printk(c);
	printk("\n");
		
	//printk(lua_tostring(L, lua_gettop(L)));
}*/

#define LBUFFER_LIMIT	65536
char lbuffer[LBUFFER_LIMIT];
int lbufferptr = 0;

/*static int clearlbuffer(lua_State *L)
{
	lbufferptr = 0;
	return 0;
}

static int finishlbuffer(lua_State *L)
{
	lua_pushlstring(L, lbuffer, lua_tounsigned(L, 1));
	return 1;
}

static int addlbuffer(lua_State *L)
{
	long rloc = lua_tounsigned(L, 1);
	long sectors_per_cluster = lua_tounsigned(L, 2);
	long* lp = (long*)lbuffer;
	int i;
	for (i = 0; i < (sectors_per_cluster * 512 / 8); i++) {
		lp[lbufferptr + i] = rdiskl(rloc);
		rloc += 8;
	}
	lbufferptr += sectors_per_cluster * 512 / 8;
	if (lbufferptr >= LBUFFER_LIMIT) {
		printk("!!! Need to extend LBUFFER_LIMIT.\n");
		printk("!!! Lua file is too long; cannot continue.\n");
		while (1) {}
	}
	return 0;
}*/

static const luaL_Reg bclib[] = {
	/*{"rdiskb", lrdiskb},
	{"rdiskw", lrdiskw},
	{"rdiski", lrdiski},
	{"rdiskl", lrdiskl},
	{"clearlbuffer", clearlbuffer},
	{"addlbuffer", addlbuffer},
	{"finishlbuffer", finishlbuffer},*/
    {"unsmuggleGOPBase", lunsmuggleGOPBase},
    {"unsmuggleGOPSize", lunsmuggleGOPSize},
	{"inb", linb},
	{"inw", linw},
	{"ini", lini},
	{"outb", loutb},
	{"outw", loutw},
	{"outi", louti},
	{"peekb", lpeekb},
	{"peekw", lpeekw},
	{"peeki", lpeeki},
	{"peekl", lpeekl},
	{"pokeb", lpokeb},
	{"pokew", lpokew},
	{"pokei", lpokei},
	{"pokel", lpokel},
	{"kmalloc", lkmalloc},
	/*{"irqmask", lirqmask},
	{"iowait", liowait},*/
	{"malloc", lmalloc},
	{"calloc", lcalloc},
	{"free", lfree},
	{NULL,     NULL}
};

LUAMOD_API int luaopen_bc (lua_State *L) {
	luaL_newlib(L, bclib);
	return 1;
}

void open_private_libs(lua_State *L) {
	luaL_requiref(L, "bc", luaopen_bc, 1);
	lua_pop(L, 1);
}

// TEMP HACK
/*extern void irq1();
extern void set_int(unsigned char inte, void* funptr);*/

void lua_stuff()
{
	// TEMP TESTING HACK
	//set_int(0x21, irq1);

	//printk("lua_stuff() starting\n");

	lua_State *l = luaL_newstate();

    unsigned char* fb = smuggled->GOPBase;
    unsigned char* fbend = smuggled->GOPBase;
    fb += (smuggled->GOPSize / 4);
    fbend += (smuggled->GOPSize / 4);
    for (; fb < fbend; fb += 4) {
        fb[0] = 255;
        fb[1] = 0;
        fb[2] = 0;
    }
    
	// shh
	globalL = l;



	luaL_openlibs(l);

    fb = smuggled->GOPBase;
    fbend = smuggled->GOPBase;
    fb += (smuggled->GOPSize / 4);
    fb += (smuggled->GOPSize / 4);
    fbend += (smuggled->GOPSize / 4);
    for (; fb < fbend; fb += 4) {
        fb[0] = 255;
        fb[1] = 0;
        fb[2] = 0;
    }

	open_private_libs(l);

	int lsv = luaL_loadstring(l, lcode);
	if (lsv != LUA_OK) {
		if (lsv == LUA_ERRSYNTAX) {
			//printk("LUA_ERRSYNTAX\n");
            unsigned char* fb = smuggled->GOPBase;
            unsigned char* fbend = smuggled->GOPBase;
            fbend += (smuggled->GOPSize / 4);
            for (; fb < fbend; fb += 4) {
                fb[2] = 255;
                fb[1] = 0;
                fb[0] = 0;
            }
		} else if (lsv == LUA_ERRMEM) {
			//printk("LUA_ERRMEM\n");
            unsigned char* fb = smuggled->GOPBase;
            unsigned char* fbend = smuggled->GOPBase;
            fb += (smuggled->GOPSize / 4);
            fbend += (smuggled->GOPSize / 4);
            for (; fb < fbend; fb += 4) {
                fb[2] = 255;
                fb[1] = 0;
                fb[0] = 0;
            }
		} else if (lsv == LUA_ERRGCMM) {
			//printk("LUA_ERRGCMM\n");
            unsigned char* fb = smuggled->GOPBase;
            unsigned char* fbend = smuggled->GOPBase;
            fb += (smuggled->GOPSize / 4);
            fb += (smuggled->GOPSize / 4);
            fbend += (smuggled->GOPSize / 4);
            for (; fb < fbend; fb += 4) {
                fb[2] = 255;
                fb[1] = 0;
                fb[0] = 0;
            }
		} else {
			//printki(lsv); printk("\n");
            unsigned char* fb = smuggled->GOPBase;
            unsigned char* fbend = smuggled->GOPBase;
            fb += (smuggled->GOPSize / 4);
            fb += (smuggled->GOPSize / 4);
            fb += (smuggled->GOPSize / 4);
            fbend += (smuggled->GOPSize / 4);
            for (; fb < fbend; fb += 4) {
                fb[2] = 255;
                fb[1] = 0;
                fb[0] = 0;
            }
		}
		//reportlua(l);
		return;
	}

	int pcv = lua_pcall(l, 0, LUA_MULTRET, 0);
	if (pcv != LUA_OK) {
		if (pcv == LUA_ERRRUN) {
			//printk("LUA_ERRRUN\n");
			//reportlua(l);
		} else if (pcv == LUA_ERRMEM) {
			//printk("LUA_ERRMEM\n");
		} else if (pcv == LUA_ERRGCMM) {
			//printk("LUA_ERRGCMM\n");
		} else {
			//printki(pcv); printk("\n");
		}
	}

}

