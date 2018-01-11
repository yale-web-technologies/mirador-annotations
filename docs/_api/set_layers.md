---
title: /setCurrentLayers
position: 1.10
type: post
description:
---

Sets layers for the group

###### Payload:

~~~ json
 {
  "group_id": "<Group ID>",
  "group_description": "<Description>",
  "layers": [
    { "layer_id": "<Layer ID>", "label": "<Label>" },
    ...
  ]
}
~~~

Currently called from the Ten Thousand Rooms portal, for example.
{: .info }
