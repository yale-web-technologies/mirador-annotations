---
title: Annotation
position: 4
---

Annotations returned by the API either by themselves or embedded in a parent object,
should be in the following format.

The annotation server tries to keep output format close to the format of Mirador-created annotations. In the examples below,
the "Canonical" tab shows the format from the current version of Mirador. The "old" format is still supported as of Mirador v2.6.

The main difference is the "on" field. In the new format, "on" is an array, and the selector is of type "oa:Choice" and contains both rectagular boundary and the SVG shape. The old format has "on" as a single object and selector doesn't contain the rectangular boundary.

~~~ json
{
  "@id": "http://annotations.ten-thousand-rooms.yale.edu/annotations/e8a459bb-119c-4f46-87a3-93edc2cd22c1",
  "@type": "oa:Annotation",
  "@context": "http://iiif.io/api/presentation/2/context.json",
  "resource": [
    {
      "@type": "dctypes:Text",
      "format": "text/html",
      "chars": "<p>Test #1</p>"
    },
    {
      "@type": "oa:Tag",
      "chars": "mytag"
    }
  ],
  "within": [
    "http://annotations.ten-thousand-rooms.yale.edu/lists/http://manifest.tenthousandrooms.yale.edu/layers/16_http://manifest.tenthousandrooms.yale.edu/node/311/canvas/14116"
  ],
  "motivation": [
    "oa:commenting"
  ],
  "on": [
    {
      "@type": "oa:SpecificResource",
      "full": "http://manifest.tenthousandrooms.yale.edu/node/311/canvas/14116",
      "selector": {
        "@type": "oa:Choice",
        "default": {
          "@type": "oa:FragmentSelector",
          "value": "xywh=54,248,179,219"
        },
        "item": {
          "@type": "oa:SvgSelector",
          "value": "<svg xmlns='http://www.w3.org/2000/svg'><path xmlns=\"http://www.w3.org/2000/svg\" d=\"M53.93942,248.15395h89.65346v0h89.65346v109.58331v109.58331h-89.65346h-89.65346v-109.58331z\" data-paper-data=\"{&quot;strokeWidth&quot;:1,&quot;rotation&quot;:0,&quot;deleteIcon&quot;:null,&quot;rotationIcon&quot;:null,&quot;group&quot;:null,&quot;editable&quot;:true,&quot;annotation&quot;:null}\" id=\"rectangle_f95e7e02-7a2b-495e-8dc4-d47f1c0fba9d\" fill-opacity=\"0\" fill=\"#00bfff\" fill-rule=\"nonzero\" stroke=\"#00bfff\" stroke-width=\"1\" stroke-linecap=\"butt\" stroke-linejoin=\"miter\" stroke-miterlimit=\"10\" stroke-dasharray=\"\" stroke-dashoffset=\"0\" font-family=\"none\" font-weight=\"none\" font-size=\"none\" text-anchor=\"none\" style=\"mix-blend-mode: normal\"/></svg>"
        }
      },
      "within": {
        "@id": "http://manifest.tenthousandrooms.yale.edu/node/311/manifest",
        "@type": "sc:Manifest"
      }
    }
  ],
  "layerId": "http://manifest.tenthousandrooms.yale.edu/layers/16"
}
~~~
{: title="Canonical" }

~~~ json
{
  "@id": "http://annotations.ten-thousand-rooms.yale.edu/annotations/215bc9b4-ca41-4467-a823-4440c420eb8e",
  "@type": "oa:annotation",
  "@context": "http://iiif.io/api/presentation/2/context.json",
  "resource": [
    {
      "@type": "dctypes:Text",
      "format": "text/html",
      "chars": "<p>《孔子集語》&nbsp;</p>"
    }
  ],
  "within": [
    "http://annotations.ten-thousand-rooms.yale.edu/lists/http://manifest.tenthousandrooms.yale.edu/layers/16_http://manifest.tenthousandrooms.yale.edu/node/311/canvas/14116",
    "http://annotations.tenkr.yale.edu/annotations/lists/http://ten-thousand-rooms.herokuapp.com/layers/5557c1c3-53d5-4af5-bfc8-990008826fcc_http://manifest.tenthousandrooms.yale.edu/node/311/canvas/14116"
  ],
  "motivation": [
    "oa:commenting"
  ],
  "on": {
    "@type": "oa:SpecificResource",
    "full": "http://manifest.tenthousandrooms.yale.edu/node/311/canvas/14116",
    "selector": {
      "@type": "oa:SvgSelector",
      "value": "<svg xmlns='http://www.w3.org/2000/svg'><path xmlns=\"http://www.w3.org/2000/svg\" d=\"M292.21935,122.21566l109.99409,0l109.99409,0l0,476.64106l0,476.64106l-109.99409,0l-109.99409,0l0,-476.64106z\" data-paper-data=\"{&quot;rotation&quot;:0,&quot;annotation&quot;:null}\" id=\"rectangle_647a69af-6014-412d-8c28-6e561ec82dde\" fill-opacity=\"0\" fill=\"#00bfff\" stroke=\"#00bfff\" stroke-width=\"1.74594\" stroke-linecap=\"butt\" stroke-linejoin=\"miter\" stroke-miterlimit=\"10\" stroke-dasharray=\"\" stroke-dashoffset=\"0\" font-family=\"sans-serif\" font-weight=\"normal\" font-size=\"12\" text-anchor=\"start\" mix-blend-mode=\"normal\"/></svg>"
    }
  },
  "layerId": "http://manifest.tenthousandrooms.yale.edu/layers/16"
}
~~~
{: title="Old" }


