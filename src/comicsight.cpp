/*
 * ComicSight entry point
 *
 * Copyright (c) 2014, Pascal Weisenburger
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <FL/Fl.H>
#include <iostream>
#include "gui/windowmanager.h"

WindowManager* windowManager = nullptr;
extern "C" const char comicsight_version[];

#if _MSC_VER
# define strcasecmp _stricmp
#endif

#ifdef _WIN32
# include <gui/win32.h>
#endif

#ifdef __APPLE__
# include <FL/x.H>
# include <gui/osx.h>

void osx_open_callback(const char* filename)
{
    windowManager->open(filename, false);
}

#endif

#include <FL\Fl_Shared_Image.H>

int main(int argc, char *argv[])
{
    fl_register_images();

    auto fullscreen = false;
    auto file = std::string();

    for (auto i = 1; i < argc; i++)
        if (strcasecmp(argv[i], "-fullscreen") == 0 ||
            strcasecmp(argv[i], "--fullscreen") == 0)
            fullscreen = true;
        else if (strcasecmp(argv[i], "-version") == 0 ||
                 strcasecmp(argv[i], "--version") == 0)
        {
#ifdef _WIN32
            win32::redirect_std_to_console();
#endif
            std::cout << std::endl
                      << "ComicSight" << std::endl
                      << "A viewer for comic book archives" << std::endl
                      << "Version: " << comicsight_version << std::endl << std::endl;
            return 0;
        }
        else if (file.empty())
            file = argv[i];

    windowManager = new WindowManager;
    windowManager->open(file, fullscreen);

#ifdef __APPLE__
    fl_open_callback(osx_open_callback);
    osx::set_about_dialog(nullptr, nullptr, comicsight_version, nullptr, "");
#endif

    // enable multi-threading support by locking from the main thread
    Fl::lock();

    auto result = Fl::run();

    delete windowManager;
    return result;
}
