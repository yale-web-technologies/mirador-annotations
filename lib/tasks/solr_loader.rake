namespace :solr_loader do
  desc "load Solr documents from all manifests and annotations"
  task :solrLoadAll => :environment do
    require 'mirador-annotation-solr-loader'
    MiradorAnnotationSolrLoader.new.load_all_annotations()
  end
end