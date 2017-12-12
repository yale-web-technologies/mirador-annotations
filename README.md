[![Build Status](https://travis-ci.org/yale-web-technologies/mirador-annotations.svg?branch=master)](https://travis-ci.org/yale-web-technologies/mirador-annotations) [![Dependency Status](https://gemnasium.com/badges/github.com/yale-web-technologies/mirador-annotations.svg)](https://gemnasium.com/github.com/yale-web-technologies/mirador-annotations)

# Mirador-Annotations
## Purpose
Provide a simple International Image Interoperability Framework (IIIF) Annotations server. Intended to be paired with Mirador, but can be used as a standalone deployment.

## About
It assumes an outside manifest and canvas server, but can be pointed to by a Mirador endpoint and used to store and retrieve annotations.

One main thrust of Mirador-Annotations is to support the IIIF `Layers=>Lists=>Annotations` structure as an alternate way of organizing annotations. For example, a manuscript can be annotated with transcript, translation, and commentary annotations and be organized by those functions along with the standard `manifest=>canvas=>annotation_list` structure.

See wiki home page for more background and information.

## Getting Started

### Basic Installation

Mirador-Annotations is a standard Ruby on Rails application with the usual deployment steps:

1. clone the repository
2. `bundle install`
3. `rake db:migrate`
4. Set `.env` config variables

### Developing Via Docker
If you prefer to develop via Docker, define the required variables in the `.env` file, then run the following:

1. `docker-compose up -d`
2. `docker-compose run rails rake db:migrate`

This will get the containers running in a private network. The rails container is exposed and bound to port 3000 on your local machine by default.

For troubleshooting tips on on developing with docker check the wiki.


## Usage Notes
Mirador-Annotations receives new annotations in IIIF format and will save to whichever relational database is configured. It will also return requested annotations in IIIF format.

Allows both standard annotations which are bound to a canvas, and "targeting" annotations which are bound to another annotation.

Layers should be created manually, and when a canvas-bound annotation is entered it will automatically add to a list defined by layer and canvas.

Custom method `#getAnnotationsForCanvas` is an API call method which will return all annotations which are bound to a given canvas,	along with all annotations which target it either directly or indirectly. For example: Annotation 3 targets Annotation 2; Annotation 2 targets standard Annotation 1; Annotation 1 is bound to a canvas.

## External Links
* [Project Mirador](https://github.com/ProjectMirador/mirador)
* [International Image Interoperability Framework (IIIF)](http://iiif.io/)
