import std.stdio, core.time, core.thread;

import derelict.sdl2.sdl,
       derelict.sdl2.image;

import dman;

void main()
{
    DerelictSDL2.load();
    DerelictSDL2Image.load();

    enforceSDL(SDL_Init(SDL_INIT_VIDEO), "SDL_Init failed: %s");
    scope(exit) SDL_Quit();

    enforceSDL!(a => (a & IMG_INIT_PNG) == IMG_INIT_PNG)(
        IMG_Init(IMG_INIT_PNG), "IMG_Init failed: %s"
    );
    scope(exit) IMG_Quit();

    Game!(DefaultConfig, DefaultGraphics, DefaultInput)(
        DefaultConfig(resourcePath("config.yml")),
        DefaultGraphics("Hi!", 640, 480),
        DefaultInput()
    ).run();
}
