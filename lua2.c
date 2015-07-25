#include <lua.h>
#include <lapi.h>
#include <lauxlib.h>
#include <lualib.h>

extern char *_ultramem;
extern int _allocs;
extern int _frees;

extern void printk(char *s);

int lprintk(lua_State *L);
int lultramem(lua_State *L);

LUAMOD_API int luaopen_bc(lua_State *L);

void open_private_libs(lua_State *L);

void the_lua(void);

extern unsigned char lcode[];

//= "kx.printk(\"hi from lua! <3\\n\")\nkx.printk(kx.ultramem())";

static const luaL_Reg kxlib[] = {
	{ "printk", lprintk },
	{ "ultramem", lultramem },
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

LUAMOD_API int luaopen_kx(lua_State *L)
{
	luaL_newlib(L, kxlib);
	return 1;
}

void open_private_libs(lua_State *L)
{
	luaL_requiref(L, "kx", luaopen_kx, 1);
	lua_pop(L, 1);
}

void the_lua()
{
	printk("lua ");
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);
	open_private_libs(L);
	printk("luaL_loadstring ");
	int lsv = luaL_loadstring(L, lcode);
	if (lsv != LUA_OK)
	{
		printk("ERR: NOTK");
		return;
	}
	printk("lua_pcall.....\n");
	int pcv = lua_pcall(L, 0, LUA_MULTRET, 0);
	if (pcv != LUA_OK)
	{
		printk("ERR: Runtime");
		return;
	}
	printk("End.\n");
}