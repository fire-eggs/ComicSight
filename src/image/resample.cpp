/*
 * Image resampling
 * using fixed-point arithmetic and pre-calculated Lanczos value approximation
 * to gain better runtime performance
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

#include <cmath>
#include <algorithm>
#include <cassert>
#include <util/concurrent.h>
#include "resample.h"

namespace
{
    typedef image::sample* __restrict sample_p_restrict;
    typedef const image::sample* __restrict sample_p_restrict_const;
    typedef uint_fast32_t default_int;

    const auto pi = 3.14159265f;

    template<typename T>
    inline int minmax(const T& value, const T& min, const T& max)
    {
        return value >= max ? max : value <= min ? min : value;
    }

    void inline sanitize(const Image& image, float& scale,
                         int& start_x, int& start_y, int& width, int& height)
    {
        if (start_x < 0)
            start_x = 0;
        if (start_y < 0)
            start_y = 0;
        if (scale < 0)
            scale = -scale;

        width = minmax(
            width, 0, std::max(0, static_cast<int>(scale * image.width()) - start_x));

        height = minmax(
            height, 0, std::max(0, static_cast<int>(scale * image.height()) - start_y));
    }

    inline float sinc(float x)
    {
       x *= pi;
       if (std::abs(x) < 0.01f)
          return 1.0f + x * x * (x * x * 1.0f/120.0f - 1.0f/6.0f);
       return sin(x) / x;
    }

    class LanczosValues
    {
        static const auto rounding = 8;
        static const auto size = (((0x03 << 16) | 0xFFFF) >> rounding) + 1;
        int32_t* values;

        static inline int32_t L(int32_t x)
        {
            auto v = static_cast<float>(x) / (1 << 16);
            return static_cast<int32_t>((1 << 16) * sinc(v) * sinc(v / 3.0f));
        }

        LanczosValues() : values(new int32_t[size])
        {
            for (auto i = 0; i < size; ++i)
                values[i] = L(i << rounding);
        }

        ~LanczosValues()
            { delete [] values; }

        LanczosValues(const LanczosValues&);
        LanczosValues& operator=(const LanczosValues&);

    public:
        static inline const LanczosValues& instance()
        {
            static LanczosValues L;
            return L;
        }

        inline int32_t operator()(int32_t x) const
            { return values[std::min(std::abs(x) >> rounding, size - 1)]; }
    };
}

Image image::resample_nearest_neighbor_fast(const Image& image, float scale,
                                            int start_x, int start_y,
                                            int width, int height)
{
    sanitize(image, scale, start_x, start_y, width, height);

    Image result(width, height, image.channels());

    sample_p_restrict_const in = image.data();
    sample_p_restrict out = result.data();

    const auto scale_factor_multiple =
            static_cast<default_int>((1 << 16) / scale);
    const auto src_x0_start_multiple =
            static_cast<default_int>(start_x * scale_factor_multiple);

    concurrent::parallel_for(0, height, [&](int y)
    {
        auto src_y0_multiple = (start_y + y) * scale_factor_multiple;

        auto src_y0 = src_y0_multiple >> 16;
        for (int x = 0, src_x0_multiple = src_x0_start_multiple;
             x < width;
             ++x, src_x0_multiple += scale_factor_multiple)
        {
            auto src_x0 = src_x0_multiple >> 16;
            auto off_in = (src_x0 + src_y0 * image.width()) * image.channels();
            auto off_out = (x + y * width) * image.channels();

            for (auto c = 0; c < image.channels(); ++c)
            {
                assert(off_in + c >= static_cast<decltype(off_in + c)>(0));
                assert(off_in + c < static_cast<decltype(off_in + c)>(image.size()));
                assert(off_out + c >= static_cast<decltype(off_out + c)>(0));
                assert(off_out + c < static_cast<decltype(off_out + c)>(result.size()));

                out[off_out + c] = in[off_in + c];
             }
        }
    });

    return result;
}

Image image::resample_nearest_neighbor(const Image& image, float scale,
                                       int start_x, int start_y,
                                       int width, int height)
{
    sanitize(image, scale, start_x, start_y, width, height);

    Image result(width, height, image.channels());

    sample_p_restrict_const in = image.data();
    sample_p_restrict out = result.data();

    const auto scale_factor_multiple =
            static_cast<default_int>((1 << 16) / scale);
    const auto src_x0_start_multiple =
            static_cast<default_int>(start_x * scale_factor_multiple);
    const auto line_size = image.width() * image.channels();

    concurrent::parallel_for(0, height, [&](int y)
    {
        auto src_y0_multiple = (start_y + y) * scale_factor_multiple;

        auto src_y0 = src_y0_multiple >> 16;
        auto src_y0_next = std::min<default_int>(
                    (src_y0_multiple + scale_factor_multiple) >> 16,
                    image.height() - 1);

        if (scale > 1)
            src_y0_next = src_y0;

        for (int x = 0, src_x0_multiple = src_x0_start_multiple;
             x < width;
             ++x, src_x0_multiple += scale_factor_multiple)
        {
            auto src_x0 = src_x0_multiple >> 16;
            auto src_x0_next = std::min<default_int>(
                        (src_x0_multiple + scale_factor_multiple) >> 16,
                        image.width() - 1);

            if (scale > 1)
                src_x0_next = src_x0;

            auto off_in = (src_x0 + src_y0 * image.width()) * image.channels();
            auto off_out = (x + y * width) * image.channels();

            for (auto c = 0; c < image.channels(); ++c)
            {
                auto v = 0, vc = 0;
                for (default_int off_y = 0, i = src_y0;
                     i <= src_y0_next;
                     off_y += line_size, ++i)
                    for (default_int off_x = 0, i = src_x0;
                         i <= src_x0_next;
                         off_x += image.channels(), ++i)
                    {
                        assert(off_in + off_x + off_y + c >=
                               static_cast<decltype(off_in + off_x + off_y + c)>(0));
                        assert(off_in + off_x + off_y + c <
                               static_cast<decltype(off_in + off_x + off_y + c)>(image.size()));

                        v += in[off_in + off_x + off_y + c], ++vc;
                    }

                assert(vc > 0);
                assert(off_out + c >= static_cast<decltype(off_out + c)>(0));
                assert(off_out + c < static_cast<decltype(off_out + c)>(result.size()));
                out[off_out + c] = static_cast<image::sample>(v / vc);
            }
        }
    });

    return result;
}

Image image::resample_bilinear_fast(const Image& image, float scale,
                                    int start_x, int start_y,
                                    int width, int height)
{
    sanitize(image, scale, start_x, start_y, width, height);

    Image result(width, height, image.channels());

    sample_p_restrict_const in = image.data();
    sample_p_restrict out = result.data();

    const auto scale_factor_multiple =
            static_cast<default_int>((1 << 16) / scale);
    const auto src_x0_start_multiple =
            static_cast<default_int>(start_x * scale_factor_multiple);

    concurrent::parallel_for(0, height, [&](int y)
    {
        auto src_y0_multiple = (start_y + y) * scale_factor_multiple;

        auto src_y0 = std::min<default_int>(
                    src_y0_multiple >> 16, image.height() - 1);
        auto src_y1 = std::min<default_int>(
                    src_y0 + 1, image.height() - 1);
        auto dy = src_y0_multiple - (src_y0 << 16);

        for (default_int x = 0, src_x0_multiple = src_x0_start_multiple;
             x < static_cast<default_int>(width);
             ++x, src_x0_multiple += scale_factor_multiple)
        {
            auto src_x0 =
                std::min<default_int>(src_x0_multiple >> 16, image.width() - 1);
            auto src_x1 =
                std::min<default_int>(src_x0 + 1, image.width() - 1);
            auto dx = src_x0_multiple - (src_x0 << 16);

            auto off_in0 = (src_x0 + src_y0 * image.width()) * image.channels(),
                 off_in1 = (src_x1 + src_y0 * image.width()) * image.channels(),
                 off_in2 = (src_x0 + src_y1 * image.width()) * image.channels(),
                 off_in3 = (src_x1 + src_y1 * image.width()) * image.channels(),
                 off_out = (x + y * width) * image.channels();

            for (auto c = 0; c < image.channels(); ++c)
            {
                assert(off_in0 + c >= static_cast<decltype(off_in0 + c)>(0));
                assert(off_in0 + c < static_cast<decltype(off_in0 + c)>(image.size()));
                assert(off_in1 + c >= static_cast<decltype(off_in1 + c)>(0));
                assert(off_in1 + c < static_cast<decltype(off_in1 + c)>(image.size()));
                assert(off_in2 + c >= static_cast<decltype(off_in2 + c)>(0));
                assert(off_in2 + c < static_cast<decltype(off_in2 + c)>(image.size()));
                assert(off_in3 + c >= static_cast<decltype(off_in3 + c)>(0));
                assert(off_in3 + c < static_cast<decltype(off_in3 + c)>(image.size()));
                assert(off_out + c >= static_cast<decltype(off_out + c)>(0));
                assert(off_out + c < static_cast<decltype(off_out + c)>(result.size()));

                auto v0 = in[off_in0 + c],
                     v1 = in[off_in1 + c],
                     v2 = in[off_in2 + c],
                     v3 = in[off_in3 + c];

                // interpolate in y direction
                auto i1 = ((v0 << 16) + (v2 - v0) * dy) >> 16;
                auto i2 = ((v1 << 16) + (v3 - v1) * dy) >> 16;

                // interpolate in x direction and set output
                out[off_out + c] =
                    static_cast<image::sample>(((i1 << 16) + (i2 - i1) * dx) >> 16);
            }
        }
    });

    return result;
}

Image image::resample_bilinear(const Image& image, float scale,
                               int start_x, int start_y,
                               int width, int height,
                               std::function<bool()> canceled)
{
    sanitize(image, scale, start_x, start_y, width, height);

    const auto scale_factor_multiple =
            static_cast<default_int>((1 << 16) / scale);

    const auto src_x0_start_multiple =
            static_cast<default_int>(start_x * scale_factor_multiple);
    const auto src_y0_start_multiple =
            static_cast<default_int>(start_y * scale_factor_multiple);

    const auto src_x_start = src_x0_start_multiple >> 16;
    const auto src_x_end = src_x_start + ((width * scale_factor_multiple) >> 16) + 1;

    const auto line_size = image.width() * image.channels();

    Image result(width, height, image.channels());
    Image intermediate(src_x_end - src_x_start, height, image.channels());

    sample_p_restrict_const in = image.data();
    sample_p_restrict out = intermediate.data();

    // interpolate in y direction
    concurrent::parallel_for(src_x_start, src_x_end, [&](default_int x)
    {
        if(!canceled())
            for (default_int y = 0, src_y0_multiple = src_y0_start_multiple;
                 y < static_cast<default_int>(height);
                 ++y, src_y0_multiple += scale_factor_multiple)
                if(!canceled())
                {
                    auto src_y0 = std::min<default_int>(
                            src_y0_multiple >> 16,
                            image.height() - 1);
                    auto src_y1 = std::min<default_int>(
                            src_y0 + 1,
                            image.height() - 1);
                    auto src_y0_next = std::min<default_int>(
                            (src_y0_multiple + scale_factor_multiple) >> 16,
                            image.height() - 1);
                    auto src_y1_next = std::min<default_int>(
                            (src_y0_multiple + (1 << 16) + scale_factor_multiple) >> 16,
                            image.height() - 1);
                    auto dy = src_y0_multiple - (src_y0 << 16);

                    if (scale > 1)
                        src_y0_next = src_y0, src_y1_next = src_y1;

                    auto off_in0 = (x + src_y0 * image.width()) * image.channels();
                    auto off_in1 = (x + src_y1 * image.width()) * image.channels();
                    auto off_out = ((x - src_x_start) + y * intermediate.width()) * image.channels();

                    for (auto c = 0; c < image.channels(); ++c)
                    {
                        auto v0 = 0, v1 = 0;
                        for (default_int off = off_in0 + c, i = src_y0;
                             i <= src_y0_next;
                             off += line_size, ++i)
                        {
                            assert(off >= static_cast<decltype(off)>(0));
                            assert(off < static_cast<decltype(off)>(image.size()));
                            v0 += in[off];
                        }
                        for (default_int off = off_in1 + c, i = src_y1;
                             i <= src_y1_next;
                             off += line_size, ++i)
                        {
                            assert(off >= static_cast<decltype(off)>(0));
                            assert(off < static_cast<decltype(off)>(image.size()));
                            v1 += in[off];
                        }
                        v0 /= src_y0_next - src_y0 + 1, v1 /= src_y1_next - src_y1 + 1;

                        assert(off_out + c >= static_cast<decltype(off_out + c)>(0));
                        assert(off_out + c < static_cast<decltype(off_out + c)>(intermediate.size()));
                        out[off_out + c] =
                            static_cast<image::sample>(((v0 << 16) + (v1 - v0) * dy) >> 16);
                    }
                }
    });

    in = intermediate.data(), out = result.data();

    // interpolate in x direction
    concurrent::parallel_for(0, intermediate.height(), [&](int y)
    {
        if(!canceled())
            for (default_int x = 0, src_x0_multiple = src_x_start << 16;
                 x < static_cast<default_int>(width);
                 ++x, src_x0_multiple += scale_factor_multiple)
                if(!canceled())
                {
                    auto src_x0 = std::min<default_int>(
                             src_x0_multiple >> 16,
                             src_x_end - 1);
                    auto src_x1 = std::min<default_int>(
                            src_x0 + 1,
                            src_x_end - 1);
                    auto src_x0_next = std::min<default_int>(
                            (src_x0_multiple + scale_factor_multiple) >> 16,
                            src_x_end - 1);
                    auto src_x1_next = std::min<default_int>(
                            (src_x0_multiple + (1 << 16) + scale_factor_multiple) >> 16,
                            src_x_end - 1);
                    auto dx = src_x0_multiple - (src_x0 << 16);

                    if (scale > 1)
                        src_x0_next = src_x0, src_x1_next = src_x1;

                    auto off_in0 = ((src_x0 - src_x_start) + y * intermediate.width()) * image.channels();
                    auto off_in1 = ((src_x1 - src_x_start) + y * intermediate.width()) * image.channels();
                    auto off_out = (x + y * width) * image.channels();

                    for (auto c = 0; c < image.channels(); ++c)
                    {
                        auto v0 = 0, v1 = 0;
                        for (default_int off = off_in0 + c, p = src_x0;
                             p <= src_x0_next;
                             off += image.channels(), ++p)
                        {
                            assert(off >= static_cast<decltype(off)>(0));
                            assert(off < static_cast<decltype(off)>(intermediate.size()));
                            v0 += in[off];
                        }
                        for (default_int off = off_in1 + c, p = src_x1;
                             p <= src_x1_next;
                             off += image.channels(), ++p)
                        {
                            assert(off >= static_cast<decltype(off)>(0));
                            assert(off < static_cast<decltype(off)>(intermediate.size()));
                            v1 += in[off];
                        }
                        v0 /= src_x0_next - src_x0 + 1, v1 /= src_x1_next - src_x1 + 1;

                        assert(off_out + c >= static_cast<decltype(off_out + c)>(0));
                        assert(off_out + c < static_cast<decltype(off_out + c)>(result.size()));
                        out[off_out + c] =
                            static_cast<image::sample>(((v0 << 16) + (v1 - v0) * dx) >> 16);
                    }
                }
    });

    return result;
}

Image image::resample_lanczos(const Image& image, float scale,
                              int start_x, int start_y,
                              int width, int height,
                              std::function<bool()> canceled)
{
    sanitize(image, scale, start_x, start_y, width, height);

    auto& L = LanczosValues::instance();

    const auto scale_factor_multiple =
            static_cast<default_int>((1 << 16) / scale);

    const auto src_x0_start_multiple =
            static_cast<default_int>(start_x * scale_factor_multiple);
    const auto src_y0_start_multiple =
            static_cast<default_int>(start_y * scale_factor_multiple);

    const auto src_x_start = src_x0_start_multiple >> 16;
    const auto src_x_end = src_x_start + ((width * scale_factor_multiple) >> 16) + 1;
    const auto src_x_padded_end = std::min<default_int>(src_x_end + 3, image.width());

    Image result(width, height, image.channels());
    Image intermediate(src_x_padded_end > src_x_start ? src_x_padded_end - src_x_start : 0,
                       height, image.channels());

    sample_p_restrict_const in = image.data();
    sample_p_restrict out = intermediate.data();

    concurrent::parallel_for(src_x_start, src_x_padded_end, [&](default_int x)
    {
        if(!canceled())
            for (default_int y = 0, src_y0_multiple = src_y0_start_multiple;
                 y < static_cast<default_int>(height);
                 ++y, src_y0_multiple += scale_factor_multiple)
                if(!canceled())
                {
                    auto src_y0 = std::min<default_int>(
                                src_y0_multiple >> 16,
                                image.height() - 1);
                    auto src_y0_next = std::min<default_int>(
                                (src_y0_multiple + scale_factor_multiple) >> 16,
                                image.height() - 1);
                    auto off_out =
                        ((x - src_x_start) + y * intermediate.width()) * image.channels();

                    if (scale > 1)
                        src_y0_next = src_y0;

                    for (auto c = 0; c < image.channels(); ++c)
                    {
                        auto s = 0;
                        for (auto i = -2; i <= 3; ++i)
                        {
                            auto v = 0;
                            for (auto p = src_y0; p <= src_y0_next; ++p)
                            {
                                auto off_in =
                                    (x + minmax<int>(p + i, 0, image.height() - 1)
                                        * image.width()) * image.channels();

                                assert(off_in + c >= static_cast<decltype(off_in + c)>(0));
                                assert(off_in + c < static_cast<decltype(off_in + c)>(image.size()));
                                v += in[off_in + c];
                            }
                            v /= src_y0_next - src_y0 + 1;

                            s += v * L(src_y0_multiple - ((src_y0 + i) << 16));
                        }

                        assert(off_out + c >= static_cast<decltype(off_out + c)>(0));
                        assert(off_out + c < static_cast<decltype(off_out + c)>(intermediate.size()));
                        out[off_out + c] = static_cast<image::sample>(minmax<int>(s >> 16, 0, 255));
                    }
                }
    });

    in = intermediate.data(), out = result.data();

    concurrent::parallel_for(0, intermediate.height(), [&](int y)
    {
        if(!canceled())
            for (default_int x = 0, src_x0_multiple = src_x_start << 16;
                 x < static_cast<default_int>(width);
                 ++x, src_x0_multiple += scale_factor_multiple)
                if(!canceled())
                {
                    auto src_x0 = std::min<default_int>(
                                src_x0_multiple >> 16,
                                src_x_padded_end - 1);
                    auto src_x0_next = std::min<default_int>(
                                (src_x0_multiple + scale_factor_multiple) >> 16,
                                src_x_padded_end - 1);
                    auto off_out = (x + y * width) * image.channels();

                    if (scale > 1)
                        src_x0_next = src_x0;

                    for (auto c = 0; c < image.channels(); ++c)
                    {
                        auto s = 0;
                        for (auto i = -2; i <= 3; ++i)
                        {
                            auto v = 0;
                            for (auto p = src_x0; p <= src_x0_next; ++p)
                            {
                                auto off_in =
                                    (minmax<int>(p + i - src_x_start, 0, intermediate.width() - 1)
                                        + y * intermediate.width()) * image.channels();

                                assert(off_in + c >= static_cast<decltype(off_in + c)>(0));
                                assert(off_in + c < static_cast<decltype(off_in + c)>(intermediate.size()));
                                v += in[off_in + c];
                            }
                            v /= src_x0_next - src_x0 + 1;

                            s += v * L(src_x0_multiple - ((src_x0 + i) << 16));
                        }

                        assert(off_out + c >= static_cast<decltype(off_out + c)>(0));
                        assert(off_out + c < static_cast<decltype(off_out + c)>(result.size()));
                        out[off_out + c] = static_cast<image::sample>(minmax<int>(s >> 16, 0, 255));
                    }
                }
    });

    return result;
}
