namespace :migrate_annotation_tags do
  desc "Copy tag data from Annotation=>resource to separate table" 
  task migrate: :environment do
    annotations = Annotation.all
    annotations.each do |anno|
      resources = JSON.parse(anno.resource)
      # only interested in resources that are a tag
      tags = resources.select { |entry| entry["@type"] == "oa:Tag"}
      tags.each do |entry|
        tag_name = entry["chars"]
        tag = AnnotationTag.where(name: tag_name)
        # create the tag if not in the db
        if tag.empty?
          tag = AnnotationTag.create(name: tag_name)
        end
        anno.annotation_tags << tag
      end
    end
  end
end
