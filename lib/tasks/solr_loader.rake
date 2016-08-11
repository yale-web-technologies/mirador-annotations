namespace :solr_loader do
  desc "load Solr documents from all manifests and annotations"
  task :solrLoadAll => :environment do
    require 'annotation_solr_loader'
    AnnotationSolrLoader.new.load_all_annotations()
  end
end