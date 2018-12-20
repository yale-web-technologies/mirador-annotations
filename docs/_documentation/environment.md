---
title: Environment
position: 5
---

##### Environment Variables

| IIIF_HOST_URL | Entity IDs will be prefixed with this URL |
| USE_REDIS | If `Y`, /getAnnotationsList is served from the Redis cache |
| S3_Bucket | URL of the S3 bucket to which export and search feed files are uploaded |
| S3_Bucket_Folder | Folder name under the said S3 bucket |
| S3_Key | S3 credential |
| S3_Secret | S3 credential |
| S3_PUBLIC_DOWNLOAD_PREFIX | URL prefix from which to download exported CSV files |
| IIIF_COLLECTIONS_HOST | URL of host that provides the collection information for exports |
| USE_JWT_AUTH | If 'Y', authenticate the REST API using JWT tokens |

For local development only:
```
DB_HOST_DEV
DATABASE_DEV
DB_USERNAME_DEV
DB_PASSWORD_DEV
DB_HOST_TEST
DATABASE_TEST
DB_USERNAME_TEST
DB_PASSWORD_TEST
```
