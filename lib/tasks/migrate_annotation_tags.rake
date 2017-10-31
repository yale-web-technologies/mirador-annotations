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
        # .first accounts for any duplicate tags from other migrations
        tag = AnnotationTag.where(name: tag_name).first
        # create the tag if not in the db
        if tag.nil?
          tag = AnnotationTag.create(name: tag_name)
        end
        # check if the association already exists
        if anno.annotation_tag_maps.where(annotation_tag_id: tag.id).first.nil?
          anno.annotation_tags << tag
        end
      end
    end
  end
end
