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

#include <FL/Fl.H>
#include <FL/fl_draw.H>
#include <FL/Fl_PNG_Image.H>
#include <util/vfsresolver.h>
#include <image/resample.h>
#include "window.h"

extern "C" const unsigned char eyes_data[];
extern "C" const int eyes_size;

extern "C" const unsigned char eyes_background_data[];
extern "C" const int eyes_background_size;

extern "C" const unsigned char eyes_foreground_data[];
extern "C" const int eyes_foreground_size;

namespace
{
    Fl_PNG_Image eyes(nullptr, eyes_data, eyes_size);
    Fl_PNG_Image eyes_background(nullptr, eyes_background_data, eyes_background_size);
    Fl_PNG_Image eyes_foreground(nullptr, eyes_foreground_data, eyes_foreground_size);
}

ApplicationWindow::ApplicationWindow(int width, int height, const char* title,
                                     Controller* controller, bool fullscreen)
    : ApplicationWindowBase(width, height, title),
      _fullscreen(fullscreen), _controller(controller),
      _eyes_x(0), _eyes_y(0), _window_width(width), _window_height(height),
      _mouse_over_center(false), _eyes_cover_image(100, 100, 4)
{
    _controller->add_view(this);

    memset(_eyes_cover_image.data(), 0, _eyes_cover_image.size());
    for (auto y = 2, dy = -48; y < 100; ++y, ++dy)
        for (auto x = 2, dx = -48; x < 100; ++x, ++dx)
            if (dx * dx + dy * dy < 48 * 48)
                _eyes_cover_image(x, y, 3) = 0xA0;

    resizable(this);
    Fl::add_check(FL_CALLBACK_MEMBER(idle_check));
}

ApplicationWindow::~ApplicationWindow()
{
    _controller->remove_view(this);
}

void ApplicationWindow::draw()
{
    ApplicationWindowBase::draw();

    fl_color(0, 0, 0);
    fl_rectf(0, 0, _window_width, _window_height);

    if (_controller->comic().page_image().empty() || content_dragging())
    {
        auto x = (_window_width - eyes_background.w()) / 2;
        auto y = (_window_height - eyes_background.h()) / 2;

        eyes_background.draw(x, y);
        eyes.draw(_eyes_x + x + 76, _eyes_y + y + 108);
        eyes.draw(_eyes_x + x + 260, _eyes_y + y + 108);
        if (_eyes_cover)
        {
            _eyes_cover->draw(x + 48, y + 80);
            _eyes_cover->draw(x + 232, y + 80);
        }
        eyes_foreground.draw(x + 48, y + 80);
        eyes_foreground.draw(x + 232, y + 80);

        if (content_dragging() || (_mouse_over_center && _controller->comic().page_count() == 0))
        {
            auto text = "Drop a comic here to open it";
            fl_color(48, 48, 48);
            fl_font(FL_HELVETICA_BOLD, 30);
            auto width = static_cast<int>(fl_width(text));
            fl_draw(text, (_window_width - width) / 2, y + eyes_background.h() + 15);
        }
        else if (_controller->comic().page_image().empty() &&
                 _controller->comic().page_count() != 0)
        {
            auto text = "I cannot show the current page :(";
            fl_color(128, 0, 0);
            fl_font(FL_HELVETICA_BOLD, 30);
            auto width = static_cast<int>(fl_width(text));
            fl_draw(text, (_window_width - width) / 2, y + eyes_background.h() + 15);

            if (_mouse_over_center)
            {
                auto text = "Is the unRAR utility missing?";
                fl_color(128, 0, 0);
                fl_font(FL_HELVETICA_BOLD, 20);
                auto width = static_cast<int>(fl_width(text));
                fl_draw(text, (_window_width - width) / 2, y + eyes_background.h() + 38);
            }
        }
    }
    else
        fl_draw_image(_scaled.data(),
                      (_window_width - _scaled.width()) / 2,
                      (_window_height - _scaled.height()) / 2,
                      _scaled.width(), _scaled.height(), 3, 0);
}

void ApplicationWindow::resize(int x, int y, int w, int h)
{
    ApplicationWindowBase::resize(x, y, _window_width = w, _window_height = h);
    _controller->perform(this, Action::Resize);
}

void ApplicationWindow::show()
{
    ApplicationWindowBase::show();
    if (_fullscreen)
        fullscreen();
}

