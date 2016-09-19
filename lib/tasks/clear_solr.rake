namespace :clear_solr do
  desc "clear Solr documents from all manifests and annotations"
  task :clear => :environment do
    require 'mirador-annotation-solr-loader'
    MiradorAnnotationSolrLoader.new.clear_solr()
  end
end