#include <lua.h>
#include <lapi.h>
#include <lauxlib.h>
#include <lualib.h>

#include <syslua.h>

#include <cpuid.h>

extern char *_ultramem;
extern int _allocs;
extern int _frees;

extern void printk(const char *s);

int lpeekub(lua_State *L);
int lpokeub(lua_State *L);
int lpeeksb(lua_State *L);
int lpeekuw(lua_State *L);
int lpeeksw(lua_State *L);
int lpeekud(lua_State *L);
int lpeeksd(lua_State *L);
int lpeeksq(lua_State *L);

int lprintk(lua_State *L);
int lultramem(lua_State *L);

int linb(lua_State *L);
int linw(lua_State *L);
int lind(lua_State *L);
int loutb(lua_State *L);
int loutw(lua_State *L);
int loutd(lua_State *L);

int lgohufont11(lua_State *L);
int lgetgopbase(lua_State *L);

int lcpuid(lua_State *L);

int lcpugetmsr(lua_State *L);
int lcpusetmsr(lua_State *L);

void open_private_libs(lua_State *L);

void the_lua(void);

//= "kx.printk(\"hi from lua! <3\\n\")\nkx.printk(kx.ultramem())";

static const luaL_Reg kxlib[] = {
	{ "printk", lprintk },
	{ "ultramem", lultramem },
	{ "peekub", lpeekub },
	{ "pokeub", lpokeub },
	{ "peeksb", lpeeksb },
	{ "peekuw", lpeekuw },
	{ "peeksw", lpeeksw },
	{ "peekud", lpeekud },
	{ "peeksd", lpeeksd },
	{ "peeksq", lpeeksq },
	{ "inb", linb },
	{ "inw", linw },
	{ "ind", lind },
	{ "outb", loutb },
	{ "outw", loutw },
	{ "outd", loutd },
  { "gohufont11", lgohufont11 },
  { "getgopbase", lgetgopbase },
  { "cpuid", lcpuid },
  { "cpugetmsr", lcpugetmsr },
  { "cpusetmsr", lcpusetmsr },
	{ NULL, NULL }
};

int lprintk(lua_State *L)
{
	printk(lua_tostring(L, lua_gettop(L)));
	return 0;
}

int lultramem(lua_State *L)
{
	lua_pushinteger(L, (unsigned long long)_ultramem);
	lua_pushinteger(L, _allocs);
	lua_pushinteger(L, _frees);
	return 3;
}

int lpeekub(lua_State *L)
{
	unsigned char *addr = (unsigned char *)lua_tointeger(L, 1);
	lua_pop(L, 1);
	lua_pushinteger(L, *addr);
	return 1;
}

int lpokeub(lua_State *L)
{
  unsigned char *addr = (unsigned char *)lua_tointeger(L, 1);
  *addr = (unsigned char)lua_tointeger(L, 2);
  return 0;
}

int lpeeksb(lua_State *L)
{
	char *addr = (char *)lua_tointeger(L, 1);
	lua_pop(L, 1);
	lua_pushinteger(L, *addr);
	return 1;
}

int lpeekuw(lua_State *L)
{
	unsigned short *addr = (unsigned short *)lua_tointeger(L, 1);
	lua_pop(L, 1);
	lua_pushinteger(L, *addr);
	return 1;
}

int lpeeksw(lua_State *L)
{
	short *addr = (short *)lua_tointeger(L, 1);
	lua_pop(L, 1);
	lua_pushinteger(L, *addr);
	return 1;
}

int lpeekud(lua_State *L)
{
	unsigned int *addr = (unsigned int *)lua_tointeger(L, 1);
	lua_pop(L, 1);
	lua_pushinteger(L, *addr);
	return 1;
}

int lpeeksd(lua_State *L)
{
	int *addr = (int *)lua_tointeger(L, 1);
	lua_pop(L, 1);
	lua_pushinteger(L, *addr);
	return 1;
}

int lpeeksq(lua_State *L)
{
	long long *addr = (long long *)lua_tointeger(L, 1);
	lua_pop(L, 1);
	lua_pushinteger(L, *addr);
	return 1;
}

int linb(lua_State *L)
{
	unsigned short port = (unsigned short)lua_tointeger(L, 1);
	unsigned char val;
	__asm__ __volatile__("inb %1, %0" : "=a"(val) : "d"(port));
	lua_pushinteger(L, val);
	return 1;
}

int linw(lua_State *L)
{
	unsigned short port = (unsigned short)lua_tointeger(L, 1);
	unsigned short val;
	__asm__ __volatile__("inw %1, %0" : "=a"(val) : "d"(port));
	lua_pushinteger(L, val);
	return 1;
}

int lind(lua_State *L)
{
	unsigned short port = (unsigned short)lua_tointeger(L, 1);
	unsigned int val;
	__asm__ __volatile__("inl %1, %0" : "=a"(val) : "d"(port));
	lua_pushinteger(L, val);
	return 1;
}

int loutb(lua_State *L)
{
	unsigned short port = (unsigned short)lua_tointeger(L, 1);
	unsigned char val = (unsigned char)lua_tointeger(L, 2);
	__asm__ __volatile__("outb %0, %1" : : "a"(val), "d"(port));
	return 0;
}

