module dman.util;

import std.file,
       std.path;

import dman.exception;

/*
 * Returns the full path to the resources directory. The resources directory
 * is expected to be one directory up from the executable's path, like:
 *
 * |- game
 *  |- bin
 *   | game executable
 *  |- res
 *   | resources here
 *
 * The path is cached after it is successfully found.
 *
 * Returns: the path to the resources directory
 * Throws: a $(REF GameException) if the resources directory wasn't found
 */
string resourcesDirPath() @trusted
{
    static string path = null;

    if (path is null) {
        auto pathTmp = buildNormalizedPath(dirName(thisExePath()), "..", "res");
        if (!exists(pathTmp)) {
            throw new GameException("The resources directory could not be found.");
        }

        path = pathTmp;
    }

    return path;
}

/*
 * Returns the full path to a resource in the resources directory. The
 * resource's path is cached after it is successfully found.
 *
 * Params:
 *   res = the resource's filename as a string
 * Returns: the path to the resource
 * Throws: a GameException if the resource wasn't found
 */
string resourcePath(in string res) @trusted
{
    static string path = null;

    if (path is null) {
        auto pathTmp = buildNormalizedPath(resourcesDirPath(), res);
        if (!exists(pathTmp)) {
            import std.format : format;
            throw new GameException(format!"The resource '%s' could not be found."(res));
        }

        path = pathTmp;
    }

    return path;
}
