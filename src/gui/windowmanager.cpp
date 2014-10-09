/*
 * Window Manager class
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

#ifdef HAVE_X11
# include <FL/x.H>
# include <gui/x11.h>
# include "comicsight.xpm"

extern "C" const unsigned char comicsight_data[];
extern "C" const int comicsight_size;

#endif

#ifdef _WIN32
# include <windows.h>
# include <FL/x.H>
#endif

#include <util/vfsresolver.h>
#include "windowmanager.h"

#ifdef HAVE_X11
bool window_already_visible(Display* display, Window window,
                            const char* res_name, const char* res_class)
{
    auto hint = XAllocClassHint();
    auto result = XGetClassHint(display, window, hint) != 0 &&
                  strcmp(hint->res_name, res_name) == 0 &&
                  strcmp(hint->res_class, res_class) == 0;
    XFree(hint);

    if (result)
        return true;

    Window root_return, parent_return;
    Window* children = nullptr;
    unsigned int nchildren;
    if (XQueryTree(display, window, &root_return, &parent_return, &children, &nchildren) != 0)
        for (auto i = 0u; i < nchildren; ++i)
            if ((result = window_already_visible(display, children[i],
                                                 res_name, res_class)))
                break;

    if (children)
        XFree(children);

    return result;
}
#endif // HAVE_X11

#ifdef _WIN32
bool window_already_visible(const char* class_name)
{
    return FindWindowA(class_name, nullptr) != nullptr;
}
#endif // _WIN32

struct WindowManager::WindowContainer
{
    WindowContainer(int width, int height, const char* title, bool fullscreen)
        : window(width, height, title, &controller, fullscreen) { }

    Controller controller;
    ApplicationWindow window;
    Fl_Callback_p original_callback;
};

WindowManager::WindowManager() { }

WindowManager::~WindowManager() { }

void WindowManager::open(const std::string& file, bool fullscreen)
{
    auto activeWindows = false;
    for (const auto& container : _windows)
        if (container->window.visible())
        {
            activeWindows = true;
            break;
        }

    // if this application instance has already created one single window
    // that has no comic loaded, we just reuse this window instead of
    // creating a new one
    // this is especially important on OS X, since we are not informed about the
    // comic file to be opened via a command line paramater but via a special
    // callback from the system that is called at some later point in time
    if (_windows.size() != 1 ||
            (_windows.size() == 1 && _windows[0]->controller.comic().valid()))
    {
        auto container = new WindowContainer(std::max(Fl::w() * 2/3, 640),
                                             std::max(Fl::h() * 2/3, 480),
                                             "ComicSight",
                                             fullscreen);

        container->original_callback = container->window.callback();
        container->window.callback(FL_CALLBACK_MEMBER(window_closed));
        _windows.push_back(std::unique_ptr<WindowContainer>(container));
    }

#ifdef HAVE_X11
    if (window_already_visible(fl_display, DefaultRootWindow(fl_display),
                               "comicsight", "Comicsight"))
        activeWindows = true;
#endif

#ifdef _WIN32
    if (window_already_visible("comicsight"))
        activeWindows = true;
#endif

    auto& container = _windows.back();
    container->controller.comic(std::move(Comic(vfs_resolver::resolve(file))));

    if (!activeWindows)
        container->window.position(Fl::x() + (Fl::w() - container->window.w()) / 2,
                                   Fl::y() + (Fl::h() - container->window.h()) / 2);

    container->window.size_range(640, 480);
    container->window.xclass("comicsight");
#ifdef _WIN32
    container->window.icon(LoadIcon(fl_display, MAKEINTRESOURCE(100)));
#endif
    container->window.show();

#ifdef HAVE_X11
    x11::set_window_machine_name(&container->window);
    x11::set_window_pid(&container->window);
    x11::set_window_wm_icon(&container->window, comicsight_data, comicsight_size);
    x11::set_window_hint_icon(&container->window, comicsight_icon);
#endif
}

void WindowManager::window_closed(Fl_Widget* widget)
{
    for (auto& container : _windows)
        if (&container->window == widget)
        {
            container->controller.comic(std::move(Comic()));
            container->original_callback(widget, nullptr);
            return;
        }
}
