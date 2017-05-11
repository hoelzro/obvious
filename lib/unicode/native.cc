extern "C" {
#  include <lua.h>
#  include <lauxlib.h>
}

#include <cstring>

#include <unicode/brkiter.h>
#include <unicode/unistr.h>

using namespace icu;

static int
_handle_error(lua_State *L, UErrorCode error)
{
    lua_pushnil(L);
    lua_pushstring(L, u_errorName(error));
    return 2;
}

static int
luaunicode_length(lua_State *L) throw ()
{
    UErrorCode error = U_ZERO_ERROR;
    UText text = UTEXT_INITIALIZER;
    const char *utf8bytes = luaL_checkstring(L, 1);

    utext_openUTF8(&text, utf8bytes, -1, &error);

    if(U_FAILURE(error)) {
        return _handle_error(L, error);
    }

    BreakIterator *i = BreakIterator::createCharacterInstance(Locale::getUS(), error);

    if(U_FAILURE(error)) {
        utext_close(&text);
        return _handle_error(L, error);
    }

    i->setText(&text, error);

    if(U_FAILURE(error)) {
        delete i;
        utext_close(&text);
        return _handle_error(L, error);
    }

    int length = 0;
    int32_t p = i->first();
    for(int32_t p = i->first(); p != BreakIterator::DONE; p = i->next()) {
        length++;
    }
    length--; // NUL byte appears to be counted

    lua_pushinteger(L, length);

    delete i;
    utext_close(&text);

    return 1;
}

static int
luaunicode_sub(lua_State *L) throw ()
{
    UErrorCode error = U_ZERO_ERROR;
    UText text = UTEXT_INITIALIZER;
    const char *utf8bytes = luaL_checkstring(L, 1);
    int start = luaL_checkinteger(L, 2);
    int end = lua_tointeger(L, 3);
    size_t start_byte;
    size_t end_byte;

    end_byte = strlen(utf8bytes);

    if(start <= 0 || end < 0) {
        return luaL_error(L, "unicode.sub: start and end must be greater than zero");
    }
    if(end != 0 && start > end) {
        return luaL_error(L, "unicode.sub: start must be less than or equal to end");
    }

    utext_openUTF8(&text, utf8bytes, -1, &error);

    if(U_FAILURE(error)) {
        return _handle_error(L, error);
    }

    BreakIterator *i = BreakIterator::createCharacterInstance(Locale::getUS(), error);

    if(U_FAILURE(error)) {
        utext_close(&text);
        return _handle_error(L, error);
    }

    i->setText(&text, error);

    if(U_FAILURE(error)) {
        delete i;
        utext_close(&text);
        return _handle_error(L, error);
    }

    for(int32_t pos = 1, p = i->first(); p != BreakIterator::DONE; p = i->next(), pos++) {
        if(pos == start) {
            start_byte = p;
            if(! end) {
                break;
            }
        }
        if(end && pos == end + 1) {
            end_byte = p;
            break;
        }
    }
    lua_pushlstring(L, utf8bytes + start_byte, end_byte - start_byte);
    delete i;
    utext_close(&text);

    return 1;
}

static luaL_Reg luaunicode_functions[] = {
    { "length", luaunicode_length },
    { "sub", luaunicode_sub },

    { NULL, NULL }
};

extern "C" int
luaopen_obvious_lib_unicode_native(lua_State *L)
{
#if LUA_VERSION_NUM >= 502
    luaL_newlib(L, luaunicode_functions);
#else
    lua_newtable(L);
    luaL_register(L, NULL, luaunicode_functions);
#endif

    return 1;
}
