/*
 * Execute a task on a background thread
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

#include <thread>
#include <mutex>
#include <atomic>
#include <condition_variable>
#include <functional>

#ifndef BACKGROUND_WORKER_H
#define BACKGROUND_WORKER_H

class BackgroundWorker
{
    bool _ready;
    bool _running;
    bool _stopped;
    std::atomic<bool> _canceled;
    std::function<void()> _task;
    std::mutex _process_mutex, _finished_mutex;
    std::condition_variable _process_cv, _finished_cv;
    std::thread _worker;

    inline void worker_running_changed(bool running);
    inline void worker();

public:
    BackgroundWorker();
    ~BackgroundWorker();

    void run(std::function<void()> task);
    void wait();
    void cancel() { _canceled = true; }
    bool canceled() const { return _canceled; }
};

#endif // BACKGROUND_WORKER_H
