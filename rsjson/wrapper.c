#ifdef USE_LUAJIT
#include <luajit.h>
#else
#include <lua.h>
#endif
#include <lualib.h>
#include <lauxlib.h>

// A simple function to initialize a Lua state
lua_State* init_lua() {
    lua_State* L = luaL_newstate();
    luaL_openlibs(L);
    return L;
}