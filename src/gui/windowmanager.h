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

#include <string>
#include <vector>
#include <memory>
#include <FL/Fl_Widget.H>
#include <gui/fltkex.h>
#include <gui/window.h>

#ifndef WINDOWMANAGER_H
#define WINDOWMANAGER_H

class WindowManager
{
    WindowManager(const WindowManager&);
    WindowManager& operator=(const WindowManager&);

public:
    WindowManager();
    ~WindowManager();
    void open(const std::string& file, bool fullscreen);

private:
    struct WindowContainer;
    std::vector<std::unique_ptr<WindowContainer>> _windows;

    void window_closed(Fl_Widget* widget);
};

#endif // WINDOWMANAGER_H
