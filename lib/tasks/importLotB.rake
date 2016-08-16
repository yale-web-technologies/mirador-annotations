namespace :importLotB do

  desc "imports LoTB annotation data from a csv file"
  #Sun of Faith - Structured Chapters - ch. 26.csv normalized
  # Assumption: will be loaded by worksheet per chapter: first column holds panel, second column holds chapter, third column holds scene
  # Iterating through sheet needs to check for new scene, but not for new panel or chapter
  #task :LoTB_annotations => :environment do
  #task :LoTB_
  #
  # annotations, [:startFile, :endFile] do |t, args|
  task :LoTB_annotations, [:startFile, :endFile] => :environment do |t, args|
    require 'csv'
    #require 'socket'

    #@ru = "http://localhost:5000"
    @ru = "http://mirador-annotations-lotb-stg.herokuapp.com"
    #@ru = "http://mirador-annotations-lotb.herokuapp.com"

    labels = Array.new
    i = 0
    j=0
    ctr=0
    panel = " "
    chapter = " "
    scene = " "
    lastScene = 0
    nextSceneSeq = 0
#=begin
    makeLanguageLayers # comment out for prod re-do
    makeLanguageLists  #comment out for prod re-do
    makeTibetanLayersInscriptionAndManual
    makeTibetanListsInscriptionAndManual
    makeEnglishLayersInscriptionAndManual
    makeEnglishListsInscriptionAndManual

    makeChaptersScenesLayers # comment out for prod re-do
    makeChaptersScenesLists # comment out for prod re-do
    makeCanonicalSourceLayers # comment out for prod re-do
    makeCanonicalSourceLists # comment out for prod re-do
    makeSecondaryCanonicalSourceLayers # comment out for prod re-do
    makeSecondaryCanonicalSourceLists # comment out for prod re-do
