---
title: Authentication
position: 2
---

Authentication for create, update, and delete operations are handled through
JWT tokens. Mirador is initialized with a token for the project and the user
from the Drupal portal and passes it to annotation server along with its
ajax requests. The annotation server decodes the token using a shared key
and queries the portal to see if the user is allowed to perform the operation.
