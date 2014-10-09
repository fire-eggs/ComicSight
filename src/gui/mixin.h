/*
 * Mixin classes
 * providing abstractions to access to certain FLTK events or
 * implementations of specific behavior
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

#include <chrono>
#include <FL/Fl.H>
#include <gui/fltkex.h>

#ifndef MIXIN_H
#define MIXIN_H

template<class FlWindow>
class CursorTimeout : public FlWindow
{
    typedef CursorTimeout This;
    enum class State : char { Visible, Waiting, Hidden };

    State _state;
    double _timeout;

    void idle_check()
    {
        if (_state == State::Visible)
        {
            Fl::add_timeout(2, FL_CALLBACK_MEMBER(timeout));
            _state = State::Waiting;
        }
    }

    void timeout()
    {
        if (_state == State::Waiting)
        {
            if (can_hide_cursor())
                FlWindow::cursor(FL_CURSOR_NONE);
            _state = State::Hidden;
        }
    }

public:
    CursorTimeout(): FlWindow(), _state(State::Visible), _timeout(2)
      { Fl::add_check(FL_CALLBACK_MEMBER(idle_check)); }

    template<class A>
    CursorTimeout(A a) : FlWindow(a), _state(State::Visible), _timeout(2)
      { Fl::add_check(FL_CALLBACK_MEMBER(idle_check)); }

    template<class A, class B>
    CursorTimeout(A a, B b) : FlWindow(a, b), _state(State::Visible), _timeout(2)
      { Fl::add_check(FL_CALLBACK_MEMBER(idle_check)); }

    template<class A, class B, class C>
    CursorTimeout(A a, B b, C c) : FlWindow(a, b, c), _state(State::Visible), _timeout(2)
      { Fl::add_check(FL_CALLBACK_MEMBER(idle_check)); }

    template<class A, class B, class C, class D>
    CursorTimeout(A a, B b, C c, D d) : FlWindow(a, b, c, d), _state(State::Visible), _timeout(2)
      { Fl::add_check(FL_CALLBACK_MEMBER(idle_check)); }

    template<class A, class B, class C, class D, class E>
    CursorTimeout(A a, B b, C c, D d, E e) : FlWindow(a, b, c, d, e), _state(State::Visible), _timeout(2)
      { Fl::add_check(FL_CALLBACK_MEMBER(idle_check)); }

    int handle(int event) override
    {
        if (event == FL_ENTER || event == FL_LEAVE)
        {
            _state = State::Hidden;
        }
        else if (event == FL_MOVE || event == FL_DRAG)
        {
            if (_state == State::Hidden)
            {
                // explicit static cast as a workaround for GCC 4.7
                Fl::remove_timeout(FL_CALLBACK_MEMBER_FOR(static_cast<CursorTimeout*>(this), idle_check));
                FlWindow::cursor(FL_CURSOR_DEFAULT);
                _state = State::Visible;
            }
        }

        return FlWindow::handle(event);
    }

    std::chrono::milliseconds cursor_timeout() const
    {
        using namespace std::chrono;
        return milliseconds(static_cast<milliseconds::rep>(1000 * _timeout));
    }

    template<class Rep, class Period>
    void cursor_timeout(const std::chrono::duration<Rep, Period>& timeout)
    {
        using namespace std::chrono;
        _timeout = duration_cast<milliseconds>(timeout).count() / 1000.0;
    }

    virtual bool can_hide_cursor() { return true; }
};

enum class MouseDraggingEvent { Start, Drag, Stop };

template<class FlWindow>
class MouseDragging : public FlWindow
{
    bool _dragging;
    int _x, _y;

public:
    MouseDragging(): FlWindow(), _dragging(false) { }

    template<class A>
    MouseDragging(A a) : FlWindow(a), _dragging(false) { }

    template<class A, class B>
    MouseDragging(A a, B b) : FlWindow(a, b), _dragging(false) { }

    template<class A, class B, class C>
    MouseDragging(A a, B b, C c) : FlWindow(a, b, c), _dragging(false) { }

    template<class A, class B, class C, class D>
    MouseDragging(A a, B b, C c, D d) : FlWindow(a, b, c, d), _dragging(false) { }

    template<class A, class B, class C, class D, class E>
    MouseDragging(A a, B b, C c, D d, E e) : FlWindow(a, b, c, d, e), _dragging(false) { }

    int handle(int event) override
    {
        if (event == FL_PUSH)
        {
            _x = Fl::event_x(), _y = Fl::event_y();
        }
        else if (event == FL_RELEASE)
        {
            _dragging = false;
            mouse_dragged(MouseDraggingEvent::Stop, 0, 0);
        }
        else if (event == FL_DRAG)
        {
            const int dx = _x - Fl::event_x(), dy = _y - Fl::event_y();

            _x = Fl::event_x(), _y = Fl::event_y();
            if (!_dragging)
            {
                _dragging = true;
                mouse_dragged(MouseDraggingEvent::Start, dx, dy);
            }
            else
                mouse_dragged(MouseDraggingEvent::Drag, dx, dy);
        }

        return FlWindow::handle(event);
    }

    bool mouse_dragging() const { return _dragging; }

    virtual void mouse_dragged(MouseDraggingEvent event, int dx, int dy) { }
};

enum class DragAndDropEvent { Enter, Drag, Drop, Leave };

template<class FlWindow>
class DragAndDrop : public FlWindow
{
    bool _dragging;
    std::string _content;

    static inline std::string get_content()
    {
        auto length = 0;
        auto str = Fl::event_text();
        while (*str && *str != '\r' && *str != '\n')
            ++str, ++length;

        return std::string(Fl::event_text(), length);
    }

public:
    DragAndDrop(): FlWindow(), _dragging(false) { }

    template<class A>
    DragAndDrop(A a) : FlWindow(a), _dragging(false) { }

    template<class A, class B>
    DragAndDrop(A a, B b) : FlWindow(a, b), _dragging(false) { }

    template<class A, class B, class C>
    DragAndDrop(A a, B b, C c) : FlWindow(a, b, c), _dragging(false) { }

    template<class A, class B, class C, class D>
    DragAndDrop(A a, B b, C c, D d) : FlWindow(a, b, c, d), _dragging(false) { }

    template<class A, class B, class C, class D, class E>
    DragAndDrop(A a, B b, C c, D d, E e) : FlWindow(a, b, c, d, e), _dragging(false) { }

    int handle(int event) override
    {
        if (event == FL_DND_ENTER)
            _dragging = false, _content.clear();

        if ((event == FL_DND_ENTER || event == FL_DND_DRAG) &&
                Fl::event_text() != nullptr &&
                strcmp(Fl::event_text(), "<unknown>") != 0)
        {
            if (!_dragging)
            {
                _content = get_content();
                if (!_content.empty())
                {
                    _dragging = true;
                    content_dragged(DragAndDropEvent::Enter);
                }
            }
            else
                content_dragged(DragAndDropEvent::Drag);
        }
        else if (event == FL_DND_LEAVE && _dragging)
        {
            _dragging = false;
            content_dragged(DragAndDropEvent::Leave);
            _content.clear();
        }
        else if (event == FL_PASTE)
        {
            if (_content.empty())
                _content = get_content();

            if (!_content.empty())
            {
                _dragging = false;
                content_dragged(DragAndDropEvent::Drop);
            }
        }

        if (event == FL_DND_ENTER || event == FL_DND_DRAG ||
            event == FL_DND_LEAVE || event == FL_DND_RELEASE)
        {
            FlWindow::handle(event);
            return 1;
        }

        return FlWindow::handle(event);
    }

    bool content_dragging() const { return _dragging; }

    const std::string& dragged_content() const { return _content; }

    virtual void content_dragged(DragAndDropEvent event) { }
};

#endif // MIXIN_H
