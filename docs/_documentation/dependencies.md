---
title: Dependencies
position: 4
---

#### API dependencies
* `${drupal_portal_url}/has-canvas-access?canvas_id=${canvas_id}&user_id=${user_id}` - to check if the user ID (extracted from the JWT token) has permission for the canvas. In Drupal, this API is impemented as a view with a contextual filter.
* `${drupal_portal_url}/node/#{project_id}/collection?user_id=#{user_id}` - to get collection information for exporting annotations data for the project.

#### Imagemagick
* The `feed_for_search:bounding_boxes` rake task depends on the `rmagick` gem, which in turn depends on the native installation of Imagemagick (note: version 6, not 7).
