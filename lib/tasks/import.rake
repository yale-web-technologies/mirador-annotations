namespace :import do

  desc "imports annotationList data from a csv file"
  task :annotationList => :environment do
    require 'csv'
    CSV.foreach('importData/AnnoList.csv') do |row|
      #id = row[0]
      list_id = row[1]
      list_type = row[2]
      resources = row[3]
      within = row[4]
      puts row.inspect
      puts "List_id: ",list_id,"Resources: ",resources, "Within", within
      @annotationList = AnnotationList.create(list_id: list_id, list_type: list_type, within: within, resources: resources)
      @annotationList.save!(options={validate: false})
      puts "annoList.within = ", @annotationList.within
    end
  end

  desc "imports annotationLayer data from a csv file"
  task :annotationLayer => :environment do
    @layer = AnnotationLayer.first
    #puts @layer.attribute_names
    require 'csv'
    CSV.foreach('importData/AnnoLayers.csv') do |row|
      #id = row[0]
      layer_id = row[1]
      layer_type = row[2]
      label = row[4]
      motivation = row[5]
      #description = row[6]
      license = row[7]
      othercontent = row[8]
      puts row.inspect
      puts "Layer_id: ",layer_id,"Label: ",label, "othercontent: ", othercontent
      @annotationLayer = AnnotationLayer.create(layer_id: layer_id, layer_type: layer_type, label: label, othercontent: othercontent, motivation: motivation, license: license)
      puts @annotationLayer.attribute_names.to_s
      puts @annotationLayer.attributes.to_s
      @annotationLayer.save!(options={validate: false})
      puts "annoLayer.othercontent = ", @annotationLayer.othercontent
      puts "annoLayer.label = ", @annotationLayer.label
    end
  end

  desc "imports annotation data from a csv file"
  task :annotations => :environment do
    require 'csv'
    CSV.foreach('importData/Annos.csv') do |row|
      id = row[0]
      annotation_id = row[1]
      annotation_type = row[2]
      on = row[3]
      canvas = row[4]
      motivation = row[6]
      resource = row[7]
      active = row[10]
      version = row[11]
      puts row.inspect
      puts "Id: ", id,"Annotation_id: ",annotation_id,"On: ",on, "Motivation", motivation, "Resource: ", resource
      @annotation = Annotation.create(annotation_id: annotation_id, annotation_type: annotation_type, on: on, canvas: canvas, motivation: motivation, active: active, version: version)
      result = @annotation.save!(options={validate: false})
      p 'save result: ' + result.to_s
      #puts "anno.motivation= ", @annotation.motivation
    end
  end



  desc "imports LoTB annotation data from a csv file"
  #Sun of Faith - Structured Chapters - ch. 26.csv normalized
  # Assumption: will be loaded by worksheet per chapter: first column holds panel, second column holds chapter, third column holds scene
  # Iterating through sheet needs to check for new scene, but not for new panel or chapter
  task :LoTB_annotations => :environment do
    require 'csv'
    #@ru = request.original_url.split('?').first
    #@ru += '/'   if !ru.end_with? '/'
    #@ru = "http://localhost:5000"
    @ru = "http://mirador-annotations-lotb-stg.herokuapp.com"
    labels = Array.new
    i = 0
    j=0
    panel = " "
    chapter = " "
    scene = " "
    lastScene = 0
    nextSceneSeq = 0
    makeLanguageLayers
    makeLanguageLists
    makeChaptersScenesLayers
    makeChaptersScenesLists
    makeCanonicalSourceLayer
    makeCanonicalSourceList
    CSV.foreach('importData/lotb26_norm.txt') do |row|
      i+=1;
      puts "i = #{i}"
      # store the labels from row 0
      #puts 'row.size = ' + row.size.to_s
      # First Row: set labels from column headings
      if (i==1)
        #while j < row.size
        while j <= 11
          labels[j] = row[j]
          puts "labels[#{j}] = #{labels[j]}"
          j += 1
        end
      else
        panel = row[0]
        chapter = row[1]
        # check for new Scene
        # this is to setup the new scene drawing annotation and initialize the nextSceneSeq num
        scene = row[2]
        scene = "0" if (scene.nil?)
        if (lastScene != scene)
          createNewScene row
          puts "just reset nextSceneSeq at i = #{i}: scene = #{scene} and lastScene = #{lastScene}"
          lastScene = scene
          nextSceneSeq = 0
        end
        nextSceneSeq += 1
        puts "nextSceneSeq = #{nextSceneSeq}"
#===================================================================================================================================================================

        # 1) create the Tibetan Sun of Faith transcription annotation for this row ([5]
        annotation_id = @ru + "/annotations/"+ "Panel_" + panel + "_Chapter_" + chapter + "_Scene_" + scene + "_" + nextSceneSeq.to_s + "_Tibetan_Sun_Of_Faith"
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
        canvas = on['full']
        manifest = "tbd"
        chars = row[5]
        #p "chars = " + chars.to_s
        resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"'
        resource += chars.to_s
        resource += '"}]'
        active = true
        version = 1
        @annotation = Annotation.create(annotation_id: annotation_id, annotation_type: annotation_type, motivation: motivation, label:label, on: on, canvas: canvas, manifest: manifest,  resource: resource, active: active, version: version)
        result = @annotation.save!(options={validate: false})
        #sceneList =  @ru + "/lists/Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" + scene
        languageList = @ru + "/lists/Tibetan"
        withinArray = Array.new
        #withinArray.push(sceneList)
        withinArray.push(languageList)
        ListAnnotationsMap.setMap withinArray, @annotation['annotation_id']
        #===================================================================================================================================================================
        # 2) create the Tibetan Inscription transcription annotation for this row ([7]
        unless row[7].nil?
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
          canvas = on['full']
          manifest = "tbd"
          chars = row[7]
          resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + chars+'"}]'
          active = true
          version = 1
          @annotation = Annotation.create(annotation_id: annotation_id, annotation_type: annotation_type, motivation: motivation, label:label, on: on, canvas: canvas, manifest: manifest,  resource: resource, active: active, version: version)
          result = @annotation.save!(options={validate: false})
          languageList = @ru + "/lists/Tibetan"
          withinArray = Array.new
          #withinArray.push(sceneList)
          withinArray.push(languageList)
          ListAnnotationsMap.setMap withinArray, @annotation['annotation_id']
        end
        #===================================================================================================================================================================
        # 3) create the Tibetan Manual transcription annotation for this row ([9]
        unless row[9].nil?
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
          canvas = on['full']
          manifest = "tbd"
          chars = row[9]
          resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + chars+'"}]'
          active = true
          version = 1
          @annotation = Annotation.create(annotation_id: annotation_id, annotation_type: annotation_type, motivation: motivation, label:label, on: on, canvas: canvas, manifest: manifest,  resource: resource, active: active, version: version)
          result = @annotation.save!(options={validate: false})
          languageList = @ru + "/lists/Tibetan"
          withinArray = Array.new
          #withinArray.push(sceneList)
          withinArray.push(languageList)
          ListAnnotationsMap.setMap withinArray, @annotation['annotation_id']
          end
        #===================================================================================================================================================================
        # 4) create the English Sun of Faith translation annotation for this row ([6]
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
        canvas = on['full']
        manifest = "tbd"
        chars = row[6]
        resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + chars+'"}]'
        active = true
        version = 1
        @annotation = Annotation.create(annotation_id: annotation_id, annotation_type: annotation_type, motivation: motivation, label:label, on: on, canvas: canvas, manifest: manifest,  resource: resource, active: active, version: version)
        result = @annotation.save!(options={validate: false})
        languageList = @ru + "/lists/English"
        withinArray = Array.new
        #withinArray.push(sceneList)
        withinArray.push(languageList)
        ListAnnotationsMap.setMap withinArray, @annotation['annotation_id']
        #===================================================================================================================================================================
        # 5) create the English Inscription annotation for this row ([8]
        unless row[8].nil?
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
          canvas = on['full']
          manifest = "tbd"
          chars = row[8]
          resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + chars+'"}]'
          active = true
          version = 1
          @annotation = Annotation.create(annotation_id: annotation_id, annotation_type: annotation_type, motivation: motivation, label:label, on: on, canvas: canvas, manifest: manifest,  resource: resource, active: active, version: version)
          result = @annotation.save!(options={validate: false})
          languageList = @ru + "/lists/English"
          withinArray = Array.new
          #withinArray.push(sceneList)
          withinArray.push(languageList)
          ListAnnotationsMap.setMap withinArray, @annotation['annotation_id']
        end
        #===================================================================================================================================================================
        # 6) create the English Manual annotation for this row ([10]
        unless row[10].nil?
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
          canvas = on['full']
          manifest = "tbd"
          chars = row[10]
          resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + chars+'"}]'
          active = true
          version = 1
          @annotation = Annotation.create(annotation_id: annotation_id, annotation_type: annotation_type, motivation: motivation, label:label, on: on, canvas: canvas, manifest: manifest,  resource: resource, active: active, version: version)
          result = @annotation.save!(options={validate: false})
          languageList = @ru + "/lists/English"
          withinArray = Array.new
          #withinArray.push(sceneList)
          withinArray.push(languageList)
          ListAnnotationsMap.setMap withinArray, @annotation['annotation_id']
        end
        #===================================================================================================================================================================
        # create the Canonical annotation for this row ([11]

        unless row[11].nil?
          annotation_id = @ru + "/annotations/"+ "Panel_" + panel + "_Chapter_" + chapter + "_Scene_" + scene + "_" + nextSceneSeq.to_s + "Canonical Source"
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
          canvas = "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
          canvas = on['full']
          manifest = "tbd"
          chars = row[11]
          resource = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + chars+'"}]'
          active = true
          version = 1
          @annotation = Annotation.create(annotation_id: annotation_id, annotation_type: annotation_type, motivation: motivation, label:label, on: on, canvas: canvas, manifest: manifest,  resource: resource, active: active, version: version)
          result = @annotation.save!(options={validate: false})
          #sceneList =  @ru + "/lists/Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" + scene
          #languageList = @ru + "/lists/Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" +scene + ":Tibetan"
          #list = @ru + "/lists/CanonicalSource"
          list = @ru + "/lists/CanonicalSources/_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
          withinArray = Array.new
          #withinArray.push(sceneList)
          withinArray.push(list)
          ListAnnotationsMap.setMap withinArray, @annotation['annotation_id']
         end

        #===================================================================================================================================================================
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

  def makeLanguageLists
    # create Tibetan and English lists for this scene
    list = Hash.new
    list['list_id'] = @ru + "/lists/Tibetan"
    list['list_type'] = "sc:list"
    list['label'] = "Tibetan"
    list['description'] = "Tibetan"
    list['version'] = " "
    languageLayer =   @ru + "/layers/Tibetan"
    withinArray = Array.new
    withinArray.push(languageLayer)
    list['within'] = withinArray
    createNewList list

    list = Hash.new
    list['list_id'] = @ru + "/lists/English"
    list['list_type'] = "sc:list"
    list['label'] = "English"
    list['description'] = "English"
    list['version'] = " "
    languageLayer =   @ru + "/layers/English"
    withinArray = Array.new
    withinArray.push(languageLayer)
    list['within'] = withinArray
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
    canvas = "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"

    list = Hash.new
    list['list_id'] = @ru + "/lists/Chapters/_" + canvas
    list['list_type'] = "sc:list"
    list['label'] = "Chapters"
    list['description'] = "Chapters"
    list['version'] = " "
    layer =   @ru + "/layers/Chapters"
    withinArray = Array.new
    withinArray.push(layer)
    list['within'] = withinArray
    createNewList list

    list = Hash.new
    list['list_id'] = @ru + "/lists/Scenes/_" + canvas
    list['list_type'] = "sc:list"
    list['label'] = "Scenes"
    list['description'] = "Scenes"
    list['version'] = " "
    layer =   @ru + "/layers/Scenes"
    withinArray = Array.new
    withinArray.push(layer)
    list['within'] = withinArray
    createNewList list
  end

  def makeCanonicalSourceLayer
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

  def makeCanonicalSourceList
    canvas = "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
    list = Hash.new
    list['list_id'] = @ru + "/lists/CanonicalSources/_" + canvas
    list['list_type'] = "sc:list"
    list['label'] = "Canonical Sources"
    list['description'] = "Canonical Sources"
    list['version'] = " "
    layer =   @ru + "/layers/CanonicalSources"
    withinArray = Array.new
    withinArray.push(layer)
    list['within'] = withinArray
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

  def createNewChapter row
=begin
    #create new layer, list and rendering annotation for new Chapter
    layer = Hash.new
    layer['layer_id'] = @ru + "/layers/Panel_" + row[0] + "_Chapter_" + row[1]
    layer['layer_type'] = "sc:layer"
    layer['motivation'] = "[oa:commenting]"
    layer['label'] = "Panel: " + row[0] + " Chapter: " + row[1]
    layer['description'] = "Sun of Faith Panel " + row[0]+ " Chapter: " + row[1]
    layer['license'] = "http://creativecommons.org/licenses/by/4.0/"
    layer['version'] = " "
    #createNewLayer layer

    list = Hash.new
    list['list_id'] = @ru + "/lists/Panel_" + row[0] + "_Chapter_" + row[1]
    list['list_type'] = "sc:list"
    list['label'] = "Panel: " + row[0] + " Chapter: " + row[1]
    list['description'] = "Panel: " + row[0] + " Chapter: " + row[1]
    list['version'] = " "
    panelLayer =  @ru + "/layers/Panel_" + row[0]
    thisLayer   = @ru + "/layers/Panel_" + row[0] + "_Chapter_" + row[1]
    withinArray = Array.new
    #withinArray.push(panelLayer)
    withinArray.push(thisLayer)
    list['within'] = withinArray
    #createNewList list