#=end

    for i in args.startFile..args.endFile
      chapterFilename = "importData/lotb_ch#{i}.csv"
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

          # new Chapter now handled in newScene
          # check for new Chapter
          #if (lastChapter != chapter)
          #  p "about to call newChapter:  #{row[1]}"
          #  createNewChapter row
          #  lastChapter = chapter
          #end
          # check for new Scene
          # this is to setup the new scene drawing annotation and initialize the nextSceneSeq num
          scene = row[2]
          scene = "0" if (scene.nil?)
          if (lastScene != scene)
            p "about to call newScene: row[13] = #{row[12]}"
            createNewScene row
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
            resource += chars.to_s
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
            resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + chars+'"}]'
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
            resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + chars+'"}]'
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
            annotation_id = @ru + "/annotations/"+ "Panel_" + panel + "_Chapter_" + chapter + "_Scene_" + scene + "_" + nextSceneSeq.to_s + "_English_Sun_Of_Faith"

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
            resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + chars+'"}]'
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
            resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + chars+'"}]'
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
            resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + chars+'"}]'
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
            resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + chars+'"}]'
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
            resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + chars+'"}]'
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
        end
      end
    end
  end

  def makeLanguageLayers
    layer = Hash.new
    layer['layer_id'] = @ru + "/layers/Tibetan"
    layer['layer_type'] = "sc:layer"
    layer['label'] = "Sun of Faith Tibetan"
    layer['motivation'] = "[oa:commenting]"
    layer['description'] = "Sun of Faith Tibetan Transcriptions"
    layer['license'] = "http://creativecommons.org/licenses/by/4.0/"
    layer['version'] = " "
    createNewLayer layer

    layer = Hash.new
    layer['layer_id'] = @ru + "/layers/English"
    layer['layer_type'] = "sc:layer"
    layer['label'] = "Sun of Faith English"
    layer['motivation'] = "[oa:commenting]"
    layer['description'] = "Sun of Faith English Transcriptions"
    layer['license'] = "http://creativecommons.org/licenses/by/4.0/"
    layer['version'] = " "
    createNewLayer layer
  end

  def makeEnglishLayersInscriptionAndManual
    layer = Hash.new
    layer['layer_id'] = @ru + "/layers/English_Inscription"
    layer['layer_type'] = "sc:layer"
    layer['label'] = "Inscription English"
    layer['motivation'] = "[oa:commenting]"
    layer['description'] = "Sun of Faith Inscription English"
    layer['license'] = "http://creativecommons.org/licenses/by/4.0/"
    layer['version'] = " "
    createNewLayer layer

    layer = Hash.new
    layer['layer_id'] = @ru + "/layers/English_PaintingManual"
    layer['layer_type'] = "sc:layer"
    layer['label'] = "Painting Manual English"
    layer['motivation'] = "[oa:commenting]"
    layer['description'] = "Sun of Faith Painting Manual English"
    layer['license'] = "http://creativecommons.org/licenses/by/4.0/"
    layer['version'] = " "
    createNewLayer layer
  end

  def makeTibetanLayersInscriptionAndManual
    layer = Hash.new
    layer['layer_id'] = @ru + "/layers/Tibetan_Inscription"
    layer['layer_type'] = "sc:layer"
    layer['label'] = "Inscription Tibetan"
    layer['motivation'] = "[oa:commenting]"
    layer['description'] = "Sun of Faith Inscription Tibetan"
    layer['license'] = "http://creativecommons.org/licenses/by/4.0/"
    layer['version'] = " "
    createNewLayer layer

    layer = Hash.new
    layer['layer_id'] = @ru + "/layers/Tibetan_PaintingManual"
    layer['layer_type'] = "sc:layer"
    layer['label'] = "Painting Manual Tibetan"
    layer['motivation'] = "[oa:commenting]"
    layer['description'] = "Sun of Faith Painting Manual Tibetan"
    layer['license'] = "http://creativecommons.org/licenses/by/4.0/"
    layer['version'] = " "
    createNewLayer layer
  end

  def makeLanguageLists
    # create Tibetan and English lists for this scene
    #canvas = "_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
    list = Hash.new
    #list['list_id'] = @ru + "/lists/Tibetan" + canvas
    list['list_id'] = @ru + "/lists/" + @ru + "/layers/Tibetan_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
    list['list_type'] = "sc:list"
    list['label'] = "Tibetan"
    list['description'] = "Tibetan"
    list['version'] = " "
    languageLayer =   @ru + "/layers/Tibetan"
    withinArray = Array.new
    withinArray.push(languageLayer)
    list['within'] = withinArray
    createNewList list

    list['list_id'] = @ru + "/lists/" + @ru + "/layers/Tibetan_http://manifests.ydc2.yale.edu/LOTB/canvas/panel_01"
    createNewList list

    list = Hash.new
    #list['list_id'] = @ru + "/lists/English" + canvas
    list['list_id'] = @ru + "/lists/" + @ru + "/layers/English_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
    list['list_type'] = "sc:list"
    list['label'] = "English"
    list['description'] = "English"
    list['version'] = " "
    languageLayer =   @ru + "/layers/English"
    withinArray = Array.new
    withinArray.push(languageLayer)
    list['within'] = withinArray
    createNewList list

    list['list_id'] = @ru + "/lists/" + @ru + "/layers/English_http://manifests.ydc2.yale.edu/LOTB/canvas/panel_01"
    createNewList list
  end

  def makeEnglishListsInscriptionAndManual
    #canvas = "_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
    list = Hash.new
    #list['list_id'] = @ru + "/lists/English_Inscription" + canvas
    list['list_id'] = @ru + "/lists/" + @ru + "/layers/English_Inscription_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
    list['list_type'] = "sc:list"
    list['label'] = "English Inscription"
    list['description'] = "English Inscription"
    list['version'] = " "
    languageLayer =   @ru + "/layers/English"
    languageLayer2 = @ru + "/layers/English_Inscription"
    withinArray = Array.new
    #withinArray.push(languageLayer)
    withinArray.push(languageLayer2)
    list['within'] = withinArray
    createNewList list

    list['list_id'] = @ru + "/lists/" + @ru + "/layers/English_Inscription_http://manifests.ydc2.yale.edu/LOTB/canvas/panel_01"
    createNewList list

    list = Hash.new
    #list['list_id'] = @ru + "/lists/English_Manual" + canvas
    list['list_id'] = @ru + "/lists/" + @ru + "/layers/English_PaintingManual_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
    list['list_type'] = "sc:list"
    list['label'] = "English Painting Manual"
    list['description'] = "English Painting Manual"
    list['version'] = " "
    languageLayer =   @ru + "/layers/English"
    languageLayer2 = @ru + "/layers/English_PaintingManual"
    withinArray = Array.new
    #withinArray.push(languageLayer)
    withinArray.push(languageLayer2)
    list['within'] = withinArray
    createNewList list

    list['list_id'] = @ru + "/lists/" + @ru + "/layers/English_PaintingManual_http://manifests.ydc2.yale.edu/LOTB/canvas/panel_01"
    createNewList list
  end

  def makeTibetanListsInscriptionAndManual
    #canvas = "_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
    list = Hash.new
    #list['list_id'] = @ru + "/lists/Tibetan_Inscription" + canvas
    list['list_id'] = @ru + "/lists/" + @ru + "/layers/Tibetan_Inscription_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
    list['list_type'] = "sc:list"
    list['label'] = "Tibetan Inscription"
    list['description'] = "English Inscription"
    list['version'] = " "
    languageLayer =   @ru + "/layers/Tibetan"
    languageLayer2 = @ru + "/layers/Tibetan_Inscription"
    withinArray = Array.new
    #withinArray.push(languageLayer)
    withinArray.push(languageLayer2)
    list['within'] = withinArray
    createNewList list

    list['list_id'] = @ru + "/lists/" + @ru + "/layers/Tibetan_Inscription_http://manifests.ydc2.yale.edu/LOTB/canvas/panel_01"
    createNewList list

    list = Hash.new
    #list['list_id'] = @ru + "/lists/Tibetan_PaintingManual" + canvas
    list['list_id'] = @ru + "/lists/" + @ru + "/layers/Tibetan_PaintingManual_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
    list['list_type'] = "sc:list"
    list['label'] = "Tibetan Painting Manual"
    list['description'] = "Tibetan Painting Manual"
    list['version'] = " "
    languageLayer =   @ru + "/layers/Tibetan"
    languageLayer2 =   @ru + "/layers/Tibetan_PaintingManual"
    withinArray = Array.new
    #withinArray.push(languageLayer)
    withinArray.push(languageLayer2)
    list['within'] = withinArray
    createNewList list

    list['list_id'] = @ru + "/lists/" + @ru + "/layers/Tibetan_PaintingManual_http://manifests.ydc2.yale.edu/LOTB/canvas/panel_01"
    createNewList list
  end


  def makeChaptersScenesLayers
    layer = Hash.new
    layer['layer_id'] = @ru + "/layers/Chapters"
    layer['layer_type'] = "sc:layer"
    layer['label'] = "Sun of Faith Chapters"
    layer['motivation'] = "[oa:commenting]"
    layer['description'] = "Sun of Faith Chapters"
    layer['license'] = "http://creativecommons.org/licenses/by/4.0/"
    layer['version'] = " "
    createNewLayer layer

    layer = Hash.new
    layer['layer_id'] = @ru + "/layers/Scenes"
    layer['layer_type'] = "sc:layer"
    layer['label'] = "Sun of Faith Scenes"
    layer['motivation'] = "[oa:commenting]"
    layer['description'] = "Sun of Faith Scenes"
    layer['license'] = "http://creativecommons.org/licenses/by/4.0/"
    layer['version'] = " "
    createNewLayer layer

    layer = Hash.new
    layer['layer_id'] = @ru + "/layers/Figures"
    layer['layer_type'] = "sc:layer"
    layer['label'] = "Sun of Faith Figures"
    layer['motivation'] = "[oa:commenting]"
    layer['description'] = "Sun of Faith Figures"
    layer['license'] = "http://creativecommons.org/licenses/by/4.0/"
    layer['version'] = " "
    createNewLayer layer
  end

  def makeChaptersScenesLists
    #canvas = "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"

    list = Hash.new
    #list['list_id'] = @ru + "/lists/Chapters/_" + canvas
    list['list_id'] = @ru + "/lists/" + @ru + "/layers/Chapters_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
    list['list_type'] = "sc:list"
    list['label'] = "Chapters"
    list['description'] = "Chapters"
    list['version'] = " "
    layer =   @ru + "/layers/Chapters"
    withinArray = Array.new
    withinArray.push(layer)
    list['within'] = withinArray
    createNewList list

    list['list_id'] = @ru + "/lists/" + @ru + "/layers/Chapters_http://manifests.ydc2.yale.edu/LOTB/canvas/panel_01"
    createNewList list

    list = Hash.new
    #list['list_id'] = @ru + "/lists/Scenes/_" + canvas
    list['list_id'] = @ru + "/lists/" + @ru + "/layers/Scenes_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
    list['list_type'] = "sc:list"
    list['label'] = "Scenes"
    list['description'] = "Scenes"
    list['version'] = " "
    layer =   @ru + "/layers/Scenes"
    withinArray = Array.new
    withinArray.push(layer)
    list['within'] = withinArray
    createNewList list

    list['list_id'] = @ru + "/lists/" + @ru + "/layers/Scenes_http://manifests.ydc2.yale.edu/LOTB/canvas/panel_01"
    createNewList list
  end

  def makeCanonicalSourceLayers
    layer = Hash.new
    layer['layer_id'] = @ru + "/layers/CanonicalSources"
    layer['layer_type'] = "sc:layer"
    layer['label'] = "Sun of Faith Canonical Sources"
    layer['motivation'] = "[oa:commenting]"
    layer['description'] = "Sun of Faith Canonical Sources"
    layer['license'] = "http://creativecommons.org/licenses/by/4.0/"
    layer['version'] = " "
    createNewLayer layer
  end

  def makeSecondaryCanonicalSourceLayers
    layer = Hash.new
    layer['layer_id'] = @ru + "/layers/SecondaryCanonicalSources"
    layer['layer_type'] = "sc:layer"
    layer['label'] = "Sun of Faith Secondary/Tertiary Canonical Sources"
    layer['motivation'] = "[oa:commenting]"
    layer['description'] = "Sun of Faith Secondary/Tertiary Canonical Sources"
    layer['license'] = "http://creativecommons.org/licenses/by/4.0/"
    layer['version'] = " "
    createNewLayer layer
  end

  def makeCanonicalSourceLists
    #canvas = "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
    list = Hash.new
    #list['list_id'] = @ru + "/lists/CanonicalSources/_" + canvas
    list['list_id'] = @ru + "/lists/" + @ru + "/layers/CanonicalSources_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
    list['list_type'] = "sc:list"
    list['label'] = "Canonical Sources"
    list['description'] = "Canonical Sources"
    list['version'] = " "
    layer =   @ru + "/layers/CanonicalSources"
    withinArray = Array.new
    withinArray.push(layer)
    list['within'] = withinArray
    createNewList list

    list['list_id'] = @ru + "/lists/" + @ru + "/layers/CanonicalSources_http://manifests.ydc2.yale.edu/LOTB/canvas/panel_01"
    createNewList list
  end

  def makeSecondaryCanonicalSourceLists
    #canvas = "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
    list = Hash.new
    #list['list_id'] = @ru + "/lists/CanonicalSources/_" + canvas
    list['list_id'] = @ru + "/lists/" + @ru + "/layers/SecondaryCanonicalSources_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
    list['list_type'] = "sc:list"
    list['label'] = "Secondary/Tertiary Canonical Sources"
    list['description'] = "Secondary/Tertiary Canonical Sources"
    list['version'] = " "
    layer =   @ru + "/layers/Secondary/TertiaryCanonicalSources"
    withinArray = Array.new
    withinArray.push(layer)
    list['within'] = withinArray
    createNewList list

    list['list_id'] = @ru + "/lists/" + @ru + "/layers/SecondaryCanonicalSources_http://manifests.ydc2.yale.edu/LOTB/canvas/panel_01"
    createNewList list
  end

