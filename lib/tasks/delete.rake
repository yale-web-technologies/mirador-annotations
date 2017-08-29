namespace :delete do
  desc "Delete from list_annotations_maps all annotations for the chapter that targets another annotation"
  task :chapter_from_list_annotations_maps, [:chapter] => :environment do |t, args|
    chapter = args.chapter
    hostUrl = Rails.application.config.hostUrl.sub(/\/$/, '')

    annotations = Annotation.select(:id, :annotation_id).where('annotation_id ~ ? and "on" not like ?',  ".*Chapter_#{chapter}(_.+)?$", '%oa:Svg%')
    annotation_ids = annotations.map { |anno| anno.annotation_id }.uniq
    list_annotation_maps = ListAnnotationsMap.where(:annotation_id => annotation_ids)

    puts "Deleting lists"
    list_annotation_maps.each do |m|
      puts "List: #{m.list_id}"
      puts "Anno: #{m.annotation_id}"
      puts
      m.destroy
    end

    puts "\nDeleteing annotations"

    annotations.each do |anno|
      puts "#{anno.id} #{anno.annotation_id}"
      Annotation.destroy(anno.id)
    end
  end
end