module dman.config;

import std.traits : lvalueOf;

import dyaml;

version (Have_unit_threaded)
{
    import unit_threaded;
}

enum isConfig(C) =
    is(typeof(C.init) == C) &&
    is(typeof(lvalueOf!(C).read!int("a")) == int) &&
    is(typeof(lvalueOf!(C).fetch!int("a", 123)) == int) &&
    is(typeof(lvalueOf!(C).write("a", 123)));

struct DefaultConfig
{
    static assert(isConfig!DefaultConfig);

    Node rootNode;

    this(Node rootNode) @safe
    {
        this.rootNode = rootNode;
    }

    this(in string fileName) @safe
    {
        rootNode = Loader(fileName).load();
    }

    static DefaultConfig fromString(in string yaml) @safe
    {
        return DefaultConfig(Loader.fromString(yaml.dup).load());
    }

    T read(T = Node)(in string key) @safe
    {
        import std.algorithm.iteration : splitter;
        import std.traits : fullyQualifiedName;

        auto node = rootNode;
        foreach (part; splitter(key, ".")) {
            node = node[part];
        }

        static if (is(T : Node)) {
            return node;
        } else {
            assert(
                node.convertsTo!T,
                "the given type `" ~ fullyQualifiedName!T ~
                "` cannot be converted to the node's type `" ~ node.nodeTypeString ~ "`."
            );

            return node.as!(T);
        }
    }

    T fetch(T = Node)(in string key, lazy T defaultValue) @safe
    {
        import std.exception : ifThrown;
        return read!T(key).ifThrown!NodeException(defaultValue);
    }

    void write(T)(in string key, T value) @trusted
    {
        import std.algorithm.iteration : splitter;

        auto node = &rootNode;
        foreach (part; splitter(key, ".")) {
            if (!node.containsKey(part)) {
                // the lambda is just so the correct overload is taken (make node as mapping)
                (*node)[part] = Node({ Node[string] placeholder; return placeholder; }());
            }

            node = &((*node)[part]);
        }

        *node = Node(value);
    }

    /* ---------- Unittests ---------- */
    version (Have_unit_threaded)
    {
        @("test reading") @safe unittest
        {
            import core.exception : AssertError;

            auto c = DefaultConfig.fromString(
                "---\n" ~
                "a: 1    \n" ~
                "b: hello\n" ~
                "c: 3.14 \n" ~
                "d:      \n" ~
                "  e: foo"
            );

            // Can read simple keys
            c.read!int("a").shouldEqual(1);
            c.read!string("b").shouldEqual("hello");
            c.read!real("c").shouldApproxEqual(3.14);

            // Can read nested keys
            c.read!string("d.e").shouldEqual("foo");

            // Defaults to Node
            typeid(c.read("d")).shouldEqual(typeid(Node));

            // Throws AssertError on mismatched types
            c.read!int("b").shouldThrowExactly!(AssertError);
        }

        @("test fetching") @safe unittest
        {
            import core.exception : AssertError;

            auto c = DefaultConfig.fromString("---\na: hi");

            // Can read existing keys
            c.fetch!string("a", "hmm").shouldEqual("hi");

            // Falls back to default when the key doesn't exist
            c.fetch!int("b", 756).shouldEqual(756);

            // Still throws AssertError on mismatched types
            c.fetch!int("a", 0).shouldThrowExactly!(AssertError);
        }

        @("test writing") @system unittest
        {
            auto c = DefaultConfig.fromString("---\na: 123");

            // Can write to simple keys
            c.write("b", 321).shouldNotThrow();
            c.rootNode["b"].shouldNotThrow();
            c.rootNode["b"].as!(int).shouldEqual(321);

            // Can write to nested keys
            c.write("foo.bar", "hello").shouldNotThrow();
            c.rootNode["foo"].shouldNotThrow();
            c.rootNode["foo"]["bar"].shouldNotThrow();
            c.rootNode["foo"]["bar"].as!(string).shouldEqual("hello");

            // Can overwrite previously existing keys
            c.rootNode["a"].as!(int).shouldEqual(123);
            c.write("a", 3.14);
            c.rootNode["a"].as!(real).shouldApproxEqual(3.14);
        }
    }
}
