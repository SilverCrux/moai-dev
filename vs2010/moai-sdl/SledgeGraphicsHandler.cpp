#include <uslscore/uslscore.h>
#include <moaicore-config.h>
#include "SledgeGraphicsHandler.h"


SDL_Window* SledgeGraphicsHandler::m_window = NULL;

SledgeGraphicsHandler::SledgeGraphicsHandler(){
	RTTI_BEGIN
		RTTI_EXTEND(MOAILuaObject)
	RTTI_END
}

SledgeGraphicsHandler::~SledgeGraphicsHandler()
{

}

int SledgeGraphicsHandler::_getSupportedResolutions( lua_State* L )
{
	MOAI_LUA_SETUP ( SledgeGraphicsHandler, "U" )

	// Get the index of the display we're currently on.
	int displayIdx = SDL_GetWindowDisplayIndex(m_window);
	// Get the number of modes this display can do.
	int num_displayModes = SDL_GetNumDisplayModes(displayIdx);

	vector<SDL_DisplayMode> modesfound;

	modesfound.clear();

	SDL_DisplayMode current_mode;

	int foo = SDL_GetWindowDisplayMode(
		m_window,
		&current_mode
	);
	
	// Push the current resolution information into Lua.
	lua_newtable(L);
		lua_pushstring(L, "w");
		lua_pushnumber(L, current_mode.w);
		lua_settable(L, -3);

		lua_pushstring(L, "h");
		lua_pushnumber(L, current_mode.h);
		lua_settable(L,-3);

		lua_pushstring(L, "bpp");
		lua_pushnumber(L, SDL_BITSPERPIXEL(current_mode.format));
		lua_settable(L,-3);
		lua_pushstring(L, "refresh");
		lua_pushnumber(L, current_mode.refresh_rate);
		lua_settable(L,-3);

		// @todo	Determine whether fullscreen or not.
		lua_pushstring(L, "format");
		lua_pushnumber(L, current_mode.format);
		//lua_pushboolean(L, 0);
		lua_settable(L,-3);

	lua_setglobal(L,"resolutionCurrent");
	printf("resolutions: %d\n", num_displayModes);

	lua_newtable(L);
	int j = 0;
	for (int i = 0; i < num_displayModes; i++)
	{
		SDL_DisplayMode thismode;
		int bar = SDL_GetDisplayMode(displayIdx, i, &thismode);
		if(bar == 0){ //&& thismode.format == current_mode.format){

			lua_pushnumber(L, j+1);
			lua_newtable(L);
				lua_pushstring(L, "w");
				lua_pushnumber(L, thismode.w);
				lua_settable(L, -3);
				lua_pushstring(L, "h");
				lua_pushnumber(L, thismode.h);
				lua_settable(L,-3);
				lua_pushstring(L, "bpp");
				lua_pushnumber(L, SDL_BITSPERPIXEL(thismode.format));
				lua_settable(L,-3);
				lua_pushstring(L, "refresh");
				lua_pushnumber(L, thismode.refresh_rate);
				lua_settable(L,-3);
				lua_pushstring(L, "format");
				lua_pushnumber(L, thismode.format);
				lua_settable(L,-3);

		lua_settable(L,-3);
		j++;
		}
	}
	lua_setglobal(L,"availableResolutions");
	/*
	lua_newtable(L);

		lua_pushnumber(L, 1);
		lua_newtable(L);
			lua_pushstring(L, "w");
			lua_pushnumber(L, current_mode.w);
			lua_settable(L, -3);
			lua_pushstring(L, "h");
			lua_pushnumber(L, current_mode.h);
			lua_settable(L,-3);

	lua_settable(L,-3);
	*/
	return 0;
}

void SledgeGraphicsHandler::RegisterLuaClass(MOAILuaState& state) {
	luaL_Reg regTable[] = {
		{ "getCurrentMode", _getSupportedResolutions },
		{ NULL, NULL }
	};
	luaL_register(state, 0, regTable);
}

void SledgeGraphicsHandler::RegisterLuaFuncs(MOAILuaState& state) {
	luaL_Reg regTable[] = {
		{ NULL, NULL}
	};
	luaL_register(state, 0, regTable);
}


void SledgeGraphicsHandler::SetWindow(SDL_Window* p_window)
{
	SledgeGraphicsHandler::m_window = p_window;
}