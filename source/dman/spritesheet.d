module dman.spritesheet;

import derelict.sdl2.sdl;

version (Have_unit_threaded)
{
    import unit_threaded;
}

import dman.util,
       dman.graphics;

enum isSpritesheet(S) = mixin(generateIsSpec(
    "S",
    "draw :: DefaultGraphics, size_t, SDL_Rect"
    // ^ instead of DefaultGraphics, you can use anything that isGraphics!T
    // responds true.
));

struct DefaultSpritesheet
{
    immutable private SDL_Rect textureSize_, spriteSize_;
    immutable private size_t maxSpriteIndex_;
    private SDL_Texture* texture_;

    this(Graphics)(Graphics graphics, in string filename, in SDL_Rect spriteSize)
        if (isGraphics!Graphics)
    {
        texture_ = graphics.loadTexture(filename);
        SDL_QueryTexture(texture_, null, null, &textureSize_.w, &textureSize_.h);

        spriteSize_     = spriteSize;
        maxSpriteIndex_ = getMaxSpriteIndex(textureSize_, spriteSize);
    }

    void draw(Graphics)(Graphics graphics, in size_t index, in SDL_Rect destRect)
        if (isGraphics!Graphics)
    in
    {
        assert(index < maxSpriteIndex_, "given index must be less than max sprite index");
    }
    body
    {
        auto srcRect = getSpritePos(index, textureSize_, spriteSize_);
        graphics.renderCopy(texture_, &srcRect, &destRect);
    }

    private SDL_Rect getSpritePos(in size_t index, in SDL_Rect texSize, in SDL_Rect sprSize) @safe const pure
    out (r)
    {
        assert(r.w < texSize.w && r.h < texSize.h);
    }
    body
    {
        immutable sprHorz = index * sprSize.w;
        immutable sprVert =
            sprHorz >= texSize.w ? (sprHorz / texSize.w) * sprSize.h : 0;

        return SDL_Rect(sprHorz % texSize.w, sprVert, sprSize.w, sprSize.h);
    }

    private size_t getMaxSpriteIndex(SDL_Rect texSize, SDL_Rect spriteSize) @safe const pure
    in
    {
        assert(texSize.w    > 0, "texture width must be greater than 0");
        assert(texSize.h    > 0, "texture height must be greater than 0");
        assert(spriteSize.w > 0, "sprite width must be greater than 0");
        assert(spriteSize.h > 0, "sprite height must be greater than 0");
    }
    body
    {
        import std.math : floor;

        immutable sprHorz = cast(size_t) floor((cast(real) texSize.w) / spriteSize.w);
        immutable sprVert = cast(size_t) floor((cast(real) texSize.h) / spriteSize.h);

        return sprHorz * sprVert;
    }

    /* ---------- Unittests ---------- */
    version (Have_unit_threaded)
    {
        @("test getMaxSpriteIndex") @safe unittest
        {
            const s = DefaultSpritesheet.init;
            s.getMaxSpriteIndex(SDL_Rect(0, 0, 32, 32), SDL_Rect(0, 0, 8, 8))
             .shouldEqual(16);
        }

        @("test getSpritePos") @safe unittest
        {
            auto s = DefaultSpritesheet.init;
            s.getSpritePos(4, SDL_Rect(0, 0, 32, 32), SDL_Rect(0, 0,  8,  8))
             .shouldEqual(SDL_Rect(0, 8, 8, 8));
        }
    }
}