int loutw(lua_State *L)
{
	unsigned short port = (unsigned short)lua_tointeger(L, 1);
	unsigned short val = (unsigned short)lua_tointeger(L, 2);
	__asm__ __volatile__("outw %0, %1" : : "a"(val), "d"(port));
	return 0;
}

int loutd(lua_State *L)
{
	unsigned short port = (unsigned short)lua_tointeger(L, 1);
	unsigned int val = (unsigned int)lua_tointeger(L, 2);
	__asm__ __volatile__("outl %0, %1" : : "a"(val), "d"(port));
	return 0;
}

int lgohufont11(lua_State *L)
{
  lua_pushstring(L, target_src_lua_gohufont11_bdf);
  return 1;
}

extern unsigned char* fb1;

int lgetgopbase(lua_State *L)
{
  lua_pushinteger(L, (lua_Integer)fb1);
  return 1;
}

int lcpuid(lua_State *L)
{
  unsigned int level = (unsigned int)lua_tointeger(L, 1);
  unsigned int a;
  unsigned int b;
  unsigned int c;
  unsigned int d;
  int ok = __get_cpuid(level, &a, &b, &c, &d);
  lua_pushinteger(L, ok);
  lua_pushinteger(L, a);
  lua_pushinteger(L, b);
  lua_pushinteger(L, c);
  lua_pushinteger(L, d);
  return 5;
}

int lcpugetmsr(lua_State *L)
{
  unsigned int msr = (unsigned int)lua_tointeger(L, 1);
  unsigned int lo;
  unsigned int hi;
  asm volatile("rdmsr" : "=a"(lo), "=d"(hi) : "c"(msr));
  lua_pushinteger(L, lo);
  lua_pushinteger(L, hi);
  return 2;
}

int lcpusetmsr(lua_State *L)
{
  unsigned int msr = (unsigned int)lua_tointeger(L, 1);
  unsigned int lo = (unsigned int)lua_tointeger(L, 2);
  unsigned int hi = (unsigned int)lua_tointeger(L, 3);
  asm volatile("wrmsr" : : "a"(lo), "d"(hi), "c"(msr));
  return 0;
}

LUAMOD_API int luaopen_kx(lua_State *L)
{
	luaL_newlib(L, kxlib);
	return 1;
}

void run_one_lua(lua_State *L, char* source)
{
	printk("rol luaL_loadstring ");
	int lsv = luaL_loadstring(L, source);
	if (lsv != LUA_OK)
	{
		if (lsv == LUA_ERRSYNTAX)
		{
			printk("ERR: LUA_ERRSYNTAX");
		}
		else if (lsv == LUA_ERRMEM)
		{
			printk("ERR: LUA_ERRMEM");
		}
		else if (lsv == LUA_ERRGCMM)
		{
			printk("ERR: LUA_ERRGCMM");
		}
		else
		{
			printk("ERR: OTHER");
		}
		printk("\n");
		char *s = lua_tostring(L, -1);
		printk(s);
		return;
	}
	printk("lua_pcall:\n");
	int pcv = lua_pcall(L, 0, LUA_MULTRET, 0);
	if (pcv != LUA_OK)
	{
		printk("ERR: Runtime\n");
		printk(lua_tostring(L, -1));
		return;
	}
	printk("OK \n");
}

void open_private_libs(lua_State *L)
{
  luaL_requiref(L, "kx", luaopen_kx, 1);
  lua_pop(L, 1);

  lua_newtable(L);
  int tableidx = lua_gettop(L);

  /*lua_pushstring(L, luasrc_gohufont11_bdf);
  lua_setfield(L, tableidx, "luasrc_gohufont11_bdf");

  lua_pushstring(L, luasrc_gohufont14_bdf);
  lua_setfield(L, tableidx, "luasrc_gohufont14_bdf");

  lua_pushstring(L, luasrc_ps2_lua);
  lua_setfield(L, tableidx, "luasrc_ps2_lua");

  lua_pushstring(L, luasrc_bdf_font_lua);
  lua_setfield(L, tableidx, "luasrc_bdf_font_lua");*/

  #include <syslua_kxdata_meta.h>

  lua_setglobal(L, "kxdata");
}

void the_lua()
{
	printk("lua ");
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);
	open_private_libs(L);
	printk("luaL_loadstring ");
	int lsv = luaL_loadstring(L, target_src_lua_lcode_lua);
	if (lsv != LUA_OK)
	{
		if (lsv == LUA_ERRSYNTAX)
		{
			printk("ERR: LUA_ERRSYNTAX");
		}
		else if (lsv == LUA_ERRMEM)
		{
			printk("ERR: LUA_ERRMEM");
		}
		else if (lsv == LUA_ERRGCMM)
		{
			printk("ERR: LUA_ERRGCMM");
		}
		else
		{
			printk("ERR: OTHER");
		}
		printk("\n");
		char *s = lua_tostring(L, -1);
		printk(s);
		return;
	}
	printk("lua_pcall.....\n");
	int pcv = lua_pcall(L, 0, LUA_MULTRET, 0);
	if (pcv != LUA_OK)
	{
		printk("ERR: Runtime\n");
		printk(lua_tostring(L, -1));
		return;
	}
	printk("End.\n");
}
