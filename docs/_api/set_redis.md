---
title: /setRedisKeys
position: 1.09
type: get
description: Export data for project
---

canvas_id
: Canvas ID

Save all annotations associated with the canvas in Redis. `canvas_id` is the key.
Subsequent calls to `/getAnnotationsViaList` will return saved values from the Redis cache.

Then environment variable `USE_REDIS` must be set to `N` when this runs.
{: .warning }