=end
    # create the Chapter annotation (for svg) (no scene)
    annotation_id = @ru + "/annotations/Panel_" + row[0] + "_Chapter_" + row[1]
    newAnnotation = Hash.new
    newAnnotation['annotation_id'] = annotation_id
    newAnnotation['annotation_type'] = "oa:annotation"
    newAnnotation['motivation'] ="[oa:commenting]"
    newAnnotation['resource'] = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + newAnnotation['annotation_id'] + '"}]'

    #newAnnotation['on'] = @ru + "/annotations/"+ "Panel_" + row[0] + "_Chapter_" + row[1]
    #newAnnotation['on'] = JSON.parse(newAnnotation['on'])
    newAnnotation['on'] = '{"@type":"oa:SpecificResource","full":"http://manifests.ydc2.yale.edu/LOTB/canvas/bv11","selector":{"@type":"oa:SvgSelector","value":"<svg >'
    newAnnotation['on'] += '<path xmlns=\"http://www.w3.org/2000/svg\"'
    newAnnotation['on'] += ' d=\"M1805.2536,2088.35484l61.85023,0l61.85023,0l0,287.42166l0,287.42166l-61.85023,0l-61.85023,0l0,-287.42166z\"'
    newAnnotation['on'] += ' data-paper-data=\"{&quot;rotation&quot;:0,&quot;annotation&quot;:null}\"'
    newAnnotation['on'] += ' id=\"rectangle_e0efece0-fe6e-438d-a2fd-384d5c281da6\" fill-opacity=\"0\"'
    newAnnotation['on'] += ' fill=\"#00bfff\"'
    newAnnotation['on'] += ' stroke=\"#00bfff\"'
    newAnnotation['on'] += ' stroke-width=\"7.2765\"'
    newAnnotation['on'] += ' stroke-linecap=\"butt\"'
    newAnnotation['on'] += ' stroke-linejoin=\"miter\"'
    newAnnotation['on'] += ' stroke-miterlimit=\"10\"'
    newAnnotation['on'] += ' stroke-dasharray=\"\"'
    newAnnotation['on'] += ' stroke-dashoffset=\"0\"'
    newAnnotation['on'] += ' font-family=\"sans-serif\"'
    newAnnotation['on'] += ' font-weight=\"normal\"'
    newAnnotation['on'] += ' font-size=\"12\"'
    newAnnotation['on'] += ' text-anchor=\"start\"'
    newAnnotation['on'] += ' mix-blend-mode=\"normal\"/></svg>>"}}'

    newAnnotation['description'] = "Panel: " + row[0] + " Chapter: " + row[1]
    newAnnotation['annotated_by'] = "annotator"
    newAnnotation['canvas']  = "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
    newAnnotation['manifest'] = "tbd"
    newAnnotation['active'] = true
    newAnnotation['version'] = 1
    #thisList = @ru + "/lists/Panel_" + row[0] + "_Chapters"# + row[1]
    thisList = @ru + "/lists/Chapters/"
    withinArray = Array.new
    withinArray.push(thisList)
    newAnnotation['within'] = withinArray
    createNewRenderingAnnotation newAnnotation
  end

  def createNewScene row

    # create new list ChapterX_SceneY and attach to layer and Chapter_X
    scene = row[2]
    scene = "0" if (scene.nil?)
=begin
    list = Hash.new
    #list['list_id'] = @ru + "/lists/Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" +scene
    list['list_id'] = @ru + "/lists/Scenes"

    list['list_type'] = "sc:list"
    list['label'] = "Panel:" + row[0] + " Chapter: " + row[1]
    list['description'] = "Sun of Faith Panel: " + row[0] + " Chapter: " + row[1] + " Scene: " +scene

    list['version'] = " "
    panelLayer =  @ru + "/layers/Panel_" + row[0]
    #thisLayer   = @ru + "/layers/Panel_" + row[0] + "_Chapter"# + row[1]
    thisLayer   = @ru + "/layers/Chapters"
    withinArray = Array.new
    #withinArray.push(panelLayer)
    withinArray.push(thisLayer)
    list['within'] = withinArray
    #createNewList list
