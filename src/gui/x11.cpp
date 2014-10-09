/*
 * X11 integration
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
# ifdef HAVE_X11XPM
#  include <X11/xpm.h>
# endif
# include <FL/x.H>
# include <streambuf>
# include <memory>
# include <unistd.h>
# include <string.h>
# include <image/image.h>
# include <image/colortype.h>
#endif
#include "x11.h"

#ifdef HAVE_X11
namespace
{
    class arraybuf : public std::streambuf
    {
    public:
        arraybuf(const char* begin, const char* end)
        {
            // we do not provide methods to modify the buffer
            // so it is actually constant
            setg(const_cast<char*>(begin), const_cast<char*>(begin),
                 const_cast<char*>(end));
        }

        int_type underflow()
        {
            return gptr() == egptr()
                    ? traits_type::eof()
                    : traits_type::to_int_type(*gptr());
        }

        std::streampos seekoff(std::streamoff off, std::ios_base::seekdir way,
                               std::ios_base::openmode which)
        {
            if (which == std::ios_base::in)
            {
                setg(eback(),
                     way == std::ios_base::beg ? eback() + off :
                     way == std::ios_base::end ? egptr() + off : gptr() + off,
                     egptr());
                return gptr() - eback();
            }
            return -1;
        }

        std::streampos seekpos(std::streampos sp, std::ios_base::openmode which)
        {
            if (which == std::ios_base::in)
            {
                setg(eback(), eback() + sp, egptr());
                return gptr() - eback();
            }
            return -1;
        }
    };
}
#endif // HAVE_X11

void x11::set_window_machine_name(const Fl_Window* window)
{
#ifdef HAVE_X11
    char hostname[512];
    gethostname(hostname, sizeof(hostname));
    XChangeProperty(fl_display, fl_xid(window),
                    XInternAtom(fl_display, "WM_CLIENT_MACHINE", 0),
                    XA_STRING, 8, PropModeReplace,
                    reinterpret_cast<unsigned char*>(hostname),
                    strnlen(hostname, sizeof(hostname)));
#endif
}

void x11::set_window_pid(const Fl_Window* window)
{
#ifdef HAVE_X11
    auto pid = getpid();
    XChangeProperty(fl_display, fl_xid(window),
                    XInternAtom(fl_display, "_NET_WM_PID", 0),
                    XA_CARDINAL, 32, PropModeReplace,
                    reinterpret_cast<unsigned char*>(&pid),
                    1);
#endif
}

void x11::set_window_wm_icon(const Fl_Window* window,
                             const unsigned char* image_data, int image_size)
{
#ifdef HAVE_X11
    arraybuf buf(reinterpret_cast<const char*>(image_data),
                 reinterpret_cast<const char*>(image_data) + image_size);
    std::istream stream(&buf);

    Image image;
    image.load(stream);

    image::ensure_rgb_inplace(image);
    image::ensure_alpha_inplace(image);

    auto data = std::unique_ptr<unsigned long[]>(
                new unsigned long[image.width() * image.height() + 2]);
    data[0] = image.width();
    data[1] = image.height();
    for (auto y = 0; y < image.height(); ++y)
        for (auto x = 0; x < image.width(); ++x)
        {
            auto& pixel = data[y * image.width() + x + 2];
            pixel = 0;
            for (auto c = 0; c < 4; ++c)
                pixel |= static_cast<unsigned long>(
                             image[(y * image.width() + x) * image.channels() + c])
                         << (8 * c);
        }

    XChangeProperty(fl_display, fl_xid(window),
                    XInternAtom(fl_display, "_NET_WM_ICON", 0),
                    XA_CARDINAL, 32, PropModeReplace,
                    reinterpret_cast<unsigned char*>(data.get()),
                    image.width() * image.height() + 2);
#endif
}

void x11::set_window_hint_icon(const Fl_Window* window, const char** pixmap_data)
{
#if defined(HAVE_X11) && defined(HAVE_X11XPM)
    auto hints = XAllocWMHints();
    hints->flags = IconPixmapHint | IconMaskHint;

    XpmCreatePixmapFromData(fl_display, DefaultRootWindow(fl_display),
                            const_cast<char**>(pixmap_data),
                            &hints->icon_pixmap, &hints->icon_mask, nullptr);

    XSetWMHints(fl_display, fl_xid(window), hints);
    XFree(hints);
#endif
}
