---
title: /export/check_status
position: 1.08
type: get
description: Get current status of offline export job
---

job_id
: ID of the Delayed::Job job

Used by the export page to check the progress of the offline export task.
It should initiate download when the status indicates the job is complete.
{: .info }