=end

    # create new annotation ChapterXSceneY (for svg) and attach to lists for ChapterX and ChapterXSceneY
    annotation_id = @ru + "/annotations/Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" + scene
    if (scene=="0")
      annotation_id = @ru + "/annotations/Panel_" + row[0] + "_Chapter_" + row[1]
    end
    newAnnotation = Hash.new
    newAnnotation['annotation_id'] = annotation_id
    newAnnotation['annotation_type'] = "oa:annotation"
    newAnnotation['motivation'] ="[oa:commenting]"
    newAnnotation['resource'] = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + "Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" + scene + '"}]'
    if (scene=="0")
      newAnnotation['resource'] = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + "Panel_" + row[0] + "_Chapter_" + row[1] + '"}]'
    end

    newAnnotation['on'] = '{"@type": "oa:SpecificResource","full": "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11","selector": {"@type": "oa:SvgSelector","value": "<svg></svg>"}}'
    if (scene=="0")
      newAnnotation['on'] = '{"@type"=>"oa:SpecificResource", "full"=>"http://manifests.ydc2.yale.edu/LOTB/canvas/bv11", "selector"=>{"@type"=>"oa:SvgSelector", "value"=>"<svg xmlns=\'http://www.w3.org/2000/svg\'><path xmlns=\"http://www.w3.org/2000/svg\" d=\"M8523.67459,3171.28866c-214.81852,-104.43732 -519.18679,-165.44584 -823.43226,-165.41138c-304.24546,0.03445 -608.36812,61.11188 -823.43226,165.41138c-215.06414,104.29951 -341.06977,251.8211 -341.07681,399.3384c-0.00703,147.51731 125.98453,295.03033 341.07681,399.3384c215.09228,104.30808 522.72403,163.74025 823.43226,165.41138c300.70822,1.67113 606.45179,-60.20713 823.43226,-165.41138c216.98047,-105.20425 341.91271,-252.18349 341.07681,-399.3384c-0.8359,-147.15491 -126.25829,-294.90108 -341.07681,-399.3384z\" data-paper-data=\"{&quot;rotation&quot;:0,&quot;annotation&quot;:null}\" id=\"ellipse_06e8b769-13e7-4809-ab48-7a369924bcaa\" fill-opacity=\"0\" fill=\"#00bfff\" stroke=\"#00bfff\" stroke-width=\"15.50905\" stroke-linecap=\"butt\" stroke-linejoin=\"miter\" stroke-miterlimit=\"10\" stroke-dasharray=\"\" stroke-dashoffset=\"0\" font-family=\"sans-serif\" font-weight=\"normal\" font-size=\"12\" text-anchor=\"start\" mix-blend-mode=\"normal\"/></svg>"}}'
    end
    if (scene=="1")
      newAnnotation['on'] = '{"@type"=>"oa:SpecificResource", "full"=>"http://manifests.ydc2.yale.edu/LOTB/canvas/bv11", "selector"=>{"@type"=>"oa:SvgSelector", "value"=>"<svg xmlns=\'http://www.w3.org/2000/svg\'><path xmlns=\"http://www.w3.org/2000/svg\" d=\"M16076.25234,5410.92583c-32.4356,0 -38.9349,3.65616 -69.37084,-11.56181c-12.42857,-6.21428 -21.78372,-17.96293 -34.68542,-23.12361c-10.73487,-4.29395 -24.34423,5.1706 -34.68542,0c-4.87489,-2.43744 -6.21736,-10.49292 -11.56181,-11.56181c-15.11638,-3.02328 -30.95053,1.91209 -46.24723,0c-49.81012,-6.22627 -91.41777,-32.72611 -138.74169,-46.24723c-11.56181,-3.30337 -23.12361,1.65169 -34.68542,0c-23.20697,-3.31528 -46.04461,-9.22918 -69.37084,-11.56181c-15.33924,-1.53392 -30.83149,0 -46.24723,0c-26.97755,0 -53.9551,0 -80.93265,0c-73.22478,0 -146.44956,0 -219.67434,0c-42.39329,0 -84.78659,0 -127.17988,0c-15.41574,0 -30.98642,-2.18012 -46.24723,0c-12.06473,1.72353 -22.73487,9.1717 -34.68542,11.56181c-11.33728,2.26746 -23.23982,-1.63509 -34.68542,0c-23.20697,3.31528 -47.13126,4.14861 -69.37084,11.56181c-13.18249,4.39416 -21.20475,19.75345 -34.68542,23.12361c-18.69433,4.67358 -38.63499,-1.9174 -57.80904,0c-19.55377,1.95538 -38.42512,8.33115 -57.80904,11.56181c-7.603,1.26717 -16.22948,-3.44706 -23.12361,0c-12.42857,6.21428 -21.50293,18.72945 -34.68542,23.12361c-10.96849,3.65616 -24.77125,-5.9485 -34.68542,0c-11.91535,7.14921 -13.29797,24.85978 -23.12361,34.68542c-2.72514,2.72514 -7.90564,-1.21872 -11.56181,0c-8.17543,2.72514 -16.39435,6.1784 -23.12361,11.56181c-12.76788,10.2143 -20.66467,26.27297 -34.68542,34.68542c-6.60945,3.96567 -16.22948,-3.44706 -23.12361,0c-9.74977,4.87489 -14.40315,16.58327 -23.12361,23.12361c-6.89413,5.1706 -14.76325,9.47172 -23.12361,11.56181c-7.47773,1.86943 -15.81129,-2.43744 -23.12361,0c-5.1706,1.72353 -9.12436,6.68692 -11.56181,11.56181c-1.72353,3.44706 2.72514,8.83666 0,11.56181c-6.09361,6.09361 -18.3434,4.39148 -23.12361,11.56181c-4.27556,6.41334 3.44706,16.22948 0,23.12361c-8.70364,17.40728 -46.4131,40.71514 -57.80904,57.80904c-2.13778,3.20667 1.72353,8.11474 0,11.56181c-2.43744,4.87489 -9.12436,6.68692 -11.56181,11.56181c-5.45029,10.90058 -5.29154,24.23497 -11.56181,34.68542c-5.6083,9.34717 -16.58327,14.40315 -23.12361,23.12361c-10.34119,13.78826 -15.41574,30.83149 -23.12361,46.24723c-3.85394,7.70787 -9.47172,14.76325 -11.56181,23.12361c-2.84981,11.39925 0,55.69842 0,69.37084c0,7.70787 2.43744,15.81129 0,23.12361c-2.72514,8.17543 -8.83666,14.94818 -11.56181,23.12361c-1.21872,3.65616 0,7.70787 0,11.56181c0,19.26968 0,38.53936 0,57.80904c0,42.39329 0,84.78659 0,127.17988c0,24.34089 -3.33026,69.18261 0,92.49446c2.24721,15.73048 9.3146,30.51675 11.56181,46.24723c1.63509,11.44561 -3.65616,23.71693 0,34.68542c4.39416,13.18249 16.90933,22.25685 23.12361,34.68542c1.72353,3.44706 -2.72514,8.83666 0,11.56181c2.72514,2.72514 9.83827,-3.44706 11.56181,0c4.62472,9.24945 -4.62472,25.43598 0,34.68542c2.43744,4.87489 9.12436,6.68692 11.56181,11.56181c1.72353,3.44706 -1.21872,7.90564 0,11.56181c2.72514,8.17543 6.78159,15.95329 11.56181,23.12361c3.02328,4.53491 9.12436,6.68692 11.56181,11.56181c5.45029,10.90058 5.29154,24.23497 11.56181,34.68542c8.41245,14.02075 23.12361,23.12361 34.68542,34.68542c7.70787,7.70787 13.37384,18.24873 23.12361,23.12361c6.89413,3.44706 15.41574,0 23.12361,0c3.85394,0 8.83666,-2.72514 11.56181,0c6.09361,6.09361 5.4682,17.03001 11.56181,23.12361c6.09361,6.09361 14.76325,9.47172 23.12361,11.56181c7.47773,1.86943 15.96704,-2.86263 23.12361,0c12.90171,5.16068 21.50293,18.72945 34.68542,23.12361c10.96849,3.65616 23.39894,-2.50811 34.68542,0c23.794,5.28756 46.24723,15.41574 69.37084,23.12361c11.56181,3.85394 24.23497,5.29154 34.68542,11.56181c9.34717,5.6083 14.05379,17.07706 23.12361,23.12361c3.20667,2.13778 7.82294,-0.93472 11.56181,0c18.90804,4.72701 40.72204,12.87142 57.80904,23.12361c11.91535,7.14921 22.25685,16.90933 34.68542,23.12361c18.56301,9.28151 38.11999,16.5606 57.80904,23.12361c3.65616,1.21872 7.90564,-1.21872 11.56181,0c8.17543,2.72514 14.94818,8.83666 23.12361,11.56181c3.65616,1.21872 7.82294,-0.93472 11.56181,0c11.82334,2.95583 22.90971,8.42162 34.68542,11.56181c87.6179,23.36477 186.73712,49.16654 277.48338,57.80904c34.52918,3.28849 69.60842,-4.05269 104.05627,0c31.56269,3.71326 61.22671,17.43857 92.49446,23.12361c15.88545,2.88826 40.17312,0 57.80904,0c46.24723,0 92.49446,0 138.74169,0c154.15743,0 308.31486,0 462.47229,0c73.22478,0 146.44956,0 219.67434,0c30.83149,0 61.85155,3.40477 92.49446,0c45.80674,-5.08964 95.46041,-18.45494 138.74169,-34.68542c19.43265,-7.28724 38.11999,-16.5606 57.80904,-23.12361c15.07475,-5.02492 31.17248,-6.53689 46.24723,-11.56181c8.17543,-2.72514 14.94818,-8.83666 23.12361,-11.56181c3.65616,-1.21872 8.83666,2.72514 11.56181,0c2.72514,-2.72514 -1.72353,-8.11474 0,-11.56181c2.43744,-4.87489 7.70787,-7.70787 11.56181,-11.56181c3.85394,-3.85394 7.02689,-8.53853 11.56181,-11.56181c7.17033,-4.78022 15.95329,-6.78159 23.12361,-11.56181c13.60474,-9.06983 23.12361,-23.12361 34.68542,-34.68542c13.56419,-13.56419 36.4063,-31.48583 46.24723,-46.24723c4.78022,-7.17033 8.83666,-14.94818 11.56181,-23.12361c3.65616,-10.96849 -2.26746,-23.34814 0,-34.68542c4.78022,-23.9011 15.41574,-46.24723 23.12361,-69.37084c3.85394,-11.56181 8.60597,-22.86209 11.56181,-34.68542c0.93472,-3.73887 -1.21872,-7.90564 0,-11.56181c13.12603,-39.3781 31.67274,-76.75277 46.24723,-115.61807c4.27922,-11.41125 9.83827,-22.62069 11.56181,-34.68542c5.45029,-38.15202 -3.83481,-77.26998 0,-115.61807c1.58113,-15.81132 9.3146,-30.51675 11.56181,-46.24723c3.27017,-22.89121 0,-46.24723 0,-69.37084c0,-34.68542 0,-69.37084 0,-104.05627c0,-15.41574 0,-30.83149 0,-46.24723c0,-7.70787 0,-15.41574 0,-23.12361c0,-3.85394 1.21872,-7.90564 0,-11.56181c-2.72514,-8.17543 -8.83666,-14.94818 -11.56181,-23.12361c-1.21872,-3.65616 1.43132,-7.98352 0,-11.56181c-6.40104,-16.0026 -16.33429,-30.40547 -23.12361,-46.24723c-4.80078,-11.20182 -5.29154,-24.23497 -11.56181,-34.68542c-5.6083,-9.34717 -17.51531,-13.77645 -23.12361,-23.12361c-6.27027,-10.45045 -5.29154,-24.23497 -11.56181,-34.68542c-5.6083,-9.34717 -14.05379,-17.07706 -23.12361,-23.12361c-3.20667,-2.13778 -8.25708,1.98283 -11.56181,0c-5.38537,-3.23122 -50.36903,-42.44687 -69.37084,-46.24723c-11.33728,-2.26746 -23.34814,2.26746 -34.68542,0c-14.42102,-2.8842 -50.02627,-30.79404 -57.80904,-34.68542c-21.80115,-10.90058 -46.73975,-14.07118 -69.37084,-23.12361c-8.0013,-3.20052 -15.12232,-8.36129 -23.12361,-11.56181c-11.31555,-4.52622 -23.36988,-7.03559 -34.68542,-11.56181c-8.0013,-3.20052 -15.95329,-6.78159 -23.12361,-11.56181c-4.53491,-3.02328 -6.68692,-9.12436 -11.56181,-11.56181c-4.14547,-2.07273 -43.81824,0.347 -46.24723,0c-19.45379,-2.77911 -39.34088,-4.84611 -57.80904,-11.56181c-24.29647,-8.83508 -46.24723,-23.12361 -69.37084,-34.68542c-15.41574,-7.70787 -29.67505,-18.38871 -46.24723,-23.12361c-21.54256,-6.15502 -47.3489,4.40439 -69.37084,0c-15.58161,-3.11632 -30.47975,-9.59087 -46.24723,-11.56181c-30.5934,-3.82418 -61.90106,3.82418 -92.49446,0c-15.76748,-1.97093 -30.66562,-8.44549 -46.24723,-11.56181c-3.77909,-0.75582 -7.70787,0 -11.56181,0c-23.12361,0 -46.24723,0 -69.37084,0c-57.80904,0 -115.61807,0 -173.42711,0\" data-paper-data=\"{&quot;annotation&quot;:null}\" id=\"smooth_path_78bf8469-de4f-4b2a-ba80-bf87ffd7377f\" fill=\"none\" stroke=\"#00bfff\" stroke-width=\"11.56181\" stroke-linecap=\"butt\" stroke-linejoin=\"miter\" stroke-miterlimit=\"10\" stroke-dasharray=\"\" stroke-dashoffset=\"0\" font-family=\"sans-serif\" font-weight=\"normal\" font-size=\"12\" text-anchor=\"start\" mix-blend-mode=\"normal\"/></svg>"}}'
    end
    if (scene=="2")
      newAnnotation['on'] = '{"@type"=>"oa:SpecificResource", "full"=>"http://manifests.ydc2.yale.edu/LOTB/canvas/bv11", "selector"=>{"@type"=>"oa:SvgSelector", "value"=>"<svg xmlns=\'http://www.w3.org/2000/svg\'><path xmlns=\"http://www.w3.org/2000/svg\" d=\"M17782.26125,8020.68268c-17.1286,0 -34.25721,0 -51.38581,0c-8.5643,0 -17.74115,3.1807 -25.69291,0c-14.33523,-5.73409 -23.89215,-20.8105 -38.53936,-25.69291c-12.18722,-4.06241 -25.69291,0 -38.53936,0c-38.53936,0 -77.07872,0 -115.61807,0c-132.74668,0 -265.49335,0 -398.24003,0c-47.10366,0 -94.20732,0 -141.31098,0c-8.4415,0 -31.29141,-2.41598 -38.53936,0c-9.08381,3.02794 -16.40362,10.52413 -25.69291,12.84645c-12.46289,3.11572 -25.69291,0 -38.53936,0c-4.28215,0 -9.28349,-2.37531 -12.84645,0c-10.07759,6.71839 -15.61532,18.97451 -25.69291,25.69291c-3.56296,2.37531 -8.69216,-1.03857 -12.84645,0c-13.13704,3.28426 -25.40232,9.56219 -38.53936,12.84645c-4.1543,1.03857 -9.01638,-1.91504 -12.84645,0c-5.41654,2.70827 -7.42991,10.13818 -12.84645,12.84645c-3.83007,1.91504 -9.01638,-1.91504 -12.84645,0c-5.41654,2.70827 -7.80766,9.48726 -12.84645,12.84645c-7.96703,5.31135 -17.72587,7.5351 -25.69291,12.84645c-5.03879,3.3592 -10.13818,7.42991 -12.84645,12.84645c-1.91504,3.83007 3.02794,9.81851 0,12.84645c-3.02794,3.02794 -10.93142,-3.83007 -12.84645,0c-3.83007,7.66014 2.70827,17.5681 0,25.69291c-1.91504,5.74511 -9.48726,7.80766 -12.84645,12.84645c-5.31135,7.96703 -6.07578,18.92223 -12.84645,25.69291c-3.02794,3.02794 -9.81851,-3.02794 -12.84645,0c-6.77068,6.77068 -7.5351,17.72587 -12.84645,25.69291c-3.3592,5.03879 -10.13818,7.42991 -12.84645,12.84645c-1.91504,3.83007 1.91504,9.01638 0,12.84645c-6.90476,13.80952 -19.95881,24.20413 -25.69291,38.53936c-3.1807,7.95175 1.6796,17.29492 0,25.69291c-2.65568,13.27839 -9.56219,25.40232 -12.84645,38.53936c-2.73652,10.94609 0,27.2132 0,38.53936c0,34.25721 0,68.51441 0,102.77162c0,19.55787 -2.50206,87.75927 0,102.77162c1.57415,9.4449 9.81851,16.60909 12.84645,25.69291c1.35414,4.06241 -1.91504,9.01638 0,12.84645c2.70827,5.41654 10.13818,7.42991 12.84645,12.84645c1.91504,3.83007 -1.91504,9.01638 0,12.84645c2.70827,5.41654 11.37769,6.97139 12.84645,12.84645c3.11572,12.46289 -3.11572,26.07647 0,38.53936c1.46877,5.87506 10.13818,7.42991 12.84645,12.84645c3.83007,7.66014 -6.05588,19.63703 0,25.69291c6.77068,6.77068 18.92223,6.07578 25.69291,12.84645c6.77068,6.77068 6.07578,18.92223 12.84645,25.69291c6.77068,6.77068 18.03276,7.10134 25.69291,12.84645c14.5341,10.90058 23.42298,28.46177 38.53936,38.53936c7.96703,5.31135 18.92223,6.07578 25.69291,12.84645c6.77068,6.77068 4.87942,20.38155 12.84645,25.69291c7.12593,4.75062 18.56698,-4.75062 25.69291,0c7.96703,5.31135 6.07578,18.92223 12.84645,25.69291c6.77068,6.77068 16.40362,10.52413 25.69291,12.84645c8.30859,2.07715 18.03276,-3.83007 25.69291,0c10.83308,5.41654 15.30716,19.46146 25.69291,25.69291c11.61161,6.96697 27.70628,4.72164 38.53936,12.84645c7.66014,5.74511 7.5351,17.72587 12.84645,25.69291c9.03313,13.54969 45.36375,35.52833 51.38581,38.53936c3.83007,1.91504 8.78405,-1.35414 12.84645,0c9.08381,3.02794 17.72587,7.5351 25.69291,12.84645c5.03879,3.3592 7.10134,10.93142 12.84645,12.84645c8.12481,2.70827 17.29492,-1.6796 25.69291,0c13.27839,2.65568 26.09289,7.51225 38.53936,12.84645c52.80588,22.63109 101.99418,53.00337 154.15743,77.07872c20.93762,9.66352 43.15969,16.32732 64.23226,25.69291c17.49982,7.7777 33.21818,19.63703 51.38581,25.69291c12.18722,4.06241 26.61173,-4.77105 38.53936,0c48.04071,19.21628 91.85761,49.01584 141.31098,64.23226c24.89547,7.66014 51.65167,7.196 77.07872,12.84645c51.70597,11.49022 102.21874,28.15162 154.15743,38.53936c12.59698,2.5194 25.79211,-1.59341 38.53936,0c21.66616,2.70827 42.61694,9.75855 64.23226,12.84645c4.6749,0.66784 49.95737,-0.71422 51.38581,0c10.83308,5.41654 14.44743,21.19471 25.69291,25.69291c11.92763,4.77105 25.69291,0 38.53936,0c21.41075,0 43.46078,-5.19287 64.23226,0c5.87506,1.46877 6.97139,11.37769 12.84645,12.84645c12.46289,3.11572 25.69291,0 38.53936,0c17.1286,0 34.25721,0 51.38581,0c72.79656,0 145.59313,0 218.38969,0c149.87528,0 299.75056,0 449.62584,0c59.95011,0 119.90022,0 179.85034,0c19.85254,0 61.888,3.79768 77.07872,0c5.87506,-1.46877 6.97139,-11.37769 12.84645,-12.84645c20.77148,-5.19287 43.92024,6.77068 64.23226,0c5.74511,-1.91504 7.10134,-10.93142 12.84645,-12.84645c8.12481,-2.70827 17.5681,2.70827 25.69291,0c5.74511,-1.91504 7.10134,-10.93142 12.84645,-12.84645c8.12481,-2.70827 18.56698,4.75062 25.69291,0c7.96703,-5.31135 6.07578,-18.92223 12.84645,-25.69291c3.02794,-3.02794 8.5643,0 12.84645,0c8.5643,0 17.5681,2.70827 25.69291,0c5.74511,-1.91504 8.5643,-8.5643 12.84645,-12.84645c4.28215,-4.28215 10.93142,-7.10134 12.84645,-12.84645c1.9586,-5.8758 -2.85819,-45.66943 0,-51.38581c2.70827,-5.41654 10.13818,-7.42991 12.84645,-12.84645c3.83007,-7.66014 -6.05588,-19.63703 0,-25.69291c6.77068,-6.77068 20.38155,-4.87942 25.69291,-12.84645c7.12593,-10.68889 0,-25.69291 0,-38.53936c0,-25.69291 0,-51.38581 0,-77.07872c0,-8.5643 -2.70827,-17.5681 0,-25.69291c6.05588,-18.16763 20.4319,-32.97228 25.69291,-51.38581c3.52919,-12.35217 0,-25.69291 0,-38.53936c0,-12.84645 0,-25.69291 0,-38.53936c0,-29.97506 0,-59.95011 0,-89.92517c0,-17.1286 3.71572,-34.66509 0,-51.38581c-5.00244,-22.51096 -20.10001,-41.86069 -25.69291,-64.23226c-6.23144,-24.92578 4.22389,-51.73539 0,-77.07872c-2.22618,-13.35711 -6.79058,-26.42761 -12.84645,-38.53936c-6.90476,-13.80952 -19.95881,-24.20413 -25.69291,-38.53936c-3.1807,-7.95175 2.35279,-17.45812 0,-25.69291c-6.33509,-22.17283 -17.59597,-42.64043 -25.69291,-64.23226c-4.75469,-12.67916 -6.79058,-26.42761 -12.84645,-38.53936c-6.90476,-13.80952 -18.78814,-24.72984 -25.69291,-38.53936c-6.05588,-12.11175 -5.87949,-26.92775 -12.84645,-38.53936c-6.23144,-10.38574 -19.46146,-15.30716 -25.69291,-25.69291c-6.96697,-11.61161 -6.79058,-26.42761 -12.84645,-38.53936c-6.90476,-13.80952 -17.74934,-25.30008 -25.69291,-38.53936c-4.92639,-8.21065 -7.10134,-18.03276 -12.84645,-25.69291c-7.26705,-9.6894 -17.1286,-17.1286 -25.69291,-25.69291c-21.41075,-21.41075 -42.82151,-42.82151 -64.23226,-64.23226c-21.41075,-21.41075 -42.82151,-42.82151 -64.23226,-64.23226c-8.5643,-8.5643 -16.0035,-18.42585 -25.69291,-25.69291c-7.66014,-5.74511 -17.48226,-7.92006 -25.69291,-12.84645c-13.23927,-7.94356 -24.72984,-18.78814 -38.53936,-25.69291c-12.11175,-6.05588 -26.16512,-7.34679 -38.53936,-12.84645c-26.24973,-11.66655 -50.67578,-27.22381 -77.07872,-38.53936c-3.93592,-1.68682 -9.28349,2.37531 -12.84645,0c-10.07759,-6.71839 -15.61532,-18.97451 -25.69291,-25.69291c-3.56296,-2.37531 -8.5643,0 -12.84645,0c-4.28215,0 -8.5643,0 -12.84645,0c-25.69291,0 -51.38581,0 -77.07872,0c-77.07872,0 -154.15743,0 -231.23615,0c-42.82151,0 -85.64302,0 -128.46453,0c-25.69291,0 -52.15294,-6.23144 -77.07872,0c-11.75013,2.93753 -14.85983,20.27637 -25.69291,25.69291c-29.8472,14.9236 -48.20807,12.84645 -77.07872,12.84645c-8.5643,0 -17.5681,-2.70827 -25.69291,0c-5.74511,1.91504 -7.10134,10.93142 -12.84645,12.84645c-15.41574,5.13858 -35.97007,-5.13858 -51.38581,0c-9.08381,3.02794 -16.60909,9.81851 -25.69291,12.84645c-8.12481,2.70827 -17.1286,0 -25.69291,0c-25.69291,0 -51.38581,0 -77.07872,0c-12.84645,0 -25.69291,0 -38.53936,0c-4.28215,0 -9.81851,-3.02794 -12.84645,0c-3.02794,3.02794 3.83007,10.93142 0,12.84645c-7.66014,3.83007 -17.1286,0 -25.69291,0c-19.29238,0 -47.20958,-3.40454 -64.23226,0c-9.38924,1.87785 -16.60909,9.81851 -25.69291,12.84645c-8.83621,2.9454 -30.95969,-3.78983 -38.53936,0c-5.41654,2.70827 -7.10134,10.93142 -12.84645,12.84645c-8.12481,2.70827 -17.1286,0 -25.69291,0c-8.5643,0 -17.1286,0 -25.69291,0c-29.97506,0 -59.95011,0 -89.92517,0\" data-paper-data=\"{&quot;annotation&quot;:null}\" id=\"smooth_path_85b54151-6ce9-4fe9-9684-dc84966b4b88\" fill=\"none\" stroke=\"#00bfff\" stroke-width=\"12.84645\" stroke-linecap=\"butt\" stroke-linejoin=\"miter\" stroke-miterlimit=\"10\" stroke-dasharray=\"\" stroke-dashoffset=\"0\" font-family=\"sans-serif\" font-weight=\"normal\" font-size=\"12\" text-anchor=\"start\" mix-blend-mode=\"normal\"/></svg>"}}'
    end
    if (scene=="3")
      newAnnotation['on'] = ' {"@type"=>"oa:SpecificResource", "full"=>"http://manifests.ydc2.yale.edu/LOTB/canvas/bv11", "selector"=>{"@type"=>"oa:SvgSelector", "value"=>"<svg xmlns=\'http://www.w3.org/2000/svg\'><path xmlns=\"http://www.w3.org/2000/svg\" d=\"M18270.42645,7481.13167c-46.75621,0 -63.53737,6.77068 -102.77162,-12.84645c-5.41654,-2.70827 -7.10134,-10.93142 -12.84645,-12.84645c-12.18722,-4.06241 -25.69291,0 -38.53936,0c-4.28215,0 -9.81851,3.02794 -12.84645,0c-6.77068,-6.77068 -6.07578,-18.92223 -12.84645,-25.69291c-3.02794,-3.02794 -8.5643,0 -12.84645,0c-4.28215,0 -8.5643,0 -12.84645,0c-21.41075,0 -42.82151,0 -64.23226,0c-94.20732,0 -188.41464,0 -282.62196,0c-81.36087,0 -162.72173,0 -244.0826,0c-37.21634,0 -79.26965,-4.03871 -115.61807,0c-16.86652,1.87406 -71.18682,18.19757 -89.92517,25.69291c-8.89033,3.55613 -16.60909,9.81851 -25.69291,12.84645c-4.06241,1.35414 -9.01638,-1.91504 -12.84645,0c-10.83308,5.41654 -14.85983,20.27637 -25.69291,25.69291c-3.83007,1.91504 -9.01638,-1.91504 -12.84645,0c-5.41654,2.70827 -7.10134,10.93142 -12.84645,12.84645c-8.12481,2.70827 -18.56698,-4.75062 -25.69291,0c-14.76149,9.84099 -12.84645,24.91978 -12.84645,38.53936c0,4.28215 3.83007,10.93142 0,12.84645c-7.66014,3.83007 -18.03276,-3.83007 -25.69291,0c-3.83007,1.91504 1.03857,8.69216 0,12.84645c-3.28426,13.13704 -10.19078,25.26097 -12.84645,38.53936c-1.6796,8.39799 2.70827,17.5681 0,25.69291c-1.91504,5.74511 -10.13818,7.42991 -12.84645,12.84645c-1.95481,3.90961 0,32.75386 0,38.53936c0,29.97506 0,59.95011 0,89.92517c0,12.84645 0,25.69291 0,38.53936c0,8.5643 -2.70827,17.5681 0,25.69291c1.91504,5.74511 10.93142,7.10134 12.84645,12.84645c2.70827,8.12481 -2.70827,17.5681 0,25.69291c1.91504,5.74511 10.93142,7.10134 12.84645,12.84645c3.85394,11.56181 -3.85394,26.97755 0,38.53936c3.02794,9.08381 6.07578,18.92223 12.84645,25.69291c3.02794,3.02794 9.81851,-3.02794 12.84645,0c6.77068,6.77068 6.86488,18.21595 12.84645,25.69291c11.34923,14.18653 23.42298,28.46177 38.53936,38.53936c11.26708,7.51139 26.42761,6.79058 38.53936,12.84645c13.80952,6.90476 25.30008,17.74934 38.53936,25.69291c8.21065,4.92639 17.72587,7.5351 25.69291,12.84645c5.03879,3.3592 7.10134,10.93142 12.84645,12.84645c8.12481,2.70827 18.03276,-3.83007 25.69291,0c10.83308,5.41654 14.04717,22.36555 25.69291,25.69291c20.58695,5.88199 43.0367,-3.02794 64.23226,0c39.08269,5.58324 76.81479,18.41729 115.61807,25.69291c29.76076,5.58014 59.75038,10.33189 89.92517,12.84645c36.58449,3.04871 78.11504,0 115.61807,0c29.97506,0 60.18158,-3.71795 89.92517,0c13.43678,1.6796 25.40232,9.56219 38.53936,12.84645c10.94609,2.73652 27.2132,0 38.53936,0c25.69291,0 51.38581,0 77.07872,0c12.84645,0 25.82202,-1.81676 38.53936,0c17.47831,2.4969 33.97028,9.94386 51.38581,12.84645c8.44778,1.40796 17.1286,0 25.69291,0c34.25721,0 68.51441,0 102.77162,0c85.64302,0 171.28603,0 256.92905,0c38.53936,0 77.07872,0 115.61807,0c8.5643,0 17.1286,0 25.69291,0c4.28215,0 9.81851,3.02794 12.84645,0c3.02794,-3.02794 -3.02794,-9.81851 0,-12.84645c3.02794,-3.02794 9.01638,1.91504 12.84645,0c5.41654,-2.70827 7.42991,-10.13818 12.84645,-12.84645c3.83007,-1.91504 9.01638,1.91504 12.84645,0c5.41654,-2.70827 7.42991,-10.13818 12.84645,-12.84645c12.11175,-6.05588 25.40232,-9.56219 38.53936,-12.84645c4.1543,-1.03857 10.93142,3.83007 12.84645,0c3.83007,-7.66014 -3.83007,-18.03276 0,-25.69291c1.91504,-3.83007 8.5643,0 12.84645,0c8.5643,0 18.03276,3.83007 25.69291,0c3.83007,-1.91504 -3.02794,-9.81851 0,-12.84645c3.02794,-3.02794 9.81851,3.02794 12.84645,0c3.02794,-3.02794 -1.91504,-9.01638 0,-12.84645c2.70827,-5.41654 10.13818,-7.42991 12.84645,-12.84645c1.91504,-3.83007 -1.91504,-9.01638 0,-12.84645c2.70827,-5.41654 10.13818,-7.42991 12.84645,-12.84645c1.91504,-3.83007 0,-8.5643 0,-12.84645c0,-12.84645 0,-25.69291 0,-38.53936c0,-4.28215 -3.02794,-9.81851 0,-12.84645c3.02794,-3.02794 10.93142,3.83007 12.84645,0c3.83007,-7.66014 0,-17.1286 0,-25.69291c0,-25.69291 0,-51.38581 0,-77.07872c0,-38.53936 0,-77.07872 0,-115.61807c0,-10.34185 2.68771,-43.32269 0,-51.38581c-3.02794,-9.08381 -9.81851,-16.60909 -12.84645,-25.69291c-4.06241,-12.18722 3.11572,-26.07647 0,-38.53936c-3.23397,-12.93589 -24.9355,-44.58388 -38.53936,-51.38581c-3.83007,-1.91504 -10.93142,3.83007 -12.84645,0c-3.83007,-7.66014 2.70827,-17.5681 0,-25.69291c-1.91504,-5.74511 -7.42991,-10.13818 -12.84645,-12.84645c-3.83007,-1.91504 -9.01638,1.91504 -12.84645,0c-5.41654,-2.70827 -8.5643,-8.5643 -12.84645,-12.84645c-8.5643,-8.5643 -15.61532,-18.97451 -25.69291,-25.69291c-3.56296,-2.37531 -8.78405,1.35414 -12.84645,0c-18.16763,-6.05588 -33.21818,-19.63703 -51.38581,-25.69291c-4.06241,-1.35414 -8.5643,0 -12.84645,0c-17.41165,0 -50.11749,3.52869 -64.23226,0c-13.13704,-3.28426 -25.18225,-10.62027 -38.53936,-12.84645c-18.15991,-3.02665 -44.39088,0 -64.23226,0c-154.15743,0 -308.31486,0 -462.47229,0\" data-paper-data=\"{&quot;annotation&quot;:null}\" id=\"smooth_path_fbcfeb92-49bd-49cb-924d-d9995e91ecc5\" fill=\"none\" stroke=\"#00bfff\" stroke-width=\"12.84645\" stroke-linecap=\"butt\" stroke-linejoin=\"miter\" stroke-miterlimit=\"10\" stroke-dasharray=\"\" stroke-dashoffset=\"0\" font-family=\"sans-serif\" font-weight=\"normal\" font-size=\"12\" text-anchor=\"start\" mix-blend-mode=\"normal\"/></svg>"}}'
    end
    if (scene=="4")
      newAnnotation['on'] = ' {"@type"=>"oa:SpecificResource", "full"=>"http://manifests.ydc2.yale.edu/LOTB/canvas/bv11", "selector"=>{"@type"=>"oa:SvgSelector", "value"=>"<svg xmlns=\'http://www.w3.org/2000/svg\'><path xmlns=\"http://www.w3.org/2000/svg\" d=\"M14654.15004,6428.36488c-19.26968,0 -38.53936,0 -57.80904,0c-7.70787,0 -15.41574,0 -23.12361,0c-3.85394,0 -8.35514,-2.13778 -11.56181,0c-9.06983,6.04655 -13.37384,18.24873 -23.12361,23.12361c-6.89413,3.44706 -15.41574,0 -23.12361,0c-16.44869,0 -43.69471,-3.52858 -57.80904,0c-11.82334,2.95583 -22.86209,8.60597 -34.68542,11.56181c-14.04424,3.51106 -31.65439,0 -46.24723,0c-7.70787,0 -15.96704,-2.86263 -23.12361,0c-12.90171,5.16068 -21.50293,18.72945 -34.68542,23.12361c-17.34271,5.7809 -40.46633,-5.7809 -57.80904,0c-5.1706,1.72353 -6.39121,9.83827 -11.56181,11.56181c-10.40563,3.46854 -24.2798,-3.46854 -34.68542,0c-8.17543,2.72514 -14.6733,9.87174 -23.12361,11.56181c-11.33728,2.26746 -23.12361,0 -34.68542,0c-3.85394,0 -8.83666,-2.72514 -11.56181,0c-6.09361,6.09361 -5.4682,17.03001 -11.56181,23.12361c-2.72514,2.72514 -7.70787,0 -11.56181,0c-15.41574,0 -30.83149,0 -46.24723,0c-3.85394,0 -7.90564,-1.21872 -11.56181,0c-16.35086,5.45029 -29.89636,17.67333 -46.24723,23.12361c-3.65616,1.21872 -7.90564,-1.21872 -11.56181,0c-8.17543,2.72514 -15.95329,6.78159 -23.12361,11.56181c-13.34055,8.8937 -21.34488,25.79172 -34.68542,34.68542c-6.41334,4.27556 -17.67333,-5.45029 -23.12361,0c-2.72514,2.72514 2.72514,8.83666 0,11.56181c-2.72514,2.72514 -8.11474,-1.72353 -11.56181,0c-4.87489,2.43744 -6.39121,9.83827 -11.56181,11.56181c-7.31233,2.43744 -16.71028,-4.27556 -23.12361,0c-7.17033,4.78022 -5.4682,17.03001 -11.56181,23.12361c-6.09361,6.09361 -17.03001,5.4682 -23.12361,11.56181c-2.72514,2.72514 2.72514,8.83666 0,11.56181c-2.72514,2.72514 -8.83666,-2.72514 -11.56181,0c-2.72514,2.72514 1.72353,8.11474 0,11.56181c-2.43744,4.87489 -8.29163,7.20158 -11.56181,11.56181c-8.33734,11.11645 -17.96293,21.78372 -23.12361,34.68542c-2.86263,7.15658 4.27556,16.71028 0,23.12361c-4.78022,7.17033 -17.03001,5.4682 -23.12361,11.56181c-14.37624,14.37624 -11.56181,29.07025 -11.56181,46.24723c0,7.70787 4.27556,16.71028 0,23.12361c-6.04655,9.06983 -17.07706,14.05379 -23.12361,23.12361c-2.13778,3.20667 0,7.70787 0,11.56181c0,7.70787 0,15.41574 0,23.12361c0,3.85394 2.72514,8.83666 0,11.56181c-6.09361,6.09361 -18.3434,4.39148 -23.12361,11.56181c-7.70787,11.56181 3.85394,23.12361 0,34.68542c-2.72514,8.17543 -8.83666,14.94818 -11.56181,23.12361c-1.21872,3.65616 0,7.70787 0,11.56181c0,23.12361 0,46.24723 0,69.37084c0,69.37084 0,138.74169 0,208.11253c0,19.26968 0,38.53936 0,57.80904c0,3.85394 2.72514,8.83666 0,11.56181c-2.72514,2.72514 -9.83827,-3.44706 -11.56181,0c-3.44706,6.89413 0,15.41574 0,23.12361c0,15.41574 0,30.83149 0,46.24723c0,26.97755 0,53.9551 0,80.93265c0,5.20695 -1.75933,31.16677 0,34.68542c2.43744,4.87489 9.83827,6.39121 11.56181,11.56181c2.43744,7.31233 -1.51164,15.56542 0,23.12361c2.39011,11.95055 6.11152,23.78485 11.56181,34.68542c6.21428,12.42857 16.90933,22.25685 23.12361,34.68542c1.72353,3.44706 -2.31236,8.47866 0,11.56181c13.08069,17.44092 30.83149,30.83149 46.24723,46.24723c3.85394,3.85394 9.12436,6.68692 11.56181,11.56181c1.72353,3.44706 -1.72353,8.11474 0,11.56181c2.43744,4.87489 6.39121,9.83827 11.56181,11.56181c7.31233,2.43744 16.22948,-3.44706 23.12361,0c17.23532,8.61766 29.51646,25.12498 46.24723,34.68542c10.53539,6.02022 46.6424,11.95698 57.80904,23.12361c6.09361,6.09361 5.4682,17.03001 11.56181,23.12361c2.72514,2.72514 7.70787,0 11.56181,0c11.56181,0 23.46882,-2.80415 34.68542,0c8.36036,2.09009 15.05465,8.53594 23.12361,11.56181c22.82249,8.55843 45.53747,18.01646 69.37084,23.12361c30.38171,6.51037 61.502,9.34806 92.49446,11.56181c23.06485,1.64749 46.38866,-2.55358 69.37084,0c12.11267,1.34585 22.73487,9.1717 34.68542,11.56181c25.76024,5.15205 55.07294,-4.30995 80.93265,0c12.02139,2.00357 22.59232,10.05017 34.68542,11.56181c19.12088,2.39011 38.53936,0 57.80904,0c34.68542,0 69.37084,0 104.05627,0c61.66297,0 123.32594,0 184.98892,0c19.26968,0 38.53936,0 57.80904,0c7.70787,0 16.22948,3.44706 23.12361,0c3.44706,-1.72353 -3.44706,-9.83827 0,-11.56181c2.71877,-1.35939 38.65202,0 46.24723,0c3.85394,0 8.83666,2.72514 11.56181,0c2.72514,-2.72514 -3.44706,-9.83827 0,-11.56181c9.24945,-4.62472 25.43598,4.62472 34.68542,0c4.87489,-2.43744 6.39121,-9.83827 11.56181,-11.56181c7.31233,-2.43744 16.71028,4.27556 23.12361,0c7.17033,-4.78022 5.4682,-17.03001 11.56181,-23.12361c2.72514,-2.72514 8.11474,1.72353 11.56181,0c4.87489,-2.43744 6.68692,-9.12436 11.56181,-11.56181c3.44706,-1.72353 8.11474,1.72353 11.56181,0c4.87489,-2.43744 6.68692,-9.12436 11.56181,-11.56181c3.44706,-1.72353 8.11474,1.72353 11.56181,0c4.87489,-2.43744 6.68692,-9.12436 11.56181,-11.56181c3.44706,-1.72353 8.83666,2.72514 11.56181,0c2.72514,-2.72514 -2.72514,-8.83666 0,-11.56181c2.72514,-2.72514 8.83666,2.72514 11.56181,0c2.72514,-2.72514 -2.72514,-8.83666 0,-11.56181c5.45029,-5.45029 17.67333,5.45029 23.12361,0c2.72514,-2.72514 -2.72514,-8.83666 0,-11.56181c2.72514,-2.72514 7.90564,1.21872 11.56181,0c8.17543,-2.72514 17.03001,-5.4682 23.12361,-11.56181c2.72514,-2.72514 -2.13778,-8.35514 0,-11.56181c6.04655,-9.06983 17.07706,-14.05379 23.12361,-23.12361c2.13778,-3.20667 -2.72514,-8.83666 0,-11.56181c2.72514,-2.72514 8.83666,2.72514 11.56181,0c2.72514,-2.72514 -3.44706,-9.83827 0,-11.56181c6.89413,-3.44706 15.81129,2.43744 23.12361,0c5.1706,-1.72353 9.12436,-6.68692 11.56181,-11.56181c1.72353,-3.44706 -2.72514,-8.83666 0,-11.56181c2.72514,-2.72514 9.83827,3.44706 11.56181,0c6.89413,-13.78826 -6.89413,-32.45897 0,-46.24723c1.72353,-3.44706 9.83827,3.44706 11.56181,0c3.44706,-6.89413 -3.44706,-16.22948 0,-23.12361c1.72353,-3.44706 8.83666,2.72514 11.56181,0c5.45029,-5.45029 -5.45029,-17.67333 0,-23.12361c2.72514,-2.72514 8.83666,2.72514 11.56181,0c5.45029,-5.45029 -4.27556,-16.71028 0,-23.12361c6.04655,-9.06983 17.07706,-14.05379 23.12361,-23.12361c2.13778,-3.20667 -1.21872,-7.90564 0,-11.56181c2.72514,-8.17543 8.83666,-14.94818 11.56181,-23.12361c2.43744,-7.31233 -4.27556,-16.71028 0,-23.12361c6.04655,-9.06983 18.24873,-13.37384 23.12361,-23.12361c3.44706,-6.89413 -1.86943,-15.64588 0,-23.12361c2.09009,-8.36036 9.47172,-14.76325 11.56181,-23.12361c1.4082,-5.63282 -3.05678,-40.13366 0,-46.24723c2.43744,-4.87489 9.83827,-6.39121 11.56181,-11.56181c2.43744,-7.31233 0,-15.41574 0,-23.12361c0,-11.56181 0,-23.12361 0,-34.68542c0,-3.85394 -1.72353,-8.11474 0,-11.56181c2.43744,-4.87489 9.12436,-6.68692 11.56181,-11.56181c1.72353,-3.44706 0,-7.70787 0,-11.56181c0,-3.9388 -2.08577,-39.98991 0,-46.24723c2.72514,-8.17543 8.83666,-14.94818 11.56181,-23.12361c2.14626,-6.43879 -2.97253,-30.22662 0,-34.68542c6.04655,-9.06983 17.07706,-14.05379 23.12361,-23.12361c2.13778,-3.20667 0,-7.70787 0,-11.56181c0,-19.26968 0,-38.53936 0,-57.80904c0,-38.53936 0,-77.07872 0,-115.61807c0,-19.26968 0,-38.53936 0,-57.80904c0,-3.85394 1.21872,-7.90564 0,-11.56181c0,0 -23.12361,-46.24723 -23.12361,-46.24723c-1.17544,-2.9386 -22.75798,-68.88332 -23.12361,-69.37084c-5.1706,-6.89413 -17.95302,-4.66768 -23.12361,-11.56181c-7.31233,-9.74977 -6.11152,-23.78485 -11.56181,-34.68542c-6.21428,-12.42857 -15.97441,-22.77007 -23.12361,-34.68542c-4.43375,-7.38958 -6.39121,-16.22948 -11.56181,-23.12361c-6.54035,-8.72046 -16.58327,-14.40315 -23.12361,-23.12361c-5.1706,-6.89413 -5.4682,-17.03001 -11.56181,-23.12361c-2.72514,-2.72514 -8.11474,1.72353 -11.56181,0c-4.87489,-2.43744 -8.53853,-7.02689 -11.56181,-11.56181c-4.78022,-7.17033 -5.4682,-17.03001 -11.56181,-23.12361c-2.72514,-2.72514 -7.90564,1.21872 -11.56181,0c-8.17543,-2.72514 -17.03001,-5.4682 -23.12361,-11.56181c-6.09361,-6.09361 -5.4682,-17.03001 -11.56181,-23.12361c-6.09361,-6.09361 -15.73403,-7.12806 -23.12361,-11.56181c-11.91535,-7.14921 -23.56897,-14.78628 -34.68542,-23.12361c-4.36023,-3.27017 -6.39121,-9.83827 -11.56181,-11.56181c-7.31233,-2.43744 -15.81129,2.43744 -23.12361,0c-5.1706,-1.72353 -6.68692,-9.12436 -11.56181,-11.56181c-3.44706,-1.72353 -8.83666,2.72514 -11.56181,0c-2.72514,-2.72514 2.72514,-8.83666 0,-11.56181c-2.72514,-2.72514 -7.70787,0 -11.56181,0c-7.70787,0 -15.81129,2.43744 -23.12361,0c-5.1706,-1.72353 -6.68692,-9.12436 -11.56181,-11.56181c-3.51865,-1.75933 -29.47847,0 -34.68542,0c-23.12361,0 -46.24723,0 -69.37084,0c-96.34839,0 -192.69679,0 -289.04518,0\" data-paper-data=\"{&quot;annotation&quot;:null}\" id=\"smooth_path_72102c9b-27ce-454e-973a-937d0401fd1e\" fill=\"none\" stroke=\"#00bfff\" stroke-width=\"11.56181\" stroke-linecap=\"butt\" stroke-linejoin=\"miter\" stroke-miterlimit=\"10\" stroke-dasharray=\"\" stroke-dashoffset=\"0\" font-family=\"sans-serif\" font-weight=\"normal\" font-size=\"12\" text-anchor=\"start\" mix-blend-mode=\"normal\"/></svg>"}}'
          end
    if (scene=="5")
      newAnnotation['on'] = '{"@type"=>"oa:SpecificResource", "full"=>"http://manifests.ydc2.yale.edu/LOTB/canvas/bv11", "selector"=>{"@type"=>"oa:SvgSelector", "value"=>"<svg xmlns=\'http://www.w3.org/2000/svg\'><path xmlns=\"http://www.w3.org/2000/svg\" d=\"M16145.62319,6705.84825c-104.05627,0 -208.11253,0 -312.1688,0c-84.78659,0 -169.57317,0 -254.35976,0c-57.80904,0 -115.61807,0 -173.42711,0c-30.83149,0 -61.74132,-2.19665 -92.49446,0c-23.383,1.67021 -46.07165,8.97301 -69.37084,11.56181c-22.16555,2.46284 -46.85151,0 -69.37084,0c-11.56181,0 -23.46882,-2.80415 -34.68542,0c-5.28756,1.32189 -7.02689,8.53853 -11.56181,11.56181c-7.17033,4.78022 -15.95329,6.78159 -23.12361,11.56181c-4.53491,3.02328 -7.02689,8.53853 -11.56181,11.56181c-7.17033,4.78022 -15.95329,6.78159 -23.12361,11.56181c-4.53491,3.02328 -6.39121,9.83827 -11.56181,11.56181c-7.31233,2.43744 -15.41574,0 -23.12361,0c-3.85394,0 -8.83666,-2.72514 -11.56181,0c-2.72514,2.72514 2.13778,8.35514 0,11.56181c-6.04655,9.06983 -14.05379,17.07706 -23.12361,23.12361c-3.20667,2.13778 -8.83666,-2.72514 -11.56181,0c-6.09361,6.09361 -6.78159,15.95329 -11.56181,23.12361c-10.25565,15.38348 -35.40753,23.84572 -46.24723,34.68542c-25.98678,25.98678 -22.14742,38.02585 -34.68542,69.37084c-3.20052,8.0013 -8.83666,14.94818 -11.56181,23.12361c-1.21872,3.65616 0,7.70787 0,11.56181c0,7.70787 0,15.41574 0,23.12361c0,26.97755 0,53.9551 0,80.93265c0,42.27861 -7.88372,99.85063 11.56181,138.74169c2.43744,4.87489 7.02689,8.53853 11.56181,11.56181c7.17033,4.78022 18.3434,4.39148 23.12361,11.56181c6.41334,9.62001 -5.1706,24.34423 0,34.68542c6.21428,12.42857 14.78628,23.56897 23.12361,34.68542c9.81052,13.08069 21.60473,24.8749 34.68542,34.68542c6.89413,5.1706 15.95329,6.78159 23.12361,11.56181c15.38348,10.25565 23.84572,35.40753 34.68542,46.24723c2.72514,2.72514 9.83827,-3.44706 11.56181,0c3.44706,6.89413 -5.45029,17.67333 0,23.12361c8.61766,8.61766 26.06776,2.94414 34.68542,11.56181c8.61766,8.61766 4.24948,24.93565 11.56181,34.68542c5.1706,6.89413 16.39435,6.1784 23.12361,11.56181c12.76788,10.2143 24.47112,21.91754 34.68542,34.68542c5.38341,6.72926 7.12806,15.73403 11.56181,23.12361c7.14921,11.91535 14.44313,23.83481 23.12361,34.68542c6.80954,8.51192 17.51531,13.77645 23.12361,23.12361c6.27027,10.45045 4.47813,24.76828 11.56181,34.68542c12.67166,17.74033 29.22339,32.62816 46.24723,46.24723c3.00942,2.40753 8.11474,-1.72353 11.56181,0c12.42857,6.21428 23.83481,14.44313 34.68542,23.12361c8.51192,6.80954 14.40315,16.58327 23.12361,23.12361c6.89413,5.1706 16.22948,6.39121 23.12361,11.56181c8.72046,6.54035 13.77645,17.51531 23.12361,23.12361c10.45045,6.27027 23.78485,6.11152 34.68542,11.56181c4.87489,2.43744 6.39121,9.83827 11.56181,11.56181c7.31233,2.43744 17.67333,-5.45029 23.12361,0c5.45029,5.45029 -3.44706,16.22948 0,23.12361c1.72353,3.44706 7.70787,0 11.56181,0c3.85394,0 7.70787,0 11.56181,0c32.36969,0 73.0744,-3.44243 104.05627,0c23.2992,2.5888 46.07165,8.97301 69.37084,11.56181c11.49109,1.27679 23.2129,-1.43407 34.68542,0c38.99909,4.87489 76.47689,19.56533 115.61807,23.12361c38.38108,3.48919 77.07872,0 115.61807,0c11.56181,0 23.71693,-3.65616 34.68542,0c3.65616,1.21872 -3.8015,10.92822 0,11.56181c22.80899,3.8015 46.24723,0 69.37084,0c15.41574,0 30.83149,0 46.24723,0c46.24723,0 92.49446,0 138.74169,0c11.56181,0 23.12361,0 34.68542,0c3.85394,0 7.90564,1.21872 11.56181,0c8.17543,-2.72514 14.94818,-8.83666 23.12361,-11.56181c7.31233,-2.43744 15.41574,0 23.12361,0c26.97755,0 53.9551,0 80.93265,0c7.70787,0 15.41574,0 23.12361,0c7.70787,0 16.22948,3.44706 23.12361,0c9.74977,-4.87489 14.05379,-17.07706 23.12361,-23.12361c3.20667,-2.13778 7.90564,1.21872 11.56181,0c8.17543,-2.72514 14.6733,-9.87174 23.12361,-11.56181c11.33728,-2.26746 23.12361,0 34.68542,0c7.70787,0 16.71028,4.27556 23.12361,0c7.17033,-4.78022 4.39148,-18.3434 11.56181,-23.12361c6.41334,-4.27556 15.81129,2.43744 23.12361,0c5.1706,-1.72353 6.39121,-9.83827 11.56181,-11.56181c10.96849,-3.65616 24.34423,5.1706 34.68542,0c4.87489,-2.43744 6.68692,-9.12436 11.56181,-11.56181c3.44706,-1.72353 8.11474,1.72353 11.56181,0c4.87489,-2.43744 6.68692,-9.12436 11.56181,-11.56181c3.44706,-1.72353 7.82294,0.93472 11.56181,0c11.82334,-2.95583 23.78485,-6.11152 34.68542,-11.56181c4.87489,-2.43744 8.53853,-7.02689 11.56181,-11.56181c4.78022,-7.17033 4.39148,-18.3434 11.56181,-23.12361c9.62001,-6.41334 23.12361,0 34.68542,0c3.85394,0 9.83827,3.44706 11.56181,0c3.44706,-6.89413 -5.45029,-17.67333 0,-23.12361c5.45029,-5.45029 16.22948,3.44706 23.12361,0c3.44706,-1.72353 -3.44706,-9.83827 0,-11.56181c10.34119,-5.1706 23.12361,0 34.68542,0c3.85394,0 9.83827,3.44706 11.56181,0c3.44706,-6.89413 -3.44706,-16.22948 0,-23.12361c1.72353,-3.44706 7.90564,1.21872 11.56181,0c16.13974,-5.37991 47.25491,-26.76982 57.80904,-34.68542c8.72046,-6.54035 13.37384,-18.24873 23.12361,-23.12361c3.44706,-1.72353 7.90564,1.21872 11.56181,0c8.17543,-2.72514 17.03001,-5.4682 23.12361,-11.56181c6.09361,-6.09361 6.78159,-15.95329 11.56181,-23.12361c3.02328,-4.53491 6.68692,-9.12436 11.56181,-11.56181c3.44706,-1.72353 8.83666,2.72514 11.56181,0c2.72514,-2.72514 -2.72514,-8.83666 0,-11.56181c2.72514,-2.72514 8.35514,2.13778 11.56181,0c9.06983,-6.04655 16.58327,-14.40315 23.12361,-23.12361c5.1706,-6.89413 6.78159,-15.95329 11.56181,-23.12361c3.02328,-4.53491 8.53853,-7.02689 11.56181,-11.56181c4.78022,-7.17033 5.4682,-17.03001 11.56181,-23.12361c6.09361,-6.09361 17.03001,-5.4682 23.12361,-11.56181c2.72514,-2.72514 -1.72353,-8.11474 0,-11.56181c4.87489,-9.74977 17.07706,-14.05379 23.12361,-23.12361c4.78022,-7.17033 8.83666,-14.94818 11.56181,-23.12361c1.21872,-3.65616 -1.21872,-7.90564 0,-11.56181c2.72514,-8.17543 8.83666,-14.94818 11.56181,-23.12361c3.46854,-10.40563 -3.46854,-24.2798 0,-34.68542c1.72353,-5.1706 9.83827,-6.39121 11.56181,-11.56181c6.09361,-18.28082 -3.77909,-38.91356 0,-57.80904c1.69006,-8.45031 8.83666,-14.94818 11.56181,-23.12361c4.52003,-13.56009 -3.21502,-64.85757 0,-80.93265c1.69006,-8.45031 8.83666,-14.94818 11.56181,-23.12361c4.61683,-13.8505 -4.68183,-43.76355 0,-57.80904c2.72514,-8.17543 8.83666,-14.94818 11.56181,-23.12361c1.21872,-3.65616 0,-7.70787 0,-11.56181c0,-19.26968 0,-38.53936 0,-57.80904c0,-3.85394 -1.21872,-7.90564 0,-11.56181c2.72514,-8.17543 9.87174,-14.6733 11.56181,-23.12361c2.8455,-14.22748 0,-76.10948 0,-92.49446c0,-11.56181 0,-23.12361 0,-34.68542c0,-3.85394 2.13778,-8.35514 0,-11.56181c-6.04655,-9.06983 -17.07706,-14.05379 -23.12361,-23.12361c-2.13778,-3.20667 1.21872,-7.90564 0,-11.56181c-2.72514,-8.17543 -7.70787,-15.41574 -11.56181,-23.12361c-7.70787,-15.41574 -12.78242,-32.45897 -23.12361,-46.24723c-2.31236,-3.08315 -9.83827,3.44706 -11.56181,0c-3.44706,-6.89413 3.44706,-16.22948 0,-23.12361c-1.72353,-3.44706 -8.83666,2.72514 -11.56181,0c-2.72514,-2.72514 1.72353,-8.11474 0,-11.56181c-2.43744,-4.87489 -7.70787,-7.70787 -11.56181,-11.56181c-3.85394,-3.85394 -6.68692,-9.12436 -11.56181,-11.56181c-3.44706,-1.72353 -8.11474,1.72353 -11.56181,0c-4.87489,-2.43744 -6.68692,-9.12436 -11.56181,-11.56181c-3.44706,-1.72353 -7.90564,1.21872 -11.56181,0c-8.17543,-2.72514 -15.05465,-8.53594 -23.12361,-11.56181c-22.82249,-8.55843 -45.93425,-16.42744 -69.37084,-23.12361c-7.4113,-2.11752 -15.41574,0 -23.12361,0c-11.56181,0 -23.12361,0 -34.68542,0c-69.37084,0 -138.74169,0 -208.11253,0c-80.93265,0 -161.8653,0 -242.79795,0c-19.26968,0 -38.53936,0 -57.80904,0c-7.70787,0 -15.41574,0 -23.12361,0c-3.85394,0 -8.11474,-1.72353 -11.56181,0c-4.87489,2.43744 -6.68692,9.12436 -11.56181,11.56181c-3.44706,1.72353 -7.70787,0 -11.56181,0c-11.56181,0 -23.23982,-1.63509 -34.68542,0c-15.73048,2.24721 -30.51675,9.3146 -46.24723,11.56181c-11.44561,1.63509 -23.12361,0 -34.68542,0c-11.56181,0 -23.12361,0 -34.68542,0c-3.85394,0 -9.83827,-3.44706 -11.56181,0c-3.44706,6.89413 3.44706,16.22948 0,23.12361c-3.44706,6.89413 -17.67333,-5.45029 -23.12361,0c-2.72514,2.72514 3.44706,9.83827 0,11.56181c-9.24945,4.62472 -25.43598,-4.62472 -34.68542,0c-12.42857,6.21428 -24.85978,13.29797 -34.68542,23.12361c-2.72514,2.72514 3.44706,9.83827 0,11.56181c-2.71877,1.35939 -38.65202,0 -46.24723,0\" data-paper-data=\"{&quot;annotation&quot;:null}\" id=\"smooth_path_fd016497-46bb-446c-8eb2-986dfe65e027\" fill=\"none\" stroke=\"#00bfff\" stroke-width=\"11.56181\" stroke-linecap=\"butt\" stroke-linejoin=\"miter\" stroke-miterlimit=\"10\" stroke-dasharray=\"\" stroke-dashoffset=\"0\" font-family=\"sans-serif\" font-weight=\"normal\" font-size=\"12\" text-anchor=\"start\" mix-blend-mode=\"normal\"/></svg>"}}'
    end
    if (scene=="6")
      newAnnotation['on'] = '{"@type"=>"oa:SpecificResource", "full"=>"http://manifests.ydc2.yale.edu/LOTB/canvas/bv11", "selector"=>{"@type"=>"oa:SvgSelector", "value"=>"<svg xmlns=\'http://www.w3.org/2000/svg\'><path xmlns=\"http://www.w3.org/2000/svg\" d=\"M18469.54646,4636.28474c-23.12361,0 -46.24723,0 -69.37084,0c-7.70787,0 -15.64588,-1.86943 -23.12361,0c-8.36036,2.09009 -14.76325,9.47172 -23.12361,11.56181c-7.47773,1.86943 -15.41574,0 -23.12361,0c-15.41574,0 -30.83149,0 -46.24723,0c-11.56181,0 -23.46882,-2.80415 -34.68542,0c-5.28756,1.32189 -6.39121,9.83827 -11.56181,11.56181c-10.96849,3.65616 -24.34423,-5.1706 -34.68542,0c-4.87489,2.43744 -6.27425,10.23992 -11.56181,11.56181c-11.2166,2.80415 -23.34814,-2.26746 -34.68542,0c-8.45031,1.69006 -14.76325,9.47172 -23.12361,11.56181c-7.47773,1.86943 -15.52062,-1.26717 -23.12361,0c-15.67398,2.61233 -30.57325,8.94948 -46.24723,11.56181c-7.603,1.26717 -15.41574,0 -23.12361,0c-3.85394,0 -8.11474,-1.72353 -11.56181,0c-4.87489,2.43744 -6.39121,9.83827 -11.56181,11.56181c-7.31233,2.43744 -16.22948,-3.44706 -23.12361,0c-9.74977,4.87489 -13.77645,17.51531 -23.12361,23.12361c-10.45045,6.27027 -23.78485,6.11152 -34.68542,11.56181c-9.74977,4.87489 -13.37384,18.24873 -23.12361,23.12361c-3.44706,1.72353 -8.83666,-2.72514 -11.56181,0c-2.72514,2.72514 2.72514,8.83666 0,11.56181c-2.72514,2.72514 -7.90564,-1.21872 -11.56181,0c-8.17543,2.72514 -15.41574,7.70787 -23.12361,11.56181c-7.70787,3.85394 -16.22948,6.39121 -23.12361,11.56181c-8.72046,6.54035 -17.07706,14.05379 -23.12361,23.12361c-2.13778,3.20667 3.44706,9.83827 0,11.56181c-6.89413,3.44706 -15.64588,-1.86943 -23.12361,0c-8.36036,2.09009 -15.41574,7.70787 -23.12361,11.56181c-7.70787,3.85394 -17.03001,5.4682 -23.12361,11.56181c-2.72514,2.72514 2.72514,8.83666 0,11.56181c-2.72514,2.72514 -8.11474,-1.72353 -11.56181,0c-4.87489,2.43744 -6.39121,9.83827 -11.56181,11.56181c-7.31233,2.43744 -16.51417,-3.96567 -23.12361,0c-2.83378,1.70027 -49.49663,50.2523 -57.80904,57.80904c-46.42201,42.20183 -94.37956,82.81775 -138.74169,127.17988c-7.70787,7.70787 -18.24873,13.37384 -23.12361,23.12361c-3.44706,6.89413 3.44706,16.22948 0,23.12361c-1.72353,3.44706 -8.11474,-1.72353 -11.56181,0c-4.87489,2.43744 -9.12436,6.68692 -11.56181,11.56181c-5.45029,10.90058 -5.29154,24.23497 -11.56181,34.68542c-5.6083,9.34717 -16.14524,14.74956 -23.12361,23.12361c-12.33615,14.80338 -24.77125,29.72362 -34.68542,46.24723c-1.98283,3.30472 2.72514,8.83666 0,11.56181c-2.72514,2.72514 -8.83666,-2.72514 -11.56181,0c-5.45029,5.45029 2.43744,15.81129 0,23.12361c-2.72514,8.17543 -5.4682,17.03001 -11.56181,23.12361c-6.09361,6.09361 -17.03001,5.4682 -23.12361,11.56181c-13.28534,13.28534 -11.56181,20.44734 -11.56181,34.68542c0,7.70787 3.44706,16.22948 0,23.12361c-1.72353,3.44706 -8.83666,-2.72514 -11.56181,0c-9.82565,9.82565 -17.96293,21.78372 -23.12361,34.68542c-2.86263,7.15658 1.51164,15.56542 0,23.12361c-2.39011,11.95055 -9.55824,22.66403 -11.56181,34.68542c-1.90075,11.4045 2.26746,23.34814 0,34.68542c-1.69006,8.45031 -8.83666,14.94818 -11.56181,23.12361c-1.21872,3.65616 1.72353,8.11474 0,11.56181c-2.43744,4.87489 -8.53853,7.02689 -11.56181,11.56181c-4.78022,7.17033 -8.83666,14.94818 -11.56181,23.12361c-2.30204,6.90612 3.05153,21.59785 0,23.12361c-6.89413,3.44706 -16.22948,-3.44706 -23.12361,0c-3.44706,1.72353 0,7.70787 0,11.56181c0,11.56181 0,23.12361 0,34.68542c0,7.70787 0,15.41574 0,23.12361c0,7.70787 2.43744,15.81129 0,23.12361c-1.72353,5.1706 -10.23992,6.27425 -11.56181,11.56181c-5.11468,20.45873 2.6695,48.01486 0,69.37084c-2.90769,23.26155 -9.22918,46.04461 -11.56181,69.37084c-1.53392,15.33924 3.02328,31.13085 0,46.24723c-1.06889,5.34445 -10.49292,6.21736 -11.56181,11.56181c-3.02328,15.11638 0,30.83149 0,46.24723c0,23.12361 0,46.24723 0,69.37084c0,69.37084 0,138.74169 0,208.11253c0,42.39329 0,84.78659 0,127.17988c0,7.70787 0,15.41574 0,23.12361c0,7.70787 2.43744,15.81129 0,23.12361c-1.72353,5.1706 -10.23992,6.27425 -11.56181,11.56181c-4.67358,18.69433 0,38.53936 0,57.80904c0,34.68542 0,69.37084 0,104.05627c0,53.9551 0,107.9102 0,161.8653c0,23.12361 -2.09351,46.34219 0,69.37084c1.77914,19.57059 2.77348,40.23239 11.56181,57.80904c3.85394,7.70787 18.3434,4.39148 23.12361,11.56181c4.27556,6.41334 -1.86943,15.64588 0,23.12361c2.09009,8.36036 6.78159,15.95329 11.56181,23.12361c3.02328,4.53491 9.83827,6.39121 11.56181,11.56181c2.43744,7.31233 -2.43744,15.81129 0,23.12361c5.45029,16.35086 16.72258,30.24463 23.12361,46.24723c1.43132,3.57829 -1.21872,7.90564 0,11.56181c2.72514,8.17543 6.78159,15.95329 11.56181,23.12361c3.02328,4.53491 6.68692,9.12436 11.56181,11.56181c3.44706,1.72353 8.83666,-2.72514 11.56181,0c6.09361,6.09361 6.1784,16.39435 11.56181,23.12361c10.2143,12.76788 21.08068,25.61559 34.68542,34.68542c10.14038,6.76025 24.54505,4.80156 34.68542,11.56181c3.20667,2.13778 -3.44706,9.83827 0,11.56181c6.89413,3.44706 16.22948,-3.44706 23.12361,0c9.74977,4.87489 13.37384,18.24873 23.12361,23.12361c6.89413,3.44706 15.64588,-1.86943 23.12361,0c8.36036,2.09009 14.94818,8.83666 23.12361,11.56181c10.96849,3.65616 23.46882,-2.80415 34.68542,0c23.64667,5.91167 45.72417,17.21195 69.37084,23.12361c22.74264,5.68566 46.38351,6.96434 69.37084,11.56181c15.58161,3.11632 30.51675,9.3146 46.24723,11.56181c11.44561,1.63509 23.2129,-1.43407 34.68542,0c19.49954,2.43744 38.42512,8.33115 57.80904,11.56181c21.07411,3.51235 48.56855,0 69.37084,0c15.41574,0 30.83149,0 46.24723,0c11.56181,0 23.28093,1.90075 34.68542,0c12.02139,-2.00357 22.86209,-8.60597 34.68542,-11.56181c11.2166,-2.80415 23.34814,2.26746 34.68542,0c11.95055,-2.39011 23.36988,-7.03559 34.68542,-11.56181c8.0013,-3.20052 14.76325,-9.47172 23.12361,-11.56181c7.47773,-1.86943 15.64588,1.86943 23.12361,0c8.36036,-2.09009 14.6733,-9.87174 23.12361,-11.56181c11.33728,-2.26746 23.34814,2.26746 34.68542,0c8.45031,-1.69006 14.94818,-8.83666 23.12361,-11.56181c15.07475,-5.02492 31.64185,-5.30236 46.24723,-11.56181c12.77204,-5.47373 21.50293,-18.72945 34.68542,-23.12361c10.96849,-3.65616 23.71693,3.65616 34.68542,0c3.65616,-1.21872 -3.44706,-9.83827 0,-11.56181c6.89413,-3.44706 15.81129,2.43744 23.12361,0c5.1706,-1.72353 6.68692,-9.12436 11.56181,-11.56181c10.34119,-5.1706 25.43598,6.93708 34.68542,0c11.11645,-8.33734 13.29797,-24.85978 23.12361,-34.68542c2.72514,-2.72514 8.35514,2.13778 11.56181,0c9.06983,-6.04655 14.74956,-16.14524 23.12361,-23.12361c14.80338,-12.33615 31.20014,-22.64775 46.24723,-34.68542c4.25596,-3.40477 7.20158,-8.29163 11.56181,-11.56181c11.11645,-8.33734 23.56897,-14.78628 34.68542,-23.12361c26.04629,-19.53472 37.91342,-56.06313 57.80904,-80.93265c13.61907,-17.02384 33.16654,-28.80631 46.24723,-46.24723c5.1706,-6.89413 5.4682,-17.03001 11.56181,-23.12361c6.09361,-6.09361 18.3434,-4.39148 23.12361,-11.56181c4.27556,-6.41334 -4.27556,-16.71028 0,-23.12361c4.78022,-7.17033 18.3434,-4.39148 23.12361,-11.56181c19.1624,-28.7436 21.54459,-61.83251 34.68542,-92.49446c6.78933,-15.84176 14.25611,-31.46806 23.12361,-46.24723c2.80415,-4.67358 9.12436,-6.68692 11.56181,-11.56181c5.45029,-10.90058 8.60597,-22.86209 11.56181,-34.68542c0.93472,-3.73887 -0.93472,-7.82294 0,-11.56181c2.95583,-11.82334 9.1717,-22.73487 11.56181,-34.68542c1.51164,-7.55819 -1.26717,-15.52062 0,-23.12361c2.61233,-15.67398 6.53689,-31.17248 11.56181,-46.24723c6.56302,-19.68905 16.5606,-38.11999 23.12361,-57.80904c1.21872,-3.65616 -1.21872,-7.90564 0,-11.56181c6.56302,-19.68905 14.94818,-38.73303 23.12361,-57.80904c3.39466,-7.92088 8.83666,-14.94818 11.56181,-23.12361c1.21872,-3.65616 -0.93472,-7.82294 0,-11.56181c2.95583,-11.82334 10.05017,-22.59232 11.56181,-34.68542c2.39011,-19.12088 -4.67358,-39.1147 0,-57.80904c3.37017,-13.48068 16.90933,-22.25685 23.12361,-34.68542c5.45029,-10.90058 6.11152,-23.78485 11.56181,-34.68542c2.43744,-4.87489 10.23992,-6.27425 11.56181,-11.56181c2.80415,-11.2166 -2.26746,-23.34814 0,-34.68542c1.69006,-8.45031 8.36129,-15.12232 11.56181,-23.12361c4.52622,-11.31555 9.55824,-22.66403 11.56181,-34.68542c1.90075,-11.4045 -5.1706,-24.34423 0,-34.68542c3.85394,-7.70787 18.3434,-4.39148 23.12361,-11.56181c4.27556,-6.41334 0,-15.41574 0,-23.12361c0,-19.26968 0,-38.53936 0,-57.80904c0,-3.85394 -1.21872,-7.90564 0,-11.56181c2.72514,-8.17543 9.87174,-14.6733 11.56181,-23.12361c2.26746,-11.33728 -2.26746,-23.34814 0,-34.68542c1.69006,-8.45031 9.87174,-14.6733 11.56181,-23.12361c3.77909,-18.89547 -4.67358,-39.1147 0,-57.80904c4.18018,-16.72072 20.29014,-29.24641 23.12361,-46.24723c2.53433,-15.206 -3.73887,-31.29176 0,-46.24723c0.93472,-3.73887 9.83827,3.44706 11.56181,0c3.44706,-6.89413 0,-15.41574 0,-23.12361c0,-15.41574 0,-30.83149 0,-46.24723c0,-7.70787 -2.43744,-15.81129 0,-23.12361c1.72353,-5.1706 10.23992,-6.27425 11.56181,-11.56181c2.80415,-11.2166 0,-23.12361 0,-34.68542c0,-30.83149 0,-61.66297 0,-92.49446c0,-11.56181 -2.80415,-23.46882 0,-34.68542c2.09009,-8.36036 8.83666,-14.94818 11.56181,-23.12361c2.08577,-6.25732 0,-42.30842 0,-46.24723c0,-19.85142 3.02654,-74.33523 0,-92.49446c-2.00357,-12.02139 -9.1717,-22.73487 -11.56181,-34.68542c-1.51164,-7.55819 0,-15.41574 0,-23.12361c0,-19.26968 0,-38.53936 0,-57.80904c0,-11.56181 2.26746,-23.34814 0,-34.68542c-1.69006,-8.45031 -10.14507,-14.6232 -11.56181,-23.12361c-2.53433,-15.206 0,-30.83149 0,-46.24723c0,-26.97755 0,-53.9551 0,-80.93265c0,-19.26968 0,-38.53936 0,-57.80904c0,-7.70787 0,-15.41574 0,-23.12361c0,-3.85394 3.44706,-9.83827 0,-11.56181c-6.89413,-3.44706 -16.22948,3.44706 -23.12361,0c-3.44706,-1.72353 1.72353,-8.11474 0,-11.56181c-2.43744,-4.87489 -9.12436,-6.68692 -11.56181,-11.56181c-1.72353,-3.44706 2.72514,-8.83666 0,-11.56181c-6.09361,-6.09361 -17.03001,-5.4682 -23.12361,-11.56181c-2.72514,-2.72514 2.72514,-8.83666 0,-11.56181c-2.72514,-2.72514 -8.11474,1.72353 -11.56181,0c-12.42857,-6.21428 -23.83481,-14.44313 -34.68542,-23.12361c-8.51192,-6.80954 -14.40315,-16.58327 -23.12361,-23.12361c-6.89413,-5.1706 -14.94818,-8.83666 -23.12361,-11.56181c-3.65616,-1.21872 -7.90564,1.21872 -11.56181,0c-8.17543,-2.72514 -14.5725,-10.49292 -23.12361,-11.56181c-22.94505,-2.86813 -46.47963,3.27017 -69.37084,0c-31.46096,-4.49442 -61.22671,-17.43857 -92.49446,-23.12361c-18.95886,-3.44706 -38.53936,0 -57.80904,0c-42.39329,0 -84.78659,0 -127.17988,0c-50.10117,0 -100.20233,0 -150.3035,0c-19.26968,0 -38.53936,0 -57.80904,0c-3.85394,0 -8.83666,2.72514 -11.56181,0c-2.72514,-2.72514 0,-7.70787 0,-11.56181\" data-paper-data=\"{&quot;annotation&quot;:null}\" id=\"smooth_path_e9e3c3b3-7f89-4281-aac5-2718076a6b15\" fill=\"none\" stroke=\"#00bfff\" stroke-width=\"11.56181\" stroke-linecap=\"butt\" stroke-linejoin=\"miter\" stroke-miterlimit=\"10\" stroke-dasharray=\"\" stroke-dashoffset=\"0\" font-family=\"sans-serif\" font-weight=\"normal\" font-size=\"12\" text-anchor=\"start\" mix-blend-mode=\"normal\"/></svg>"}}'
    end
    if (scene=="7")
      newAnnotation['on'] = '{"@type"=>"oa:SpecificResource", "full"=>"http://manifests.ydc2.yale.edu/LOTB/canvas/bv11", "selector"=>{"@type"=>"oa:SvgSelector", "value"=>"<svg xmlns=\'http://www.w3.org/2000/svg\'><path xmlns=\"http://www.w3.org/2000/svg\" d=\"M17666.64318,9369.5602c0,12.84645 0,25.69291 0,38.53936c0,8.5643 3.83007,18.03276 0,25.69291c-6.90476,13.80952 -20.8105,23.89215 -25.69291,38.53936c-4.06241,12.18722 2.11194,25.86769 0,38.53936c-2.22618,13.35711 -10.19078,25.26097 -12.84645,38.53936c-1.6796,8.39799 0,17.1286 0,25.69291c0,29.52931 2.92041,60.72109 0,89.92517c-5.18361,51.83608 -17.1286,102.77162 -25.69291,154.15743c-2.07344,12.44065 2.47184,26.18016 0,38.53936c-3.46258,17.3129 -9.94386,33.97028 -12.84645,51.38581c-1.40796,8.44778 0,17.1286 0,25.69291c0,21.41075 0,42.82151 0,64.23226c0,8.5643 2.07715,17.38431 0,25.69291c-2.32232,9.28929 -10.52413,16.40362 -12.84645,25.69291c-5.21601,20.86406 4.16701,56.24365 0,77.07872c-1.87785,9.38924 -10.96861,16.30367 -12.84645,25.69291c-2.5194,12.59698 0,25.69291 0,38.53936c0,38.53936 0,77.07872 0,115.61807c0,12.84645 2.5194,25.94237 0,38.53936c-2.65568,13.27839 -10.19078,25.26097 -12.84645,38.53936c-1.6796,8.39799 0,17.1286 0,25.69291c0,21.41075 0,42.82151 0,64.23226c0,47.10366 0,94.20732 0,141.31098c0,68.51441 0,137.02883 0,205.54324c0,21.41075 0,42.82151 0,64.23226c0,4.28215 -2.37531,9.28349 0,12.84645c6.71839,10.07759 20.27637,14.85983 25.69291,25.69291c3.83007,7.66014 -2.70827,17.5681 0,25.69291c1.91504,5.74511 11.99002,6.85144 12.84645,12.84645c3.63353,25.43468 -2.83731,51.54295 0,77.07872c1.49539,13.45853 9.56219,25.40232 12.84645,38.53936c1.03857,4.1543 -2.37531,9.28349 0,12.84645c6.71839,10.07759 20.27637,14.85983 25.69291,25.69291c1.51043,3.02086 0,42.94669 0,51.38581c0,8.5643 -3.83007,18.03276 0,25.69291c1.91504,3.83007 8.78405,-1.35414 12.84645,0c9.08381,3.02794 20.38155,4.87942 25.69291,12.84645c4.75062,7.12593 -4.75062,18.56698 0,25.69291c5.31135,7.96703 18.92223,6.07578 25.69291,12.84645c3.02794,3.02794 -3.02794,9.81851 0,12.84645c6.05588,6.05588 18.84146,-5.13858 25.69291,0c14.5341,10.90058 24.35282,27.19013 38.53936,38.53936c7.47696,5.98157 18.92223,6.07578 25.69291,12.84645c3.02794,3.02794 -3.02794,9.81851 0,12.84645c6.77068,6.77068 18.92223,6.07578 25.69291,12.84645c3.02794,3.02794 -3.02794,9.81851 0,12.84645c6.05588,6.05588 18.03276,-3.83007 25.69291,0c13.80952,6.90476 23.89215,20.8105 38.53936,25.69291c24.37443,8.12481 51.73539,-4.22389 77.07872,0c13.35711,2.22618 26.42761,6.79058 38.53936,12.84645c13.80952,6.90476 24.72984,18.78814 38.53936,25.69291c3.90961,1.95481 32.75386,0 38.53936,0c29.97506,0 59.95011,0 89.92517,0c38.53936,0 77.07872,0 115.61807,0c12.84645,0 26.35214,4.06241 38.53936,0c14.64721,-4.8824 24.20413,-19.95881 38.53936,-25.69291c11.92763,-4.77105 27.04914,5.74511 38.53936,0c5.41654,-2.70827 7.42991,-10.13818 12.84645,-12.84645c3.83007,-1.91504 8.5643,0 12.84645,0c8.5643,0 17.1286,0 25.69291,0c8.5643,0 17.6739,3.00713 25.69291,0c26.89656,-10.08621 52.13796,-24.2875 77.07872,-38.53936c5.25797,-3.00456 7.80766,-9.48726 12.84645,-12.84645c12.84645,-8.5643 29.27565,-13.34129 38.53936,-25.69291c9.26371,-12.35161 13.34129,-29.27565 25.69291,-38.53936c6.85144,-5.13858 18.03276,3.83007 25.69291,0c19.15036,-9.57518 36.24612,-23.39967 51.38581,-38.53936c6.77068,-6.77068 6.07578,-18.92223 12.84645,-25.69291c6.77068,-6.77068 18.03276,-7.10134 25.69291,-12.84645c9.6894,-7.26705 15.61532,-18.97451 25.69291,-25.69291c3.56296,-2.37531 9.81851,3.02794 12.84645,0c15.64677,-15.64677 6.01756,-28.70169 25.69291,-38.53936c7.66014,-3.83007 19.63703,6.05588 25.69291,0c10.91739,-10.91739 14.77552,-27.62197 25.69291,-38.53936c6.77068,-6.77068 17.48226,-7.92006 25.69291,-12.84645c13.23927,-7.94356 27.62197,-14.77552 38.53936,-25.69291c6.77068,-6.77068 7.5351,-17.72587 12.84645,-25.69291c3.3592,-5.03879 9.48726,-7.80766 12.84645,-12.84645c5.31135,-7.96703 7.10134,-18.03276 12.84645,-25.69291c26.79888,-35.73184 41.65425,-31.9227 64.23226,-77.07872c6.05588,-12.11175 5.87949,-26.92775 12.84645,-38.53936c6.23144,-10.38574 21.19471,-14.44743 25.69291,-25.69291c4.77105,-11.92763 -3.11572,-26.07647 0,-38.53936c1.46877,-5.87506 10.93142,-7.10134 12.84645,-12.84645c2.70827,-8.12481 -3.83007,-18.03276 0,-25.69291c9.57518,-19.15036 27.91665,-32.79607 38.53936,-51.38581c6.71839,-11.75718 8.09177,-25.8602 12.84645,-38.53936c8.09694,-21.59183 18.40067,-42.35554 25.69291,-64.23226c1.35414,-4.06241 -0.8398,-8.64746 0,-12.84645c3.46258,-17.3129 6.28927,-34.99285 12.84645,-51.38581c2.2491,-5.62274 11.37769,-6.97139 12.84645,-12.84645c5.03782,-20.1513 -5.03782,-44.08096 0,-64.23226c6.23495,-24.93978 29.32942,-41.20743 38.53936,-64.23226c3.1807,-7.95175 -1.21118,-17.21468 0,-25.69291c3.0879,-21.61532 4.24531,-44.16294 12.84645,-64.23226c4.77105,-11.13246 18.97451,-15.61532 25.69291,-25.69291c2.37531,-3.56296 0,-8.5643 0,-12.84645c0,-12.84645 0,-25.69291 0,-38.53936c0,-17.1286 -3.3592,-34.58983 0,-51.38581c4.28215,-21.41075 12.84645,-42.39749 12.84645,-64.23226c0,-21.41075 0,-42.82151 0,-64.23226c0,-4.28215 -1.91504,-9.01638 0,-12.84645c6.90476,-13.80952 18.78814,-24.72984 25.69291,-38.53936c3.83007,-7.66014 0,-17.1286 0,-25.69291c0,-17.1286 0,-34.25721 0,-51.38581c0,-38.53936 0,-77.07872 0,-115.61807c0,-17.1286 2.81593,-34.49026 0,-51.38581c-1.57415,-9.4449 -10.96861,-16.30367 -12.84645,-25.69291c-2.5194,-12.59698 2.11194,-25.86769 0,-38.53936c-2.22618,-13.35711 -9.56219,-25.40232 -12.84645,-38.53936c-1.03857,-4.1543 1.1764,-8.72906 0,-12.84645c-7.44019,-26.04066 -15.63464,-51.93306 -25.69291,-77.07872c-7.11227,-17.78066 -18.14921,-33.78385 -25.69291,-51.38581c-5.3342,-12.44646 -8.21879,-25.81329 -12.84645,-38.53936c-12.50326,-34.38395 -23.39967,-69.4643 -38.53936,-102.77162c-6.38892,-14.05562 -17.1286,-25.69291 -25.69291,-38.53936c-8.5643,-12.84645 -17.74934,-25.30008 -25.69291,-38.53936c-4.92639,-8.21065 -5.18631,-19.9478 -12.84645,-25.69291c-10.83308,-8.12481 -27.85046,-4.53287 -38.53936,-12.84645c-28.68131,-22.30769 -47.5115,-55.95928 -77.07872,-77.07872c-31.16658,-22.26184 -69.38965,-32.60845 -102.77162,-51.38581c-35.20967,-19.80544 -70.10052,-40.47146 -102.77162,-64.23226c-14.69282,-10.68568 -22.28974,-30.41455 -38.53936,-38.53936c-5.35269,-2.67634 -53.52689,1.78423 -64.23226,0c-17.41553,-2.90259 -33.80256,-11.24798 -51.38581,-12.84645c-29.85195,-2.71381 -59.95011,0 -89.92517,0c-34.25721,0 -68.51441,0 -102.77162,0c-68.51441,0 -137.02883,0 -205.54324,0c-12.84645,0 -25.69291,0 -38.53936,0c-8.5643,0 -17.74115,-3.1807 -25.69291,0c-14.33523,5.73409 -24.72984,18.78814 -38.53936,25.69291c-12.11175,6.05588 -26.42761,6.79058 -38.53936,12.84645c-13.80952,6.90476 -24.72984,18.78814 -38.53936,25.69291c-3.83007,1.91504 -9.81851,-3.02794 -12.84645,0c-3.02794,3.02794 3.56296,10.47114 0,12.84645c-11.26708,7.51139 -26.42761,6.79058 -38.53936,12.84645c-22.33297,11.16648 -44.25705,23.55795 -64.23226,38.53936c-14.5341,10.90058 -22.96075,29.19219 -38.53936,38.53936c0,0 -51.38581,0 -51.38581,0c-3.83007,1.91504 3.42572,10.27716 0,12.84645c-18.38282,13.78711 -65.11913,32.33785 -89.92517,38.53936c-4.1543,1.03857 -9.81851,-3.02794 -12.84645,0c-3.02794,3.02794 3.83007,10.93142 0,12.84645c-7.66014,3.83007 -18.03276,-3.83007 -25.69291,0c-3.83007,1.91504 3.02794,9.81851 0,12.84645c-15.64677,15.64677 -28.70169,6.01756 -38.53936,25.69291c-3.83007,7.66014 6.05588,19.63703 0,25.69291c-3.02794,3.02794 -9.81851,-3.02794 -12.84645,0c-6.05588,6.05588 2.70827,17.5681 0,25.69291c-3.02794,9.08381 -9.81851,16.60909 -12.84645,25.69291c-2.70827,8.12481 0,17.1286 0,25.69291c0,17.1286 0,34.25721 0,51.38581\" data-paper-data=\"{&quot;annotation&quot;:null}\" id=\"smooth_path_2bd1cf80-eced-443b-8036-8a04e37990fb\" fill=\"none\" stroke=\"#00bfff\" stroke-width=\"12.84645\" stroke-linecap=\"butt\" stroke-linejoin=\"miter\" stroke-miterlimit=\"10\" stroke-dasharray=\"\" stroke-dashoffset=\"0\" font-family=\"sans-serif\" font-weight=\"normal\" font-size=\"12\" text-anchor=\"start\" mix-blend-mode=\"normal\"/></svg>"}}'
    end
    if (scene=="8")
      newAnnotation['on'] = '{"@type"=>"oa:SpecificResource", "full"=>"http://manifests.ydc2.yale.edu/LOTB/canvas/bv11", "selector"=>{"@type"=>"oa:SvgSelector", "value"=>"<svg xmlns=\'http://www.w3.org/2000/svg\'><path xmlns=\"http://www.w3.org/2000/svg\" d=\"M17475.23103,10162.82864c-62.36371,0 -123.05601,-17.49335 -184.98892,-23.12361c-15.35243,-1.39568 -30.83149,0 -46.24723,0c-34.68542,0 -69.37084,0 -104.05627,0c-14.36812,0 -67.1597,-2.29549 -80.93265,0c-12.02139,2.00357 -23.78485,6.11152 -34.68542,11.56181c-4.87489,2.43744 -6.68692,9.12436 -11.56181,11.56181c-3.44706,1.72353 -8.83666,-2.72514 -11.56181,0c-2.72514,2.72514 3.44706,9.83827 0,11.56181c-6.89413,3.44706 -15.81129,-2.43744 -23.12361,0c-5.1706,1.72353 -8.29163,7.20158 -11.56181,11.56181c-8.33734,11.11645 -16.90933,22.25685 -23.12361,34.68542c-1.72353,3.44706 1.72353,8.11474 0,11.56181c-2.43744,4.87489 -6.68692,9.12436 -11.56181,11.56181c-3.44706,1.72353 -8.83666,-2.72514 -11.56181,0c-2.72514,2.72514 2.72514,8.83666 0,11.56181c-6.09361,6.09361 -17.03001,5.4682 -23.12361,11.56181c-2.72514,2.72514 0,7.70787 0,11.56181c0,7.59521 1.35939,43.52846 0,46.24723c-1.72353,3.44706 -9.83827,-3.44706 -11.56181,0c-3.44706,6.89413 1.86943,15.64588 0,23.12361c-2.09009,8.36036 -6.78159,15.95329 -11.56181,23.12361c-3.02328,4.53491 -9.83827,6.39121 -11.56181,11.56181c-3.65616,10.96849 5.1706,24.34423 0,34.68542c-2.43744,4.87489 -9.12436,6.68692 -11.56181,11.56181c-2.76204,5.52407 1.21707,27.38298 0,34.68542c-3.23065,19.38392 -8.78269,38.35525 -11.56181,57.80904c-3.60576,25.24034 4.95168,56.17423 0,80.93265c-3.11632,15.58161 -8.94948,30.57325 -11.56181,46.24723c-3.01394,18.08364 0,39.36959 0,57.80904c0,42.39329 0,84.78659 0,127.17988c0,19.26968 0,38.53936 0,57.80904c0,11.56181 0,23.12361 0,34.68542c0,3.85394 -1.21872,7.90564 0,11.56181c5.45029,16.35086 17.67333,29.89636 23.12361,46.24723c5.02492,15.07475 6.53689,31.17248 11.56181,46.24723c2.72514,8.17543 6.78159,15.95329 11.56181,23.12361c3.02328,4.53491 8.53853,7.02689 11.56181,11.56181c4.78022,7.17033 8.83666,14.94818 11.56181,23.12361c1.21872,3.65616 -3.44706,9.83827 0,11.56181c6.89413,3.44706 16.71028,-4.27556 23.12361,0c7.17033,4.78022 4.39148,18.3434 11.56181,23.12361c6.41334,4.27556 16.22948,-3.44706 23.12361,0c9.74977,4.87489 14.05379,17.07706 23.12361,23.12361c3.20667,2.13778 7.90564,-1.21872 11.56181,0c8.17543,2.72514 14.94818,8.83666 23.12361,11.56181c3.65616,1.21872 8.83666,-2.72514 11.56181,0c2.72514,2.72514 -2.72514,8.83666 0,11.56181c2.72514,2.72514 7.70787,0 11.56181,0c7.70787,0 15.81129,-2.43744 23.12361,0c16.35086,5.45029 29.89636,17.67333 46.24723,23.12361c18.64285,6.21428 38.66099,7.14303 57.80904,11.56181c30.96651,7.14612 61.22671,17.43857 92.49446,23.12361c24.24133,4.40751 83.64267,-2.26818 104.05627,0c15.793,1.75478 30.47975,9.59087 46.24723,11.56181c15.2967,1.91209 30.98642,-2.18012 46.24723,0c12.06473,1.72353 22.86209,8.60597 34.68542,11.56181c11.2166,2.80415 23.12361,0 34.68542,0c34.68542,0 69.37084,0 104.05627,0c6.4533,0 52.51646,1.76419 57.80904,0c16.35086,-5.45029 30.24463,-16.72258 46.24723,-23.12361c7.15658,-2.86263 15.81129,2.43744 23.12361,0c8.17543,-2.72514 17.03001,-5.4682 23.12361,-11.56181c6.09361,-6.09361 5.4682,-17.03001 11.56181,-23.12361c2.72514,-2.72514 7.90564,1.21872 11.56181,0c8.17543,-2.72514 18.3434,-4.39148 23.12361,-11.56181c4.27556,-6.41334 -2.43744,-15.81129 0,-23.12361c1.72353,-5.1706 6.68692,-9.12436 11.56181,-11.56181c3.44706,-1.72353 8.83666,2.72514 11.56181,0c6.09361,-6.09361 6.78159,-15.95329 11.56181,-23.12361c3.02328,-4.53491 8.53853,-7.02689 11.56181,-11.56181c11.51229,-17.26844 13.84211,-39.24602 23.12361,-57.80904c6.21428,-12.42857 18.72945,-21.50293 23.12361,-34.68542c3.65616,-10.96849 -1.27679,-23.19433 0,-34.68542c2.5888,-23.2992 5.12164,-46.83025 11.56181,-69.37084c1.49731,-5.24058 10.49292,-6.21736 11.56181,-11.56181c3.02328,-15.11638 0,-30.83149 0,-46.24723c0,-23.49626 -3.54786,-71.20731 0,-92.49446c1.41673,-8.50041 9.87174,-14.6733 11.56181,-23.12361c2.26746,-11.33728 0,-23.12361 0,-34.68542c0,-30.83149 0,-61.66297 0,-92.49446c0,-50.10117 0,-100.20233 0,-150.3035c0,-11.56181 0,-23.12361 0,-34.68542c0,-7.70787 3.44706,-16.22948 0,-23.12361c-1.72353,-3.44706 -10.34309,3.65616 -11.56181,0c-5.7809,-17.34271 5.7809,-40.46633 0,-57.80904c-1.72353,-5.1706 -6.68692,-9.12436 -11.56181,-11.56181c-3.44706,-1.72353 -9.83827,3.44706 -11.56181,0c-3.44706,-6.89413 4.27556,-16.71028 0,-23.12361c-4.78022,-7.17033 -16.22948,-6.39121 -23.12361,-11.56181c-8.72046,-6.54035 -14.40315,-16.58327 -23.12361,-23.12361c-6.89413,-5.1706 -16.22948,-6.39121 -23.12361,-11.56181c-8.72046,-6.54035 -14.05379,-17.07706 -23.12361,-23.12361c-3.20667,-2.13778 -7.90564,1.21872 -11.56181,0c-31.23828,-10.41276 -62.40443,-21.31208 -92.49446,-34.68542c-9.96107,-4.42714 -12.25074,-22.34698 -23.12361,-23.12361c-49.97384,-3.56956 -100.20233,0 -150.3035,0c-38.53936,0 -77.07872,0 -115.61807,0\" data-paper-data=\"{&quot;annotation&quot;:null}\" id=\"smooth_path_29039226-52b8-4dd5-b228-670d57d6b2e5\" fill=\"none\" stroke=\"#00bfff\" stroke-width=\"11.56181\" stroke-linecap=\"butt\" stroke-linejoin=\"miter\" stroke-miterlimit=\"10\" stroke-dasharray=\"\" stroke-dashoffset=\"0\" font-family=\"sans-serif\" font-weight=\"normal\" font-size=\"12\" text-anchor=\"start\" mix-blend-mode=\"normal\"/></svg>"}}'
    end
    #newAnnotation['on'] = JSON.parse(newAnnotation['on'])

    newAnnotation['description'] = "Panel: " + row[0] + " Chapter: " + row[1] + " Scene: " + scene
    newAnnotation['description'] = "Panel: " + row[0] + " Chapter: " + row[1] if (scene=="0")
    newAnnotation['annotated_by'] = "annotator"
    newAnnotation['canvas']  = "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
    newAnnotation['manifest'] = "tbd"
    newAnnotation['active'] = true
    newAnnotation['version'] = 1
    thisList = @ru + "/lists/Scenes/_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
    thisList = @ru + "/lists/Chapters/_http://manifests.ydc2.yale.edu/LOTB/canvas/bv11" if (scene=="0")
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
    #LayerListsMap.setMap list['within'],list['list_id']
  end

  def createNewRenderingAnnotation newAnnotation
    annotations = Annotation.where(annotation_id: newAnnotation['annotation_id']).first
    if (annotations.nil?)
      #p 'in createNewRenderingAnnotation: resource = ' + newAnnotation['resource'].to_s
      @annotation = Annotation.create(annotation_id:newAnnotation['annotation_id'], annotation_type: newAnnotation['annotation_type'], motivation: newAnnotation['motivation'],
                                      description:newAnnotation['description'], resource:newAnnotation['resource'].to_s, on: newAnnotation['on'].to_s, canvas: newAnnotation['canvas'], manifest: newAnnotation['manifest'],
                                      active: newAnnotation['active'],
                                      version: newAnnotation['version'])
      ListAnnotationsMap.setMap newAnnotation['within'], newAnnotation['annotation_id']
    end
  end
