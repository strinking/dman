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

/**
 * Generates an is-specification at compile-time for use with DbI.
 * Use with mixin.
 *
 * Params:
 *   typename = the type variable to use in the specification
 *   spec = a string of newline-separated function specifications, formatted
 *          like `name :: argType1, argType2, ..., argTypeN -> retType`
 * Returns: the generated specification -- might be invalid D code if the
 *          given `spec` doesn't have valid D types and identifiers and such
 *          or is malformed
 */
string generateIsSpec(string typename, string spec) @safe pure
{
    import std.string    : lineSplitter, strip;
    import std.algorithm : findSplit, splitter;
    import std.range     : empty;

    auto buf = "{\nimport std.traits : lvalueOf;\n" ~
               "return is(typeof(" ~ typename ~ ".init) == " ~ typename ~ ") &&\n";
    auto specSplitted = spec.lineSplitter;

    size_t i;
    foreach (const l; specSplitted) {
        if (l.strip.empty) {
            continue;
        }

        if (i != 0 && !specSplitted.empty) {
            buf ~= " &&\n";
        }

        buf ~= "is(typeof(lvalueOf!(" ~ typename ~ ").";

        if (auto parts = l.findSplit("::")) {
            auto fname = parts[0].strip;
            buf ~= fname ~ "(";

            auto fspec = parts[2].findSplit("->");

            auto fparams = (fspec ? fspec[0] : parts[2]).splitter(',');
            if (!fparams.empty) {
                auto j = 0;
                foreach (const param; fparams) {
                    if (j != 0 && !fparams.empty) {
                        buf ~= ", ";
                    }

                    buf ~= "lvalueOf!(" ~ param.strip ~ ")";

                    ++j;
                }

                buf ~= ")";
            }

            buf ~= ")";

            auto fretType = fspec[2].strip;
            if (!fretType.empty && fretType != "void") {
                buf ~= " == " ~ fretType;
            }
        } else if (auto parts = l.findSplit("->")) {
            auto fname = parts[0].strip;
            buf ~= fname ~ "())";

            auto fretType = parts[2].strip;
            if (!fretType.empty && fretType != "void") {
                buf ~= " == " ~ fretType;
            }
        } else {
            buf ~= l.strip ~ "())";
        }

        buf ~= ")";
        ++i;
    }

    return buf ~ ";\n}()";
}
