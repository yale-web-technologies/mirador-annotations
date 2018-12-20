---
title: /export/check_status
position: 1.9
type: get
description: Called by client-side JavaScript in intervals to update the status of the export job -- whether it is in progress or complete.
---

job_id
: ID of the Delayed::Job job

Used by the export page to check the progress of the offline export task.
It should initiate download when the status indicates the job is complete.
{: .info }
