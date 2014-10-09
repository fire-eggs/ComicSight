/*
 * Color type conversion
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

#include "colortype.h"

namespace
{
    typedef image::sample* __restrict sample_p_restrict;
    typedef const image::sample* __restrict sample_p_restrict_const;

    inline void grayscale(sample_p_restrict_const in,
                          sample_p_restrict out,
                          const int size,
                          bool alpha_channel,
                          bool reduce_channels)
    {
        if (alpha_channel)
        {
            if (reduce_channels)
                for (auto i = 0, o = 0; i < size; i += 4, o += 2)
                    out[o] = (306 * in[i] + 601 * in[i + 1] + 117 * in[i + 2]) / 1024,
                    out[o + 1] = in[i + 3];
            else
                for (auto i = 0; i < size; i += 4)
                    out[i] = out[i + 1] = out[i + 2] =
                            (306 * in[i] + 601 * in[i + 1] + 117 * in[i + 2]) / 1024,
                    out[i + 3] = in[i + 3];
        }
        else
        {
            if (reduce_channels)
                for (auto i = 0, o = 0; i < size; i += 3, o++)
                    out[o] = (306 * in[i] + 601 * in[i + 1] + 117 * in[i + 2]) / 1024;
            else
                for (auto i = 0; i < size; i += 3)
                    out[i] = out[i + 1] = out[i + 2] =
                            (306 * in[i] + 601 * in[i + 1] + 117 * in[i + 2]) / 1024;
        }
    }
}

Image image::grayscale(const Image& image, bool reduce_channels)
{
    auto result = image.channels() == 1 || image.channels() == 2 ? image : Image();

    if (image.channels() == 3 || image.channels() == 4)
    {
        if (reduce_channels)
            result.reset(image.width(), image.width(), image.channels() == 3 ? 1 : 2);
        else
            result.reset(image.width(), image.width(), image.channels());
        ::grayscale(image.data(), result.data(), image.size(),
                    image.channels() == 4, reduce_channels);
    }

    return result;
}

void image::grayscale_inplace(Image& image, bool reduce_channels)
{
    if (image.channels() != 3 && image.channels() != 4)
        return;

    ::grayscale(image.data(), image.data(), image.size(),
                image.channels() == 4, reduce_channels);
    if (reduce_channels)
        image.reset(image.width(), image.height(), image.channels() == 3 ? 1 : 2);
}

Image image::ensure_rgb(const Image& image)
{
    auto result = image.channels() == 3 || image.channels() == 4 ? image : Image();

    if (image.channels() == 1 || image.channels() == 2)
    {
        result.reset(image.width(), image.height(), image.channels() == 1 ? 3 : 4);
        sample_p_restrict out = result.data();
        auto size = result.size();
        sample_p_restrict_const in = image.data();

        if (image.channels() == 1)
            for (int i = 0, o = 0; o < size; i++, o += 3)
                out[o] = out[o + 1] = out[o + 2] = in[i];
        else
            for (int i = 0, o = 0; o < size; i += 2, o += 4)
                out[o] = out[o + 1] = out[o + 2] = in[i],
                out[o + 3] = in[i + 1];
    }

    return result;
}

void image::ensure_rgb_inplace(Image& image)
{
    if (image.channels() != 1 && image.channels() != 2)
        return;
    image = std::move(ensure_rgb(image));
}

Image image::drop_alpha(const Image& image)
{
    auto result = image.channels() == 1 || image.channels() == 3 ? image : Image();

    if (image.channels() == 2 || image.channels() == 4)
    {
        result.reset(image.width(), image.height(), image.channels() == 4 ? 3 : 1);
        auto out = result.data();
        const auto size = result.size();
        const auto in = image.data();

        if (image.channels() == 2)
            for (int i = 0, o = 0; o < size; i += 2, o++)
                out[o] = in[i];
        else
            for (int i = 0, o = 0; o < size; i += 4, o += 3)
                out[o] = in[i], out[o + 1] = in[i + 1], out[o + 2] = in[i + 2];
    }

    return result;
}

void image::drop_alpha_inplace(Image& image)
{
    if (image.channels() != 2 && image.channels() != 4)
        return;

    int size = image.width() * image.height();
    if (image.channels() == 4)
        size *= 3;
    sample_p_restrict data = image.data();

    if (image.channels() == 2)
        for (int i = 0, o = 0; o < size; i += 2, o++)
            data[o] = data[i];
    else
        for (int i = 0, o = 0; o < size; i += 4, o += 3)
            data[o] = data[i], data[o + 1] = data[i + 1], data[o + 2] = data[i + 2];

    image.reset(image.width(), image.height(), image.channels() == 4 ? 3 : 1);
}

Image image::ensure_alpha(const Image& image, image::sample default_alpha)
{
    auto result = image.channels() == 2 || image.channels() == 4 ? image : Image();

    if (image.channels() == 1 || image.channels() == 3)
    {
        result.reset(image.width(), image.height(), image.channels() == 1 ? 2 : 4);
        sample_p_restrict out = result.data();
        auto size = result.size();
        sample_p_restrict_const in = image.data();

        if (image.channels() == 1)
            for (int i = 0, o = 0; o < size; i++, o += 2)
                out[o] = in[i], out[o + 1] = default_alpha;
        else
            for (int i = 0, o = 0; o < size; i += 3, o += 4)
                out[o] = in[i], out[o + 1] = in[i + 1], out[o + 2] = in[i + 2],
                out[o + 3] = default_alpha;
    }

    return result;
}

void image::ensure_alpha_inplace(Image& image, image::sample default_alpha)
{
    if (image.channels() != 1 && image.channels() != 3)
        return;
    image = std::move(ensure_alpha(image, default_alpha));
}
