module dman.exception;

import std.exception;

class GameException : Exception
{
    mixin basicExceptionCtors;
}

class SDLException : GameException
{
    import std.format : format;
    import std.string : fromStringz;

    import derelict.sdl2.sdl : SDL_GetError;

    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(msg.format(fromStringz(SDL_GetError())), file, line, next);
    }

    this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg.format(fromStringz(SDL_GetError())), file, line, next);
    }
}

T enforceSDL(alias cmp = "a == 0", T)(T a, lazy string message)
{
    import std.functional : unaryFun;

    if (!unaryFun!(cmp)(a)) {
        throw new SDLException(message);
    }

    return a;
}