#================= end LotB ================

  desc "imports LayerListsMaps data from a csv file"
  task :layerListsMaps => :environment do
    require 'csv'
    CSV.foreach('importData/LayerListsMaps.csv') do |row|
      id = row[0]
      layer_id = row[1]
      sequence = row[2]
      list_id = row[3]
      puts row.inspect
      puts "Id: ", id,"Layer_id: ", layer_id, "Sequence ", sequence,"List_Id: ", list_id
      @layerListsMap = LayerListsMap.create(id: id, layer_id: layer_id, sequence: sequence, list_id: list_id)
      #@layerListsMap.save!(options={validate: false})
      puts "@layerListsMap.sequence = ", @layerListsMap.sequence
    end
  end

  desc "imports ListAnnotationssMaps data from a csv file"
  task :listAnnotationMaps => :environment do
    require 'csv'
    CSV.foreach('importData/ListAnnotationsMaps.csv') do |row|
      id = row[0]
      list_id_in = row[1]
      sequence = row[2].to_i
      annotation_id = row[3]
      puts row.inspect
      puts "Id: ", id,"List_id: ", list_id_in, "Sequence ", sequence,"Annotation_Id: ", annotation_id
      @listAnnotationsMap = ListAnnotationsMap.create(list_id:list_id_in, sequence: sequence, annotation_id: annotation_id)

      puts @listAnnotationsMap.attributes.to_s
      @listAnnotationsMap.save!(options={validate: false})
      puts "@listAnnotationsMap.sequence = ", @listAnnotationsMap.sequence
    end
  end

  desc "imports user data from a csv file"
  task :users => :environment do
    require 'csv'
    CSV.foreach('importData/users.csv') do |row|
      provider = row[0]
      uid = row[1]
      name = row[2]
      email = uid
      password = "password"
      puts row.inspect
      puts "Provider: ", provider,"uid: ",uid,"Name: ",name, "email", email
      #@user = User.create(provider: provider, uid: uid, name: name, encrypted_password: password, email: email)
       @user = User.create(provider: provider, uid: uid, encrypted_password: password, email: email)
      @user.save!(options={validate: false})
      puts "user.provider = ", @user.provider
    end
  end

  desc "clears user data"
  task :clear_users => :environment do
    User.destroy_all
  end

end