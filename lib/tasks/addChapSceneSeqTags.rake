namespace :add_chap_scene_seq_tags do
  desc "add chapter, scene and sequence tags to non-svg annos for LOTB"
  task :addTags => :environment do
    @host = Rails.application.config.hostUrl
    @host += '/' if !@host.end_with? '/'
    puts "@host= #{@host}"
    count = 0

    # get all annotations and set up loop
    annotations = Annotation.all
    annotations.each do |anno|
      count += 1
      puts count.to_s + ") #{anno.annotation_id}"
      #puts "on: #{anno.on}"

      #exit if count > 100 # XXXX

      # skip this anno if it is a shape anno (Chapter or Scene)
      targetingCanvas = anno.on.include?("oa:SpecificResource")

      if targetingCanvas
        puts "    Targeting canvas: yes"
        next
      else
        puts "    Targeting canvas: no"
      end

      next if targetingCanvas

      annoId = anno.annotation_id

      chapIndex = 0
      sceneIndex =  0
      seqIndex = 0

      # anno.annotation_id: parse out the chapter, scene and seq
      chapIndex = annoId.index("Chapter")
      sceneIndex =  annoId.index("Scene")
      sceneIndex = annoId.length if sceneIndex == 0
      sceneSeparator = annoId.index("_", sceneIndex + 5)
      sequenceSeparator = annoId.index("_", sceneSeparator + 1)
      seqIndex =  annoId.index("_",sequenceSeparator)
      seqIndex = annoId.length if seqIndex==0 || seqIndex.nil?
      seqEnd = annoId.index("_",seqIndex+1)

      chapterTag = annoId[chapIndex..sceneIndex - 1].gsub('_', '').downcase
      sceneTag = annoId[sceneIndex..seqIndex - 1].gsub('_', '').downcase
      sequenceTag = 'p' + annoId[seqIndex+1..seqEnd-1]
      puts "    chapter = #{chapterTag}"
      puts "    scene = #{sceneTag}"
      puts "    sequence = #{sequenceTag}"

      anno.resource = sanitizeJSON(anno.resource)
      tags = getTags(anno)
      puts "    tags before: #{tags}"

      addTags(anno, [chapterTag, sceneTag, sequenceTag])

      tags = getTags(anno)
      puts "    tags after: #{tags}"
      puts "\n"

      anno.save!
    end
  end

  def getTags(anno)
    tags = []
    resourceItems = makeArray(JSON.parse(anno.resource))
    resourceItems.each do |item|
      if item['@type'] == 'oa:Tag'
        tags << item['chars']
      end
    end
    tags
  end

  def addTags(anno, tags)
    existingTags = getTags(anno)
    resourceItems = JSON.parse(anno.resource)
    tags.each do |tag|
      if !existingTags.include?(tag)
        resourceItems << { '@type' => 'oa:Tag', 'chars' => tag }
      end
    end
    anno.resource = resourceItems.to_json
  end

  def makeArray(item)
    if item.class != Array
      item = [item]
    end
    item
  end

  def sanitizeJSON(jsonText)
    jsonText.gsub("\n", "\\n")
  end

end

