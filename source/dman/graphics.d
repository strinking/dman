module dman.graphics;

import std.traits : lvalueOf;

import derelict.sdl2.sdl,
       derelict.sdl2.image;

import dman.exception, dman.util;

enum isGraphics(G) = mixin(generateIsSpec(
    "G",
    "loadTexture :: string -> SDL_Texture*
     renderCopy  :: SDL_Texture*, SDL_Rect*, SDL_Rect*
     renderPresent
     renderClear"
));

struct DefaultGraphics
{
    static assert(isGraphics!DefaultGraphics);

    private SDL_Window* window_;
    private SDL_Renderer* renderer_;
    private SDL_Texture*[string] textureCache_;

    this(in string windowTitle, in SDL_Rect windowPosDim)
    {
        import std.string : toStringz;

        window_ = enforceSDL!"a != null"(
            SDL_CreateWindow(
                windowTitle.toStringz,
                windowPosDim.x,
                windowPosDim.y,
                windowPosDim.w,
                windowPosDim.h,
                cast(SDL_WindowFlags) 0
            ),
            "SDL_CreateWindow failed: %s"
        );

        renderer_ = enforceSDL!"a != null"(
            SDL_CreateRenderer(window_, -1, cast(SDL_RendererFlags) 0),
            "SDL_CreateRenderer failed: %s"
        );
    }

    this(in string windowTitle, in int windowWidth, in int windowHeight)
    {
        this(
            windowTitle,
            SDL_Rect(
                SDL_WINDOWPOS_CENTERED,
                SDL_WINDOWPOS_CENTERED,
                windowWidth,
                windowHeight
            )
        );
    }

    this(SDL_Window* window, SDL_Renderer* renderer)
    {
        window_   = window;
        renderer_ = renderer;
    }

    ~this()
    {
        foreach (_, ref texture; textureCache_) {
            SDL_DestroyTexture(texture);
            texture = null;
        }
        textureCache_ = null;

        SDL_DestroyRenderer(renderer_);
        renderer_ = null;

        SDL_DestroyWindow(window_);
        window_ = null;
    }

    SDL_Texture* loadTexture(in string path)
    {
        if (auto tex = path in textureCache_) {
            return *tex;
        }

        auto tex = loadTextureForce(path);
        textureCache_[path] = tex;
        return tex;
    }

    void renderCopy(SDL_Texture* tex, in SDL_Rect* src, in SDL_Rect* dest)
    {
        enforceSDL(
            SDL_RenderCopy(renderer_, tex, src, dest),
            "SDL_RenderCopy failed: %s"
        );
    }

    void renderPresent()
    {
        SDL_RenderPresent(renderer_);
    }

    void renderClear()
    {
        enforceSDL(
            SDL_RenderClear(renderer_),
            "SDL_RenderClear failed: %s"
        );
    }

    private SDL_Texture* loadTextureForce(in string path)
    {
        import std.string : toStringz;

        return enforceSDL!"a"(
            IMG_LoadTexture(renderer_, path.toStringz),
            "IMG_LoadTexture failed: %s"
        );
    }
}