# not used
  def createNewPanel row
    layer = Hash.new
    layer['layer_id'] = @ru + "/layers/Panel_" + row[0]
    layer['layer_type'] = "sc:layer"
    layer['label'] = "Panel " + row[0]
    layer['motivation'] = "[oa:commenting]"
    layer['description'] = "Sun of Faith Panel " + row[0]
    layer['license'] = "http://creativecommons.org/licenses/by/4.0/"
    layer['version'] = " "
    createNewLayer layer
  end

=begin
  # new chapter is now handled as part of new scene
  def createNewChapter row
    # create the Chapter annotation (for svg) (no scene)
    annotation_id = @ru + "/annotations/Panel_" + row[0] + "_Chapter_" + row[1]
    newAnnotation = Hash.new
    newAnnotation['annotation_id'] = annotation_id
    newAnnotation['annotation_type'] = "oa:annotation"
    newAnnotation['motivation'] ="[oa:commenting]"
    #newAnnotation['resource'] = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + newAnnotation['annotation_id'] + '"}]'
    newAnnotation['resource'] = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + newAnnotation['annotation_id'] + '"},{"@type":"oa:Tag","chars":"chapter"'  + row[1] + "}]"

    newAnnotation['on'] = '{"@type": "oa:SpecificResource","full": "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11","selector": {"@type": "oa:SvgSelector","value": "'
    newAnnotation['on'] =  newAnnotation['on'] + row[12] unless row[12].nil?
    newAnnotation['on'] =  newAnnotation['on'] + '"}}'

    newAnnotation['description'] = "Panel: " + row[0] + " Chapter: " + row[1]
    newAnnotation['annotated_by'] = "annotator"
    newAnnotation['canvas']  = "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
    newAnnotation['manifest'] = "tbd"
    newAnnotation['active'] = true
    newAnnotation['version'] = 1
    #thisList = @ru + "/lists/Panel_" + row[0] + "_Chapters"# + row[1]
    #thisList = @ru + "/lists/Chapters/"
    thisList = @ru + "/lists/" + @ru + "/layers/Chapters_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"

    withinArray = Array.new
    withinArray.push(thisList)
    newAnnotation['within'] = withinArray
    createNewRenderingAnnotation newAnnotation
  end
