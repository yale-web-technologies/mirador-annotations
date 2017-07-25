**Mirador-Annotations**

Purpose: provide a simple IIIF Annotations server which can be used stand-alone, but is designed with pairing with Mirador in mind. It assumes an outside manifest and canvas server, but can be pointed to by a Mirador endpoint and used to store and retrieve annotations.
One main thrust of Mirador-Annotations is to support the IIIF Layers=>Lists=>Annotations structure as an alternate way of organizing annotations. For example, a manuscript can be annotated with transcript, translation and commentary annotations and be organized by those functions along with the standard manifest=>canvas=>annotation_list structure.
See wiki home page for more background and information.

Getting Started:
Mirador-Annotations is basically a standard Ruby on Rails application with the usual deployment steps:
**Installation:**
	- git clone
	- bundle
	- rake db:migrate
1.	Clone the repository
2.	Run bundle install
3.	Rake db:migrate
4. 	Set env config variables:
        - IIIF_HOST_URL
        - USE_REDIS
          if USE_REDIS is set to 'Y' then set these:
            - REDIS_URL
            - S3_Bucket
            - S3_Bucket_Folder
            - S3_Key
            - S3_Secret

**Usage:**
    - Mirador-Annotations receives new annotations in IIIF format and will save to whichever relational database
	 is configured. It will also return requested annotations in IIIF format.
    - For use with Mirador, the central thought is to allow both standard annotations which are bound to a canvas,
	and "targeting" annotations which are bound to another annotation.
    - layers should be created manually, and when an canvas-bound annotation is entered it will automatically add to a list defined by layer and canvas
    - Custom Method *getAnnotationsForCanvas* is an API call method which will return all annotations which are bound to a given canvas,
	along with all annotations which target it either directly or indirectly
	(i.e. Annotation 3 targets Annotation 2 which targets standard Annotation 1, which is bound to a canvas)

