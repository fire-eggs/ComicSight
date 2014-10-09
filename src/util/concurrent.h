/*
 * Support for concurrent operations
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

#include <future>
#include <thread>
#include <vector>

#ifdef _MSC_VER
# include <ppl.h>
#endif

#ifndef CONCURRENT_H
#define CONCURRENT_H

namespace concurrent
{
    template<class RandomAccessIterator, class Body>
    void parallel_for(RandomAccessIterator start,
                      RandomAccessIterator end,
                      Body body)
    {
        if (start >= end)
            return;

#ifdef _MSC_VER

        concurrency::parallel_for(start, end, body);

#else // _MSC_VER

        typedef std::future<decltype(body(start))> body_future;
        const auto size = end - start;
        const static auto count = std::thread::hardware_concurrency();

        if (count > 1)
        {
            const auto part_size = size / count;
            RandomAccessIterator part_start = start, part_end = start + part_size;

            std::vector<body_future> futures;
            futures.reserve(count - 1);

            for (auto i = 0u;
                 i < count - 1;
                 ++i, part_start += part_size, part_end += part_size)
                futures.push_back(
                    std::async(std::launch::async, [part_start, part_end, &body]
                    {
                        for (RandomAccessIterator i = part_start; i < part_end; ++i)
                            body(i);
                    }));

            for (RandomAccessIterator i = part_start; i < end; ++i)
                body(i);

            for (body_future& future : futures)
                future.wait();
        }
        else
            for (RandomAccessIterator i = start; i < end; ++i)
                body(i);

#endif // _MSC_VER
    }
}

#endif // CONCURRENT_H
