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

#include "backgroundworker.h"

inline void BackgroundWorker::worker_running_changed(bool running)
{
    {
        std::lock_guard<std::mutex> lock(_finished_mutex);
        _running = running;
    }
    _finished_cv.notify_all();
}

inline void BackgroundWorker::worker()
{
    std::function<void()> task;
    while (true)
    {
        {
            std::unique_lock<std::mutex> lock(_process_mutex);
            if (!_ready && !_stopped)
            {
                worker_running_changed(false);
                _process_cv.wait(lock, [this] { return _ready || _stopped; });
            }
            if (_stopped)
                return;

            _ready = false;
            _canceled = false;
            worker_running_changed(true);
            task = std::move(_task);
        }

        task();
    }
}

BackgroundWorker::BackgroundWorker()
    : _ready(false), _running(false), _stopped(false), _canceled(false),
      _worker(&BackgroundWorker::worker, this) { }

BackgroundWorker::~BackgroundWorker()
{
    {
        std::lock_guard<std::mutex> lock(_process_mutex);
        _canceled = true;
        _stopped = true;
    }
    _process_cv.notify_one();
    _worker.join();
}

void BackgroundWorker::run(std::function<void()> task)
{
    {
        std::lock_guard<std::mutex> lock(_process_mutex);
        _ready = true;
        _canceled = true;
        _task = std::move(task);
    }
    _process_cv.notify_one();
}

void BackgroundWorker::wait()
{
    std::unique_lock<std::mutex> lock(_finished_mutex);
    if (_running)
        _finished_cv.wait(lock, [this] { return !_running; });
}
