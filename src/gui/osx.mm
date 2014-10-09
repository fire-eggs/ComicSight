/*
 * OS X integration
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

#ifdef __APPLE__
# include <FL/x.H>
# import <Cocoa/Cocoa.h>
#endif
#include "osx.h"

#ifdef __APPLE__
namespace
{
    void mac_about_callback(Fl_Widget* widget, void* data)
    {
        (void) widget;
        [NSApp orderFrontStandardAboutPanelWithOptions:(NSMutableDictionary*)data];
    }
}
#endif

void osx::set_about_dialog(const char* credits, const char* application_name,
                           const char* version, const char* copyright,
                           const char* application_version)
{
#ifdef __APPLE__
    NSMutableDictionary* options = [[[NSMutableDictionary alloc] init] autorelease];

    if (credits)
        [options setValue:[[[NSAttributedString alloc]
                     initWithString:[NSString stringWithUTF8String:credits]] autorelease]
                 forKey:@"Credits"];

    if (application_name)
        [options setValue:[NSString stringWithUTF8String:application_name]
                 forKey:@"ApplicationName"];

    if (version)
        [options setValue:[NSString stringWithUTF8String:version]
                 forKey:@"Version"];

    if (copyright)
        [options setValue:[NSString stringWithUTF8String:copyright]
                 forKey:@"Copyright"];

    if (application_version)
        [options setValue:[NSString stringWithUTF8String:application_version]
                 forKey:@"ApplicationVersion"];

    fl_mac_set_about(mac_about_callback, options);
#endif
}
