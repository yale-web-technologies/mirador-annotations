---
title: /layers
position: 1.05
type: get
description: Get annotation layers
---

group_id
: Group ID of current user. <br/>
When specified, returns list of layers that are defined for the group (or project).<br/>
(optional - currently used for Ten Thousand Rooms only.)

~~~ json
[
  {
    "@context": "http://iiif.io/api/presentation/2/context.json",
    "@id": "http://manifest.tenthousandrooms.yale.edu/layers/16",
    "@type": "sc:Layer",
    "label": "Transcription"
  },
  ...
]
~~~
{: title="Response"}

~~~ javascript
~~~
{: title="jQuery example" }
