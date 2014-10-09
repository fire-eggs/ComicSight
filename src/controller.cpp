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

#include <FL/Fl.H>
#include <util/vfsresolver.h>
#include "controller.h"

namespace
{
    template<typename T>
    inline void minmax(T& value, const T& min, const T& max)
    {
        value = value >= max ? max : value <= min ? min : value;
    }

    template<typename Views, typename View>
    inline const ViewClip* lookup(const Views& views, View* view)
    {
        for (const auto& view_clip : views)
            if (view_clip.first == view)
                return &view_clip.second;
        return nullptr;
    }
}

void Controller::add_view(View* view)
{
    if (!lookup(_views, view))
    {
        _views.push_back(std::make_pair(view, ViewClip(0, 0, 1.0f)));
        updateAlignment(0.5f, 0.5f, 1.0f, true, view);
    }
}

void Controller::remove_view(View* view)
{
    for (auto iterator = _views.begin(); iterator != _views.end(); ++iterator)
        if (iterator->first == view)
        {
            _views.erase(iterator);
            return;
        }
}

void Controller::comic(Comic&& comic)
{
    _comic = std::move(comic);
    updateAlignment(0.5f, 0.5f, 1.0f, true);
}

ViewClip Controller::clip(View* view) const
{
    ViewClip result(0, 0, 1.0f);
    if (auto clip = lookup(_views, view))
        result = *clip;
    return result;
}

void Controller::updateAlignment(float x, float y, float scale, bool page_changed,
                                 View* only_view)
{
    // make sure values are in bounds
    minmax(scale, 1.0f, 40.0f);
    minmax(x, 0.0f, 1.0f);
    minmax(y, 0.0f, 1.0f);

    decltype(_views.size())
        width_fits_completely_count = 0, height_fits_completely_count = 0;

    for (auto& view_clip : _views)
    {
        auto& view = view_clip.first;
        auto& clip = view_clip.second;

        if (_comic.page_image().empty())
        {
            view->clipChanged(ViewClip(0, 0, 1.0f));
            continue;
        }

        // calculate page image size in window
        auto size = view->size();
        auto image_width = _comic.page_image().width();
        auto image_height = _comic.page_image().height();

        auto clip_scale = scale *
                std::min(static_cast<float>(size.width) / image_width,
                         static_cast<float>(size.height) / image_height);

        image_width = static_cast<int>(image_width * clip_scale);
        image_height = static_cast<int>(image_height * clip_scale);

        // calculate the visible page image clip coordinates
        // with regard to the whole page image
        auto clip_x = 0, clip_y = 0;

        if (image_width > size.width)
            clip_x = static_cast<int>(x * (image_width - size.width));
        else
            ++width_fits_completely_count;

        if (image_height > size.height)
            clip_y = static_cast<int>(y * (image_height - size.height));
        else
            ++height_fits_completely_count;

        // update values
        if (!only_view || only_view == view)
        {
            if (page_changed || clip.scale != clip_scale ||
                    clip.x != clip_x || clip.y != clip_y)
                view->clipChanged(ViewClip(clip_x, clip_y, clip_scale));

            _scale = scale, clip.scale = clip_scale;
            _x = x, clip.x = clip_x;
            _y = y, clip.y = clip_y;
        }
    }

    if (width_fits_completely_count == _views.size())
        _x = 0.5f;
    if (height_fits_completely_count == _views.size())
        _y = 0.5f;
}

void Controller::perform(View* view, Action action, int move_dx, int move_dy)
{
    if (const auto clip = lookup(_views, view))
    {
        auto size = view->size();

        auto delta_x = action == Action::Move
            ? move_dx / (_comic.page_image().width() * clip->scale - size.width)
            : 50.0f * clip->scale / (_comic.page_image().width() * clip->scale - size.width);

        auto delta_y = action == Action::Move
            ? move_dy / (_comic.page_image().height() * clip->scale - size.height)
            : 50.0f * clip->scale / (_comic.page_image().height() * clip->scale - size.height);

        auto delta_scale = 1.1f;

        switch (action)
        {
        case Action::Resize:
            updateAlignment(_x, _y, _scale, false, view);
            break;
        case Action::Move:
            updateAlignment(_x + delta_x, _y + delta_y, _scale, false);
            break;
        case Action::Left:
            updateAlignment(_x - delta_x, _y, _scale, false);
            break;
        case Action::Right:
            updateAlignment(_x + delta_x, _y, _scale, false);
            break;
        case Action::Up:
            updateAlignment(_x, _y - delta_y, _scale, false);
            break;
        case Action::Down:
            updateAlignment(_x, _y + delta_y, _scale, false);
            break;
        case Action::In:
            updateAlignment(_x, _y, _scale * delta_scale, false);
            break;
        case Action::Out:
            updateAlignment(_x, _y, _scale / delta_scale, false);
            break;
        case Action::Next:
            _comic.page(_comic.page() + 1);
            updateAlignment(0.5f, 0.5f, 1.0f, true);
            break;
        case Action::Previous:
            _comic.page(_comic.page() - 1);
            updateAlignment(0.5f, 0.5f, 1.0f, true);
            break;
        }
    }
}
