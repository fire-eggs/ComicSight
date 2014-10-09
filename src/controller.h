/*
 * Window View Controller class
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

#include <FL/Fl_Window.H>
#include <vector>
#include <utility>
#include <comic/comic.h>

#ifndef CONTROLLER_H
#define CONTROLLER_H

enum class Action { Resize, Move, Left, Right, Up, Down, In, Out, Next, Previous };

struct ViewSize
{
    int width, height;
    ViewSize(int width, int height) : width(width), height(height) { }
};

struct ViewClip
{
    int x, y;
    float scale;
    ViewClip(int x, int y, float scale) : x(x), y(y), scale(scale) { }
};

class View
{
public:
    virtual ViewSize size() = 0;
    virtual void clipChanged(ViewClip clip) = 0;
};

class Controller
{
public:
    void add_view(View* view);
    void remove_view(View* view);

    void comic(Comic&& comic);
    const Comic& comic() const { return _comic; }

    ViewClip clip(View* view) const;

    void perform(View *view, Action action, int move_dx = 0, int move_dy = 0);

private:
    float _x, _y, _scale;
    Comic _comic;
    std::vector<std::pair<View*, ViewClip>> _views;

    void updateAlignment(float x, float y, float scale, bool page_changed,
                         View *only_view = nullptr);
};

#endif // CONTROLLER_H
