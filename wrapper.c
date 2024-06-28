#include <luajit.h>
#include <lualib.h>
#include <lauxlib.h>

// A simple function to initialize a Lua state
lua_State* init_lua() {
    lua_State* L = luaL_newstate();
    luaL_openlibs(L);
    return L;
}