namespace :add_chap_scene_seq_tags do
  desc "add chapter, scene and sequence tags to non-svg annos for LOTB"
  task :addTags => :environment do
    @host = Rails.application.config.hostUrl
    @host += '/'   if !@host.end_with? '/'
    p "@host= #{@host}"
    count=0

    # get all annotations and set up loop
    annotations = Annotation.all
    annotations.each do |anno|
      count+=1
      p count.to_s + ") #{anno.annotation_id}"
      next if count < 112  #first non-svg in local db
      exit if count > 150

      # skip this anno if it is a shape anno (Chapter or Scene)
      #p "anno.on = #{anno.on}"
      p "yes is svg" if anno.on.include?("oa:Svg")

      next if anno.on.include?("oa:Svg")

      annoId = anno.annotation_id
      p "annotation_id passed svg test: #{annoId}"

      chapIndex = 0
      sceneIndex =  0
      seqIndex = 0

      # anno.annotation_id: parse out the chapter, scene and seq
      chapIndex = annoId.index("Chapter")
      sceneIndex =  annoId.index("Scene")
      sceneIndex = annoId.length if sceneIndex==0
      sceneSeparator = annoId.index("_",sceneIndex + 5)
      sequenceSeparator = annoId.index("_", sceneSeparator + 1)
      seqIndex =  annoId.index("_",sequenceSeparator)
      seqIndex = annoId.length if seqIndex==0 || seqIndex.nil?
      seqEnd = annoId.index("_",seqIndex+1)
      p "      chapIndex = #{chapIndex}"
      p "      sceneIndex = #{sceneIndex}"
      p "      seqIndex = #{seqIndex}"

      chapter = annoId[chapIndex..sceneIndex - 1]
      scene = annoId[sceneIndex..seqIndex - 1]
      sequence = annoId[seqIndex+1..seqEnd-1]
      p "      chapter = #{chapter}"
      p "      scene = #{scene}"
      p "      sequence = #{sequence}"

      p "\n"

      # anno.resource: add a tag each to the resource for chapter, scene and seq

      # use update_attributes to update the anno with the updated resource
    end
  end

end

