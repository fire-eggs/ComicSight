/*
 * Window class
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

#include <memory>
#include <FL/Fl_Double_Window.H>
#include <FL/Fl_RGB_Image.H>
#include <util/backgroundworker.h>
#include <gui/fltkex.h>
#include <gui/mixin.h>
#include <controller.h>

#ifndef WINDOW_H
#define WINDOW_H

typedef CursorTimeout<DragAndDrop<MouseDragging<Fl_Double_Window>>>
        ApplicationWindowBase;

class ApplicationWindow : public ApplicationWindowBase, public View
{
public:
    ApplicationWindow(int width, int height, const char* title,
                      Controller* controller, bool fullscreen);
    ~ApplicationWindow();

    void draw() override;
    void resize(int x, int y, int w, int h) override;
    void show() override;
    int handle(int event) override;

    void mouse_dragged(MouseDraggingEvent event, int dx, int dy) override;
    void content_dragged(DragAndDropEvent event) override;
    bool can_hide_cursor() override;

    ViewSize size() override;
    void clipChanged(ViewClip clip) override;

private:
    FlEx::GuiRunner _gui_runner;
    BackgroundWorker _worker;
    Image _scaled;
    bool _quick_scaled;
    bool _fullscreen;
    Controller* _controller;
    int _eyes_x, _eyes_y;
    int _window_width, _window_height;
    bool _mouse_over_center;
    Image _eyes_cover_image;
    std::unique_ptr<Fl_RGB_Image> _eyes_cover;
    void timeout();
    void idle_check();
};

#endif // WINDOW_H
