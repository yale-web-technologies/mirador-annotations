---
title: /resequenceList
position: 1.7
type: put
description: Re-order annotations in a list
---

###### Payload:

~~~ json
 {
  "canvas_id": "<Canvas ID>",
  "layer_id": "<Layer ID>",
  "annotation_ids": [ "<AnnotationID>", ... ]
}
~~~

`canvas_id` and `layer_id` together determines the list the user wants to change.
{: .info}

`annotation_ids` is a list of annotation IDs that are arranged in the new updated order.
{: .info}
