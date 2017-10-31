namespace :migrate_annotation_tags do
  desc "TODO"
  task migrate: :environment do
    annotations = Annotation.all
    annotations.each do |anno|
      resources = JSON.parse(anno.resource)
      # only interested in resources that are a tag
      tags = resources.select { |entry| entry["@type"] == "oa:Tag"}
      tags.each do |tag|
        tag_name = tag["chars"]
        # create the tag if not in the db
        if AnnotationTag.where(name: tag_name).empty?
          AnnotationTag.create(name: tag_name)
        end
        tag_id = AnnotationTag.where(name: tag_name).first.id
        # create the join table entry
        AnnotationTagMap.
          create(annotation_id: anno.id, annotation_tag_id: tag_id)
      end
    end
  end
end
