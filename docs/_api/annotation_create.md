---
title: /annotations
position: 1.02
type: post
description: Create an annotation
---

###### Payload:

~~~ json
 {
  "layer_id": "<Layer ID>",
  "annotation": "<See Documentation/Annotation section>"
}
~~~

`annotation["@id"]` is not required because it will be created by the server and included in response.
{: .info }
