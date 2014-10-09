/*
 * FLTK related API extensions
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
#include <functional>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <type_traits>
#include <cassert>

#ifndef FLTK_EX_H
#define FLTK_EX_H

#define FL_MEMBER_CALLBACK_FOR(object, member) \
    (FlEx::detail::MemberCallback< \
            decltype(&std::remove_pointer<decltype(object)>::type::member), \
                     &std::remove_pointer<decltype(object)>::type::member> \
     ::Callback::callback)

#define FL_MEMBER_CALLBACK(member) \
    FL_MEMBER_CALLBACK_FOR(this, member)

#define FL_CALLBACK_MEMBER_FOR(object, member) \
    FL_MEMBER_CALLBACK_FOR(object, member), (assert(object != nullptr), object)

#define FL_CALLBACK_MEMBER(member) \
    FL_MEMBER_CALLBACK_FOR(this, member), this

namespace FlEx
{
    class GuiRunner
    {
    public:
        GuiRunner();
        ~GuiRunner();
        void run(std::function<void()> task);
        void cancel();
        void wait();

    private:
        bool _running;
        std::mutex _mutex;
        std::function<void()> _task;
#ifndef NDEBUG
        std::thread::id _constructed_on_gui_thread_id;
#endif
        void callback();

    };

    namespace detail
    {
        template<class F, F f>
        struct MemberCallback
        {
            template<class>
            struct CallbackFunction;

            template<class C, class R>
            struct CallbackFunction<R(C::*)()>
            {
                static inline R callback(void* data)
                {
                    assert(data != nullptr);
                    return (static_cast<C*>(data)->*f)();
                }
            };

            template<class C, class R, class Arg>
            struct CallbackFunction<R(C::*)(Arg)>
            {
                static inline R callback(Arg arg, void* data)
                {
                    assert(data != nullptr);
                    return (static_cast<C*>(data)->*f)(arg);
                }
            };

            typedef CallbackFunction<F> Callback;
        };
    }
}

#endif // FLTK_EX_H
