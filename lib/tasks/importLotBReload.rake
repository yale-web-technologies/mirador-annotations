namespace :importLotBReload do

  desc "imports LoTB annotation data from a csv file"
  #Sun of Faith - Structured Chapters - ch. 26.csv normalized
  # Assumption: will be loaded by worksheet per chapter: first column holds panel, second column holds chapter, third column holds scene
  # Iterating through sheet needs to check for new scene, but not for new panel or chapter
  #task :LoTB_annotations => :environment do
  #task :LoTB_
  # 3/2017: This task is modified from importLotB, but is assumes:
  # - the non-Chapter and non-Scene annotations that were created during the load have been preserved (to preserve the svg data added later with task updateSVG)
  # - the content annotations (i.e. the rows from the spreadsheet which have been updated since initial load, and often ascribed to different scenes) have been deleted
  # - to accommodate this, all the chapter and scene logic has been removed or de-activated here
  #
  # annotations, [:startFile, :endFile] do |t, args|
  task :LoTB_annotations, [:startFile, :endFile] => :environment do |t, args|
    require 'csv'

    @ru = Rails.application.config.hostUrl
    if @ru.end_with?('/')
      @ru = @ru[0...-1]
    end

    labels = Array.new
    i = 0
    j=0
    ctr=0
    panel = " "
    chapter = " "
    scene = " "
    lastScene = 0
    nextSceneSeq = 0

    for i in args.startFile..args.endFile
    #for i in 1..28
      chapterFilename = "importData/LOTB_Spreadsheet_ReLoad_7-2017/lotb_ch#{i}.csv"
      p "chapterFilename = #{chapterFilename}"
      firstLineInChapter = 0
      CSV.foreach(chapterFilename) do |row|
        firstLineInChapter += 1; # total counter
        puts "i = #{i.to_s}  chapter: #{chapterFilename}"
        puts 'row.size = ' + row.size.to_s

        # First Row: set labels from column headings
        if (firstLineInChapter==1)   # gets cleared for each new chapter
          while j <= 12
            labels[j] = row[j]
            j += 1
          end
        else
          #Process as an annotation
          panel = row[0]
          chapter = row[1]

          #set the canvas based on the chapter number, since row[0] is not always filled in
          if (panel == "B")
            canvas = 'http://manifests.ydc2.yale.edu/LOTB/canvas/bv11'
          else
            canvas = 'http://manifests.ydc2.yale.edu/LOTB/canvas/panel_01'
          end

          # check for new Scene
          # this is to setup the new scene drawing annotation and initialize the nextSceneSeq num
          scene = row[2]
          scene = "0" if (scene.nil?)
          if (lastScene != scene)
            p "about to call newScene: row[13] = #{row[2]}"
            #createNewScene row
            puts "just reset nextSceneSeq at i = #{i}: scene = #{scene} and lastScene = #{lastScene}"
            lastScene = scene
            nextSceneSeq = 0
          end
          nextSceneSeq += 1
          puts "nextSceneSeq = #{nextSceneSeq}"
  #===================================================================================================================================================================

          # 1) create the Tibetan Sun of Faith transcription annotation for this row ([3]
          unless row[3].nil?
            annotation_id = @ru + "/annotations/"+ "Panel_" + panel + "_Chapter_" + chapter + "_Scene_" + scene + "_" + nextSceneSeq.to_s +
                "_Tibetan_Sun_Of_Faith"
            p "about to create annotation: #{annotation_id}"
            annotation_type = "oa:annotation"
            motivation = "[oa:transcribing]"
            label = "Tibetan transcription: Sun of Faith"
            on = '{
                "@type": "oa:Annotation",
                "full": "'
            if (scene=="0")
              on += @ru + '/annotations/'+ 'Panel_' + row[0] + '_Chapter_' + row[1]
            else
              on += @ru + '/annotations/'+ 'Panel_' + row[0] + '_Chapter_' + row[1] + '_Scene_' + scene
            end
            on += '"}'
            on = JSON.parse(on)
            #canvas = "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
            #canvas = on['full']
            manifest = "tbd"
            chars = row[3]
            #p "chars = " + chars.to_s
            resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"'
            resource += "<p><span style='font-size: 24px;'>"
            resource += chars.to_s
            resource += "</p></span>"
            resource += '"}]'
            active = true
            version = 1
            @annotation = Annotation.create(annotation_id: annotation_id, annotation_type: annotation_type, motivation: motivation, label:label, on: on, canvas: canvas, manifest: manifest,  resource: resource, active: active, version: version)
            result = @annotation.save!(options={validate: false})

            #p 'just created tibetan annotation: ' + annotation_id

            #sceneList =  @ru + "/lists/Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" + scene
            #languageList = @ru + "/lists/Tibetan_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
            languageList = @ru + "/lists/" + @ru + "/layers/Tibetan_" + canvas
            withinArray = Array.new
            #withinArray.push(sceneList)
            withinArray.push(languageList)
            ListAnnotationsMap.setMap withinArray, @annotation['annotation_id']
          end
          #===================================================================================================================================================================
          # 2) create the Tibetan Inscription transcription annotation for this row ([5]
          unless row[5].nil?
            annotation_id = @ru + "/annotations/"+ "Panel_" + panel + "_Chapter_" + chapter + "_Scene_" + scene + "_" + nextSceneSeq.to_s + "_Tibetan_Inscription"
            p "about to create annotation: #{annotation_id}"
            annotation_type = "oa:annotation"
            motivation = "[oa:transcribing]"
            label = "Tibetan transcription: Inscription"
            on = '{
                "@type": "oa:Annotation",
                "full": "'
            if (scene=="0")
              on += @ru + '/annotations/'+ 'Panel_' + row[0] + '_Chapter_' + row[1]
            else
              on += @ru + '/annotations/'+ 'Panel_' + row[0] + '_Chapter_' + row[1] + '_Scene_' + scene
            end
            on += '"}'
            on = JSON.parse(on)
            #canvas = "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
            #canvas = on['full']
            manifest = "tbd"
            chars = row[5]
            #resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + chars+'"}]'
            resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"'
            resource += "<p><span style='font-size: 24px;'>"
            resource += chars
            resource += "</p></span>"
            resource += '"}]'
            active = true
            version = 1
            @annotation = Annotation.create(annotation_id: annotation_id, annotation_type: annotation_type, motivation: motivation, label:label, on: on, canvas: canvas, manifest: manifest,  resource: resource, active: active, version: version)
            result = @annotation.save!(options={validate: false})
            #languageList = @ru + "/lists/Tibetan_Inscription_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
            languageList = @ru + "/lists/" + @ru + "/layers/Tibetan_Inscription_" + canvas

            withinArray = Array.new
            #withinArray.push(sceneList)
            withinArray.push(languageList)
            ListAnnotationsMap.setMap withinArray, @annotation['annotation_id']
          end
          #===================================================================================================================================================================
          # 3) create the Tibetan Manual transcription annotation for this row ([7]
          unless row[7].nil?
            annotation_id = @ru + "/annotations/"+ "Panel_" + panel + "_Chapter_" + chapter + "_Scene_" + scene + "_" + nextSceneSeq.to_s + "_Tibetan_Manual"
            p "about to create annotation: #{annotation_id}"
            annotation_type = "oa:annotation"
            motivation = "[oa:transcribing]"
            label = "Tibetan transcription: Manual"
            on = '{
                "@type": "oa:Annotation",
                "full": "'
            if (scene=="0")
              on += @ru + '/annotations/'+ 'Panel_' + row[0] + '_Chapter_' + row[1]
            else
              on += @ru + '/annotations/'+ 'Panel_' + row[0] + '_Chapter_' + row[1] + '_Scene_' + scene
            end
            on += '"}'
            on = JSON.parse(on)
            #canvas = "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
            #canvas = on['full']
            manifest = "tbd"
            chars = row[7]
            #resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + chars+'"}]'
            resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"'
            resource += "<p><span style='font-size: 24px;'>"
            resource += chars
            resource += "</p></span>"
            resource += '"}]'
            active = true
            version = 1
            @annotation = Annotation.create(annotation_id: annotation_id, annotation_type: annotation_type, motivation: motivation, label:label, on: on, canvas: canvas, manifest: manifest,  resource: resource, active: active, version: version)
            result = @annotation.save!(options={validate: false})
            #languageList = @ru + "/lists/Tibetan_PaintingManual_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
            languageList = @ru + "/lists/" + @ru + "/layers/Tibetan_PaintingManual_" + canvas

            withinArray = Array.new
            #withinArray.push(sceneList)
            withinArray.push(languageList)
            ListAnnotationsMap.setMap withinArray, @annotation['annotation_id']
            end
          #===================================================================================================================================================================
          # 4) create the English Sun of Faith translation annotation for this row ([4]
          unless row[4].nil?
            p "panel = #{panel}"
            p "chapter = #{chapter}"
            p "scene = #{scene}"
            p "nextSceneSeq = #{nextSceneSeq.to_s}"

            annotation_id = @ru + "/annotations/"+ "Panel_" + panel + "_Chapter_" + chapter + "_Scene_" + scene + "_" + nextSceneSeq.to_s + "_English_Sun_Of_Faith"
            p "about to create annotation: #{annotation_id}"
            annotation_type = "oa:annotation"
            motivation = "[oa:translating]"
            label = "English Translation: Sun Of Faith"
            on = '{
                "@type": "oa:Annotation",
                "full": "'
            if (scene=="0")
              on += @ru + '/annotations/'+ 'Panel_' + row[0] + '_Chapter_' + row[1]
            else
              on += @ru + '/annotations/'+ 'Panel_' + row[0] + '_Chapter_' + row[1] + '_Scene_' + scene
            end
            on += '"}'
            on = JSON.parse(on)
            #canvas = "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
            #canvas = on['full']
            manifest = "tbd"
            row[4].gsub!(/"/,39.chr) if (!row[4].nil?)
            chars = row[4]
            #resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + chars+'"}]'
            resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"'
            resource += "<p><span style='font-size: 14px;'>"
            resource += chars
            resource += "</p></span>"
            resource += '"}]'
            active = true
            version = 1
            @annotation = Annotation.create(annotation_id: annotation_id, annotation_type: annotation_type, motivation: motivation, label:label, on: on, canvas: canvas, manifest: manifest,  resource: resource, active: active, version: version)
            result = @annotation.save!(options={validate: false})
            #languageList = @ru + "/lists/English_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
            languageList = @ru + "/lists/" + @ru + "/layers/English_" + canvas

            withinArray = Array.new
            #withinArray.push(sceneList)
            withinArray.push(languageList)
            ListAnnotationsMap.setMap withinArray, @annotation['annotation_id']
          end
          #===================================================================================================================================================================
          # 5) create the English Inscription annotation for this row ([6]
          unless row[6].nil?
            annotation_id = @ru + "/annotations/"+ "Panel_" + panel + "_Chapter_" + chapter + "_Scene_" + scene + "_" + nextSceneSeq.to_s + "_English_Inscription"
            p "about to create annotation: #{annotation_id}"
            annotation_type = "oa:annotation"
            motivation = "[oa:translating]"
            label = "English translation: Inscription"
            on = '{
                "@type": "oa:Annotation",
                "full": "'
            if (scene=="0")
              on += @ru + '/annotations/'+ 'Panel_' + row[0] + '_Chapter_' + row[1]
            else
              on += @ru + '/annotations/'+ 'Panel_' + row[0] + '_Chapter_' + row[1] + '_Scene_' + scene
            end
            on += '"}'
            on = JSON.parse(on)
            #canvas = "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
            #canvas = on['full']
            manifest = "tbd"
            chars = row[6]
            #resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + chars+'"}]'
            resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"'
            resource += "<p><span style='font-size: 14px;'>"
            resource += chars
            resource += "</p></span>"
            resource += '"}]'
            active = true
            version = 1
            @annotation = Annotation.create(annotation_id: annotation_id, annotation_type: annotation_type, motivation: motivation, label:label, on: on, canvas: canvas, manifest: manifest,  resource: resource, active: active, version: version)
            result = @annotation.save!(options={validate: false})
            #languageList = @ru + "/lists/English_Inscription_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
            languageList = @ru + "/lists/" + @ru + "/layers/English_Inscription_" + canvas

            withinArray = Array.new
            #withinArray.push(sceneList)
            withinArray.push(languageList)
            ListAnnotationsMap.setMap withinArray, @annotation['annotation_id']
          end
          #===================================================================================================================================================================
          # 6) create the English Manual annotation for this row ([8]
          unless row[8].nil?
            annotation_id = @ru + "/annotations/"+ "Panel_" + panel + "_Chapter_" + chapter + "_Scene_" + scene + "_" + nextSceneSeq.to_s + "_English_Manual"
            p "about to create annotation: #{annotation_id}"
            annotation_type = "oa:annotation"
            motivation = "[oa:translating]"
            label = "English translation: Manual"
            on = '{
                "@type": "oa:Annotation",
                "full": "'
            if (scene=="0")
              on += @ru + '/annotations/'+ 'Panel_' + row[0] + '_Chapter_' + row[1]
            else
              on += @ru + '/annotations/'+ 'Panel_' + row[0] + '_Chapter_' + row[1] + '_Scene_' + scene
            end
            on += '"}'
            on = JSON.parse(on)
            # canvas = "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
            #canvas = on['full']
            manifest = "tbd"
            chars = row[8]
            #resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + chars+'"}]'
            resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"'
            resource += "<p><span style='font-size: 14px;'>"
            resource += chars
            resource += "</p></span>"
            resource += '"}]'
            active = true
            version = 1
            @annotation = Annotation.create(annotation_id: annotation_id, annotation_type: annotation_type, motivation: motivation, label:label, on: on, canvas: canvas, manifest: manifest,  resource: resource, active: active, version: version)
            result = @annotation.save!(options={validate: false})
            #languageList = @ru + "/lists/English_Manual_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
            languageList = @ru + "/lists/" + @ru + "/layers/English_PaintingManual_" + canvas

            withinArray = Array.new
            #withinArray.push(sceneList)
            withinArray.push(languageList)
            ListAnnotationsMap.setMap withinArray, @annotation['annotation_id']
          end
          #===================================================================================================================================================================
          # create the Canonical annotation for this row ([9]

          unless row[9].nil?
            annotation_id = @ru + "/annotations/"+ "Panel_" + panel + "_Chapter_" + chapter + "_Scene_" + scene + "_" + nextSceneSeq.to_s + "_Canonical Source"
            p "about to create annotation: #{annotation_id}"
            annotation_type = "oa:annotation"
            motivation = "[oa:commenting]"
            label = "Canonical Source"
            on = '{
                "@type": "oa:Annotation",
                "full": "'
            if (scene=="0")
              on += @ru + '/annotations/'+ 'Panel_' + row[0] + '_Chapter_' + row[1]
            else
              on += @ru + '/annotations/'+ 'Panel_' + row[0] + '_Chapter_' + row[1] + '_Scene_' + scene
            end
            on += '"}'
            on = JSON.parse(on)
            #canvas = "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
            #canvas = on['full']
            manifest = "tbd"
            chars = row[9]
            #resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + chars+'"}]'
            resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"'
            resource += "<p><span style='font-size: 14px;'>"
            resource += chars
            resource += "</p></span>"
            resource += '"}]'
            active = true
            version = 1
            @annotation = Annotation.create(annotation_id: annotation_id, annotation_type: annotation_type, motivation: motivation, label:label, on: on, canvas: canvas, manifest: manifest,  resource: resource, active: active, version: version)
            result = @annotation.save!(options={validate: false})
            #sceneList =  @ru + "/lists/Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" + scene
            #languageList = @ru + "/lists/Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" +scene + ":Tibetan"
            #list = @ru + "/lists/CanonicalSource"
            #list = @ru + "/lists/CanonicalSources/_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
            list = @ru + "/lists/" + @ru + "/layers/CanonicalSources_" + canvas

            withinArray = Array.new
            #withinArray.push(sceneList)
            withinArray.push(list)
            ListAnnotationsMap.setMap withinArray, @annotation['annotation_id']
           end
          #===================================================================================================================================================================
          # create the Secondary/Tertiary Canonical annotation for this row ([10]


          unless row[10].nil?
            annotation_id = @ru + "/annotations/"+ "Panel_" + panel + "_Chapter_" + chapter + "_Scene_" + scene + "_" + nextSceneSeq.to_s + "_Secondary/Tertiary Canonical Source"
            p "about to create annotation: #{annotation_id}"
            annotation_type = "oa:annotation"
            motivation = "[oa:commenting]"
            label = "Secondary/TertiaryCanonical Source"
            on = '{
                "@type": "oa:Annotation",
                "full": "'
            if (scene=="0")
              on += @ru + '/annotations/'+ 'Panel_' + row[0] + '_Chapter_' + row[1]
            else
              on += @ru + '/annotations/'+ 'Panel_' + row[0] + '_Chapter_' + row[1] + '_Scene_' + scene
            end
            on += '"}'
            on = JSON.parse(on)
            #canvas = "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
            #canvas = on['full']
            manifest = "tbd"
            chars = row[10]
            #resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + chars+'"}]'
            resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"'
            resource += "<p><span style='font-size: 14px;'>"
            resource += chars
            resource += "</p></span>"
            resource += '"}]'
            active = true
            version = 1
            @annotation = Annotation.create(annotation_id: annotation_id, annotation_type: annotation_type, motivation: motivation, label:label, on: on, canvas: canvas, manifest: manifest,  resource: resource, active: active, version: version)
            result = @annotation.save!(options={validate: false})
            #sceneList =  @ru + "/lists/Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" + scene
            #languageList = @ru + "/lists/Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" +scene + ":Tibetan"
            #list = @ru + "/lists/CanonicalSource"
            #list = @ru + "/lists/CanonicalSources/_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
            list = @ru + "/lists/" + @ru + "/layers/SecondaryCanonicalSources_" + canvas

            withinArray = Array.new
            #withinArray.push(sceneList)
            withinArray.push(list)
            ListAnnotationsMap.setMap withinArray, @annotation['annotation_id']
          end

          #===================================================================================================================================================================
          # create the Secondary/Tertiary Canonical annotation for this row ([10]


          unless row[11].nil?
            annotation_id = @ru + "/annotations/"+ "Panel_" + panel + "_Chapter_" + chapter + "_Scene_" + scene + "_" + nextSceneSeq.to_s + "_Scene Working Notes"
            p "about to create annotation: #{annotation_id}"
            annotation_type = "oa:annotation"
            motivation = "[oa:commenting]"
            label = "Scene Working Notes"
            on = '{
                "@type": "oa:Annotation",
                "full": "'
            if (scene=="0")
              on += @ru + '/annotations/'+ 'Panel_' + row[0] + '_Chapter_' + row[1]
            else
              on += @ru + '/annotations/'+ 'Panel_' + row[0] + '_Chapter_' + row[1] + '_Scene_' + scene
            end
            on += '"}'
            on = JSON.parse(on)
            #canvas = "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
            #canvas = on['full']
            manifest = "tbd"
            chars = row[11]
            chars.gsub!(/"/,'')
            chars.gsub!(/'/,'')
            #resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + chars+'"}]'
            resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"'
            resource += "<p><span style='font-size: 14px;'>"
            resource += chars
            resource += "</p></span>"
            resource += '"}]'
            active = true
            version = 1
            @annotation = Annotation.create(annotation_id: annotation_id, annotation_type: annotation_type, motivation: motivation, label:label, on: on, canvas: canvas, manifest: manifest,  resource: resource, active: active, version: version)
            result = @annotation.save!(options={validate: false})
            #sceneList =  @ru + "/lists/Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" + scene
            #languageList = @ru + "/lists/Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" +scene + ":Tibetan"
            #list = @ru + "/lists/CanonicalSource"
            #list = @ru + "/lists/CanonicalSources/_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
            list = @ru + "/lists/" + @ru + "/layers/SceneWorkingNotes_" + canvas

            withinArray = Array.new
            #withinArray.push(sceneList)
            withinArray.push(list)
            ListAnnotationsMap.setMap withinArray, @annotation['annotation_id']
          end
          #===================================================================================================================================================================
        end
      end
    end
  end


  def createNewList list
    lists = AnnotationList.where(list_id: list['list_id']).first
    if (lists.nil?)
      @newList = AnnotationList.create(list_id: list['list_id'], list_type: list['list_type'],
                                       label:list['label'], description:list['description'], version: list['version'])
      LayerListsMap.setMap list['within'],list['list_id']
    end
    LayerListsMap.setMap list['within'],list['list_id']
  end




  def createNewRenderingAnnotation newAnnotation
    p "*********====> createNewRenderingAnnotation: ON = #{newAnnotation['on'].to_s}"
    annotations = Annotation.where(annotation_id: newAnnotation['annotation_id']).first
    #if (annotations.nil?)
      #addTagsToRenderingAnnotation newAnnotation
      #p 'in createNewRenderingAnnotation: resource = ' + newAnnotation['resource'].to_s
      @annotation = Annotation.create(annotation_id:newAnnotation['annotation_id'], annotation_type: newAnnotation['annotation_type'], motivation: newAnnotation['motivation'],
                                      description:newAnnotation['description'], resource:newAnnotation['resource'].to_s, on: newAnnotation['on'].to_s, canvas: newAnnotation['canvas'], manifest: newAnnotation['manifest'],
                                      active: newAnnotation['active'],
                                      version: newAnnotation['version'])
      ListAnnotationsMap.setMap newAnnotation['within'], newAnnotation['annotation_id']
    #end
  end


=begin
        resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"'
        resource += chars.to_s
        resource += '"}]'
an anno with chapter and scene tags:
  "resource": [
    {
      "@type": "dctypes:Text",
     "chars": "<p>28.1</p>",
      "format": "text/html"
    },
    {
      "@type": "oa:Tag",
      "chars": "chapter28"
    },
    {
      "@type": "oa:Tag",
      "chars": "scene1"
    }
  ],

=end

#================= end LotB ================
  # with args = 19,28
  #task :LoTB_annotations => :environment do
  #task :my_task, [:startFile, :endFile] do |t, args|
  task :my_task , [:startFile, :endFile] => :environment do |t, args|
    puts "StartFile = #{args.startFile}"
    puts "EndFile = #{args.endFile}"
    for i in args.startFile..args.endFile
      chapterFilename = "lotb_ch#{i}.csv"
      puts "chapter file = #{chapterFilename}"
    end
  end

end










