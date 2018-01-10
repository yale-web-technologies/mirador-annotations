---
title: /getAnnotationsViaList
position: 1.1
type: get
description: Get annotations on the canvas
---

canvas_id
: ID of canvas<br/>
e.g. `http://example.org/iiif/canvas/1`<br/>
(required)

Returns all annotations (along with the IDs of the layers to which they belong)
that are associated with the canvas transitively,
i.e., recursively including annotations that target those annotations, thus indirectly targeting the canvas.

~~~ json
[
  {
    "layer_id" : "<Layer ID>",
    "annotation": "<See Documentation/Annotation section>"
  },
  ...
]
~~~
{: title="Response" }

~~~ javascript
jQuery.ajax({
  url: "https://mirador-annotations-lotb-stg.herokuapp.com/getAnnotationsViaList?canvas_id=http%3A%2F%2Fmanifests.ydc2.yale.edu%2FLOTB%2Fcanvas%2Fpanel_01",
  type: 'GET',
  dataType: 'json',
  contentType: 'application/json; charset=utf-8',
  success: (data, textStatus, jqXHR) => {
    console.log('Success', data);
  },
  error: (jqXHR, textStatus, errorThrown) => {
    console.log('Error', jqXHR);
  }
});
~~~
{: title="jQuery example" }
