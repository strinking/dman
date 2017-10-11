module dman.exception;

class GameException : Exception
{
    import std.exception : basicExceptionCtors;

    mixin basicExceptionCtors;
}