int ApplicationWindow::handle(int event)
{
    bool mouse_over_window =
            Fl::event_x() >= 0 && Fl::event_x() < _window_width &&
            Fl::event_y() >= 0 && Fl::event_y() < _window_height;

    if (mouse_over_window &&
        (event == FL_MOVE || event == FL_DRAG || event == FL_DND_DRAG) &&
        (_controller->comic().page_image().empty() || content_dragging()))
    {
        auto dx = std::abs(Fl::event_x() - _window_width / 2);
        auto dy = std::abs(Fl::event_y() - _window_height / 2);
        _mouse_over_center = dx < eyes_background.w() / 2 + 64 &&
                             dy < eyes_background.h() / 2 + 64;

        _eyes_x = -16 + 32 * Fl::event_x() / _window_width;
        _eyes_y = -16 + 32 * Fl::event_y() / _window_height;
        redraw();
    }
    if (event == FL_LEAVE || event == FL_DND_LEAVE || !mouse_over_window)
    {
        if (_eyes_x != 0 || _eyes_y != 0 || _mouse_over_center)
        {
            _eyes_x = 0, _eyes_y = 0, _mouse_over_center = false;
            redraw();
        }
    }
    if (event == FL_KEYDOWN)
    {
        if (Fl::event_key(FL_Escape) && fullscreen_active() && !_fullscreen)
        {
            fullscreen_off();
            return 1; // prevent window from closing
        }
        if (Fl::event_key(FL_F + 11) || strcmp(Fl::event_text(), "\r") == 0)
        {
            if (!_fullscreen)
                fullscreen_active() ? fullscreen_off() : fullscreen();
        }

        if ((Fl::event_key(FL_Right) && Fl::event_ctrl()) || strcmp(Fl::event_text(), " ") == 0)
            _controller->perform(this, Action::Next);
        if ((Fl::event_key(FL_Left) && Fl::event_ctrl()) || Fl::event_key(FL_BackSpace))
            _controller->perform(this, Action::Previous);
        if (Fl::event_key(FL_Right))
            _controller->perform(this, Action::Right);
        if (Fl::event_key(FL_Left))
            _controller->perform(this, Action::Left);
        if (Fl::event_key(FL_Down))
            _controller->perform(this, Action::Down);
        if (Fl::event_key(FL_Up))
            _controller->perform(this, Action::Up);
        if (strcmp(Fl::event_text(), "+") == 0)
            _controller->perform(this, Action::In);
        if (strcmp(Fl::event_text(), "-") == 0)
            _controller->perform(this, Action::Out);
    }
    if (event == FL_MOUSEWHEEL)
    {
        if (Fl::event_dy() < 0)
            _controller->perform(this, Action::In);
        if (Fl::event_dy() > 0)
            _controller->perform(this, Action::Out);
    }

    return ApplicationWindowBase::handle(event);
}

void ApplicationWindow::mouse_dragged(MouseDraggingEvent event, int dx, int dy)
{
    ApplicationWindowBase::mouse_dragged(event, dx, dy);

    if (!_controller->comic().page_image().empty())
    {
        if (event == MouseDraggingEvent::Start)
            cursor(FL_CURSOR_MOVE);
        if (event == MouseDraggingEvent::Stop)
            cursor(FL_CURSOR_DEFAULT);
        _controller->perform(this, Action::Move, dx, dy);
    }
}

void ApplicationWindow::content_dragged(DragAndDropEvent event)
{
    ApplicationWindowBase::content_dragged(event);

    if (event == DragAndDropEvent::Enter)
    {
        auto comic = Comic(vfs_resolver::resolve(dragged_content()));
        comic.page(0);

        auto cover = comic.page_image();
        if (!cover.empty())
        {
            auto scale = std::max(100.0f / cover.width(), 100.0f / cover.height());
            auto scaled = image::resample_lanczos(
                                cover, scale,
                                (static_cast<int>(scale * cover.width()) - 100) / 2,
                                0,
                                100, 100);

            for (auto y = 0; y < 100; ++y)
                for (auto x = 0; x < 100; ++x)
                    for (auto c = 0; c < 3; c++)
                        _eyes_cover_image(x, y, c) = scaled(x, y, c);

            _eyes_cover.reset(new Fl_RGB_Image(_eyes_cover_image.data(), 100, 100, 4));
            redraw();
        }
    }

    if (event == DragAndDropEvent::Drop || event == DragAndDropEvent::Leave)
    {
        _eyes_cover.reset();
        redraw();
    }

    if (event == DragAndDropEvent::Drop)
    {
        auto comic = Comic(vfs_resolver::resolve(dragged_content()));
        if (comic.valid())
            _controller->comic(std::move(comic));
    }
}

bool ApplicationWindow::can_hide_cursor()
{
    return !_controller->comic().page_image().empty();
}

ViewSize ApplicationWindow::size()
{
    return ViewSize(_window_width, _window_height);
}

void ApplicationWindow::clipChanged(ViewClip clip)
{
    auto image = _controller->comic().page_image();

    _scaled = image::resample_nearest_neighbor_fast(
            image, clip.scale, clip.x, clip.y,
            std::min(static_cast<int>(clip.scale * image.width()), _window_width),
            std::min(static_cast<int>(clip.scale * image.height()), _window_height));

    _worker.cancel();
    _gui_runner.cancel();

    Fl::remove_timeout(FL_CALLBACK_MEMBER(timeout));
    Fl::add_timeout(0.5, FL_CALLBACK_MEMBER(timeout));

    redraw();
#ifndef __APPLE__
    // under OS X this can cause runtime failure
    Fl::flush();
#endif
}

void ApplicationWindow::timeout()
{
    _quick_scaled = true;
}

void ApplicationWindow::idle_check()
{
    if (_quick_scaled && !_controller->comic().page_image().empty())
    {
        _quick_scaled = false;
        Fl::remove_timeout(FL_CALLBACK_MEMBER(timeout));

        const auto page_image = _controller->comic().page_image();
        const auto scale = _controller->clip(this).scale;
        const auto x = _controller->clip(this).x, y = _controller->clip(this).y;
        const auto width = _window_width, height = _window_height;

        _worker.run([this, page_image, scale, x, y, width, height]
        {
            if (_worker.canceled())
                return;

            auto image = image::resample_lanczos(
                        page_image, scale, x, y,
                        std::min(static_cast<int>(scale * page_image.width()), width),
                        std::min(static_cast<int>(scale * page_image.height()), height),
                        [this] { return _worker.canceled(); });

            if (_worker.canceled())
                return;

            _gui_runner.run([this, image]
            {
                _scaled = std::move(image);
                redraw();
            });
        });
    }
}