=end

  def createNewScene row
    puts "**** row[1] = #{row[1]} ***"
    puts "**** row[1].to_i = #{row[1].to_i} ***"
    #if (row[1].to_i > 18)
    if (row[0] == "B")
      canvas = 'http://manifests.ydc2.yale.edu/LOTB/canvas/bv11'
    else
      canvas = 'http://manifests.ydc2.yale.edu/LOTB/canvas/panel_01'
    end
    puts "createNewScene: setting canvas to: #{canvas}"


    # create new list ChapterX_SceneY and attach to layer and Chapter_X
    scene = row[2]
    scene = "0" if (scene.nil?)

    p "in createScene: @ru = #{@ru}   row[0] = #{row[0]}  row[1] = #{row[1]}   scene = #{scene} row[12] = #{row[12]}"

    # create new annotation ChapterXSceneY (for svg) and attach to lists for ChapterX and ChapterXSceneY
    annotation_id = @ru + "/annotations/Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" + scene
    if (scene=="0")
      annotation_id = @ru + "/annotations/Panel_" + row[0] + "_Chapter_" + row[1]
    end
    newAnnotation = Hash.new
    newAnnotation['annotation_id'] = annotation_id
    newAnnotation['annotation_type'] = "oa:annotation"
    newAnnotation['motivation'] ="[oa:commenting]"
    #newAnnotation['resource'] = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + "Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" + scene + '"}]'
    newAnnotation['resource'] = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + "Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" + scene + '"},{"@type": "oa:Tag","chars":"chapter'  + row[1] + '"},{"@type": "oa:Tag","chars":"scene'  + scene + '"}]'

    if (scene=="0")
      #newAnnotation['resource'] = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + "Panel_" + row[0] + "_Chapter_" + row[1] + '"}]'
      newAnnotation['resource'] = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + "Panel_" + row[0] + "_Chapter_" + row[1] + '"},{"@type":"oa:Tag","chars":"chapter'  + row[1] + '"}]'
    end

    #newAnnotation['on'] = '{"@type": "oa:SpecificResource","full": "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11","selector": {"@type": "oa:SvgSelector","value": "<svg  xmlns=\'http://www.w3.org/2000/svg\'> </svg>"}}'

    newAnnotation['on'] = '{"@type": "oa:SpecificResource","full": "' + canvas + '","selector": {"@type": "oa:SvgSelector","value": "'
    newAnnotation['on'] =  newAnnotation['on'] + row[12] unless row[12].nil?
    newAnnotation['on'] =  newAnnotation['on'] + '"}}'
    p "********* ON = #{newAnnotation['on']}"

    #newAnnotation['on'] = JSON.parse(newAnnotation['on'])

    newAnnotation['description'] = "Panel: " + row[0] + " Chapter: " + row[1] + " Scene: " + scene
    newAnnotation['description'] = "Panel: " + row[0] + " Chapter: " + row[1] if (scene=="0")
    newAnnotation['annotated_by'] = "annotator"
    newAnnotation['canvas']  = canvas
    newAnnotation['manifest'] = "tbd"
    newAnnotation['active'] = true
    newAnnotation['version'] = 1
    #thisList = @ru + "/lists/Scenes/_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
    thisList = @ru + "/lists/" + @ru + "/layers/Scenes_" + canvas

    #thisList = @ru + "/lists/Chapters/_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11" if (scene=="0")
    thisList = @ru + "/lists/" + @ru + "/layers/Chapters_" + canvas  if (scene=="0")

    #chapterList = @ru + "/lists/Panel_" + row[0] + "_Chapter_" + row[1]
    withinArray = Array.new
    withinArray.push(thisList)
    #withinArray.push(chapterList)
    newAnnotation['within'] = withinArray
    createNewRenderingAnnotation newAnnotation
    #createNewRenderingAnnotation newAnnotation, withinArray
  end

  def createNewLayer layer
    layers = AnnotationLayer.where(layer_id: layer['layer_id']).first
    if (layers.nil?)
      @newLayer = AnnotationLayer.create(layer_id: layer['layer_id'], layer_type: layer['layer_type'], motivation: layer['motivation'],
                                         label:layer['label'], description:layer['description'], license: layer['license'], version: layer['version'])
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
  task :my_task, [:startFile, :endFile] do |t, args|
  #task :my_task , [:startFile, :endFile] => :environment do |t, args|
    puts "StartFile = #{args.startFile}"
    puts "EndFile = #{args.endFile}"
    for i in args.startFile..args.endFile
      chapterFilename = "lotb_ch#{i}.csv"
      puts "chapter file = #{chapterFilename}"
    end
  end

end










