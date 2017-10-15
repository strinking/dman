module dman.input;

import std.typecons,
       std.bitmanip,
       std.traits;

import derelict.sdl2.sdl;

version (Have_unit_threaded)
{
    import unit_threaded;
}

import dman.util;

enum KeyState
{
    KEY_DOWN,
    KEY_UP,
    KEY_REPEAT
}

alias InputCommand = void delegate();

enum isInput(I) = mixin(generateIsSpec(
    "I",
    "beginNewFrame
     bind      :: SDL_Scancode, KeyState, InputCommand
     keyAction :: SDL_Scancode, KeyState
     handle"
));

struct DefaultInput
{
    static assert(isInput!DefaultInput);

    private static immutable keyStateMembers = [EnumMembers!KeyState];
    private enum keyStateLength = keyStateMembers.length;

    private BitArray frameKeys_;

    private InputCommand[size_t] bindings_;

    static DefaultInput opCall()
    {
        DefaultInput d;
        d.frameKeys_.length = SDL_NUM_SCANCODES * keyStateLength;
        return d;
    }

    void beginNewFrame()
    {
        foreach (i; frameKeys_.bitsSet) {
            frameKeys_[i] = false;
        }
    }

    void bind(in SDL_Scancode sc, in KeyState state, InputCommand cmd) @safe
    {
        bindings_[(cast(size_t) sc) + (cast(size_t) state)] = cmd;
    }

    void keyAction(in SDL_Scancode sc, in KeyState state)
    {
        frameKeys_[(cast(size_t) sc) + (cast(size_t) state)] = true;
    }

    void handle()
    {
        foreach (i; frameKeys_.bitsSet) {
            if (auto cmd = i in bindings_) {
                (*cmd)();
            }
        }
    }

    /* ---------- Unit tests ---------- */
    version (Have_unit_threaded)
    {
        @("integration test") @system unittest
        {
            auto i = DefaultInput();
            bool wasKeyDownCalled, wasKeyUpCalled, wasKeyRepeatCalled;

            i.bind(SDL_SCANCODE_0, KeyState.KEY_DOWN,   { wasKeyDownCalled   = true; });
            i.bind(SDL_SCANCODE_1, KeyState.KEY_UP,     { wasKeyUpCalled     = true; });
            i.bind(SDL_SCANCODE_2, KeyState.KEY_REPEAT, { wasKeyRepeatCalled = true; });

            // Simulate input
            i.beginNewFrame();
            i.keyAction(SDL_SCANCODE_0, KeyState.KEY_DOWN);
            i.keyAction(SDL_SCANCODE_1, KeyState.KEY_UP);
            i.keyAction(SDL_SCANCODE_2, KeyState.KEY_REPEAT);

            // Everything should've been called
            i.handle();
            wasKeyDownCalled.shouldBeTrue();
            wasKeyUpCalled.shouldBeTrue();
            wasKeyRepeatCalled.shouldBeTrue();

            // Should not fire anything for unbound keys
            i.beginNewFrame();
            wasKeyDownCalled   = false;
            wasKeyUpCalled     = false;
            wasKeyRepeatCalled = false;

            i.keyAction(SDL_SCANCODE_A, KeyState.KEY_DOWN);
            i.keyAction(SDL_SCANCODE_B, KeyState.KEY_UP);
            i.keyAction(SDL_SCANCODE_C, KeyState.KEY_REPEAT);
            wasKeyDownCalled.shouldBeFalse();
            wasKeyUpCalled.shouldBeFalse();
            wasKeyRepeatCalled.shouldBeFalse();

            i.keyAction(SDL_SCANCODE_0, KeyState.KEY_UP);
            i.keyAction(SDL_SCANCODE_1, KeyState.KEY_REPEAT);
            i.keyAction(SDL_SCANCODE_2, KeyState.KEY_DOWN);
            wasKeyDownCalled.shouldBeFalse();
            wasKeyUpCalled.shouldBeFalse();
            wasKeyRepeatCalled.shouldBeFalse();
        }
    }
}
