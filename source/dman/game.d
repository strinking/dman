module dman.game;

import derelict.sdl2.sdl;

import dman.config, dman.graphics, dman.input;

struct Game(Config, Graphics, Input)
    if (isConfig!Config && isGraphics!Graphics && isInput!Input)
{
    enum MS_PER_UPDATE = 16.0;

    Config config_;
    Graphics graphics_;
    Input input_;

    private bool running_;

    void run()
    {
        running_ = true;

        SDL_Event e;
        auto previousTimeMs = SDL_GetTicks();
        auto lag = 0.0;

        while (running_) {
            immutable currentTimeMs = SDL_GetTicks();
            immutable elapsedTimeMs = currentTimeMs - previousTimeMs;
            previousTimeMs = currentTimeMs;
            lag += elapsedTimeMs;

            input_.beginNewFrame();

            while (SDL_PollEvent(&e)) {
                switch (e.type) {
                    case SDL_QUIT:
                        running_ = false;
                        break;

                    case SDL_KEYDOWN:
                        input_.keyAction(
                            e.key.keysym.scancode,
                            e.key.repeat ? KeyState.KEY_REPEAT : KeyState.KEY_DOWN
                        );
                        break;

                    case SDL_KEYUP:
                        input_.keyAction(e.key.keysym.scancode, KeyState.KEY_UP);
                        break;

                    default: break;
                }
            }

            if (!running_) break;

            input_.handle();

            while (lag >= MS_PER_UPDATE) {
                update();
                lag -= MS_PER_UPDATE;
            }

            draw();
        }
    }

    private void update()
    {
        // updating goes here //
    }

    private void draw()
    {
        graphics_.renderClear();

        // drawing goes here //

        graphics_.renderPresent();
    }
}
