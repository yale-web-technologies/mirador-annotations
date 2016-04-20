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
    @ru = "http://localhost:5000"
    #@ru = "mirador-annotations-lotb.herokuapp.com"
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
    #newAnnotation['resource'] = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + newAnnotation['annotation_id'] + '"}]'
    newAnnotation['resource'] = '[{"@type":"dctypes:Text","format":"text/html","chars":"' + "Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" + scene + '"}]'

    #newAnnotation['on'] = @ru + "/annotations/"+ "Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" + scene #+ "_0"
    #newAnnotation['on'] = '{"@type": "oa:SpecificResource","full": "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11","selector": {"@type": "oa:SvgSelector","value": "<svg ><path xmlns=\"http://www.w3.org/2000/svg\" d=\"M1805.2536,2088.35484l61.85023,0l61.85023,0l0,287.42166l0,287.42166l-61.85023,0l-61.85023,0l0,-287.42166z\" data-paper-data=\"{&quot;rotation&quot;:0,&quot;annotation&quot;:null}\" id=\"rectangle_e0efece0-fe6e-438d-a2fd-384d5c281da6\" fill-opacity=\"0\" fill=\"#00bfff\" stroke=\"#00bfff\" stroke-width=\"7.2765\" stroke-linecap=\"butt\" stroke-linejoin=\"miter\" stroke-miterlimit=\"10\" stroke-dasharray=\"\" stroke-dashoffset=\"0\" font-family=\"sans-serif\" font-weight=\"normal\" font-size=\"12\" text-anchor=\"start\" mix-blend-mode=\"normal\"/></svg>"}}'
    newAnnotation['on'] = '{"@type": "oa:SpecificResource","full": "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11","selector": {"@type": "oa:SvgSelector","value": "<svg></svg>"}}'

    #newAnnotation['on'] = '{"@type"=>"oa:SpecificResource", "full"=>"http://manifests.ydc2.yale.edu/LOTB/canvas/bv11", "selector"=>{"@type"=>"oa:SvgSelector", "value"=>"<svg xmlns=$$http://www.w3.org/2000/svg$$><path xmlns=\"http://www.w3.org/2000/svg\" d=\"M4350.4232,3061.01567c0,56.68548 0,113.37095 0,170.05643c0,21.25705 3.0062,42.72775 0,63.77116c-4.13163,28.9214 -15.52752,56.38052 -21.25705,85.02821c-1.38962,6.94809 0,14.17137 0,21.25705c0,21.25705 0,42.51411 0,63.77116c0,7.08568 2.24069,14.53498 0,21.25705c-5.01034,15.03101 -10.0536,31.31066 -21.25705,42.51411c-11.20345,11.20345 -33.00766,8.5818 -42.51411,21.25705c-13.44414,17.92552 -11.23638,43.72982 -21.25705,63.77116c-12.41323,24.82646 -56.783,89.33814 -85.02821,106.28527c-19.21376,11.52826 -47.92709,5.41298 -63.77116,21.25705c-15.84407,15.84407 -5.41298,47.92709 -21.25705,63.77116c-15.84407,15.84407 -44.5574,9.7288 -63.77116,21.25705c-17.18531,10.31119 -28.34274,28.34274 -42.51411,42.51411c-14.17137,14.17137 -32.20292,25.3288 -42.51411,42.51411c-11.52826,19.21376 -11.23638,43.72982 -21.25705,63.77116c-11.42532,22.85065 -29.36987,41.8641 -42.51411,63.77116c-24.45512,40.75854 -40.18858,86.2728 -63.77116,127.54232c-12.67526,22.1817 -33.02589,40.05062 -42.51411,63.77116c-5.26311,13.15779 3.43706,28.76586 0,42.51411c-3.84275,15.37101 -18.14978,26.97772 -21.25705,42.51411c-4.16885,20.84426 3.49464,42.80333 0,63.77116c-3.68367,22.10203 -17.57338,41.66913 -21.25705,63.77116c-3.49464,20.96783 0,42.51411 0,63.77116c0,42.51411 0,85.02821 0,127.54232c0,21.25705 -5.15559,43.14879 0,63.77116c2.43037,9.72148 18.08824,11.75061 21.25705,21.25705c4.48138,13.44414 -4.48138,29.06997 0,42.51411c3.16881,9.50644 12.29429,16.77567 21.25705,21.25705c6.33763,3.16881 14.53498,-2.24069 21.25705,0c15.03101,5.01034 29.83885,11.75061 42.51411,21.25705c16.03307,12.02481 23.90619,35.07094 42.51411,42.51411c19.73668,7.89467 42.51411,0 63.77116,0c7.08568,0 14.67816,-2.63156 21.25705,0c29.4217,11.76868 54.5593,33.8087 85.02821,42.51411c20.43917,5.83976 42.9269,-4.16885 63.77116,0c15.53639,3.10728 27.1431,17.4143 42.51411,21.25705c13.74825,3.43706 28.34274,0 42.51411,0c21.25705,0 42.51411,0 63.77116,0c35.42842,0 70.85684,0 106.28527,0c28.34274,0 56.97033,4.00827 85.02821,0c22.1817,-3.16881 43.72982,-11.23638 63.77116,-21.25705c22.85065,-11.42532 40.28903,-32.45034 63.77116,-42.51411c26.85285,-11.50836 58.8975,-8.1917 85.02821,-21.25705c54.53891,-27.26946 106.25434,-84.99728 148.79937,-127.54232c28.34274,-28.34274 60.41983,-53.38886 85.02821,-85.02821c25.36575,-32.6131 45.29396,-69.33086 63.77116,-106.28527c17.06459,-34.12918 26.72439,-71.54789 42.51411,-106.28527c19.66897,-43.27174 46.11814,-83.40976 63.77116,-127.54232c10.85019,-27.12547 14.17137,-56.68548 21.25705,-85.02821c23.08191,-92.32762 54.95319,-200.60108 63.77116,-297.59875c3.20754,-35.28292 0,-70.85684 0,-106.28527c0,-28.34274 0,-56.68548 0,-85.02821c0,-70.85684 0,-141.71369 0,-212.57053c0,-21.25705 0,-42.51411 0,-63.77116c0,-7.08568 3.16881,-14.91942 0,-21.25705c-11.42532,-22.85065 -31.08878,-40.92051 -42.51411,-63.77116c-20.04134,-40.08268 -25.87068,-85.93375 -42.51411,-127.54232c-5.88434,-14.71085 -18.14978,-26.97772 -21.25705,-42.51411c-4.16885,-20.84426 9.50644,-44.75827 0,-63.77116c-7.08568,-14.17137 -31.31066,-10.0536 -42.51411,-21.25705c-11.20345,-11.20345 -11.75061,-29.83885 -21.25705,-42.51411c-12.02481,-16.03307 -28.34274,-28.34274 -42.51411,-42.51411c-7.08568,-7.08568 -11.75061,-18.08824 -21.25705,-21.25705c-13.44414,-4.48138 -29.06997,4.48138 -42.51411,0c-9.50644,-3.16881 -11.53557,-18.82668 -21.25705,-21.25705c-20.62237,-5.15559 -43.14879,5.15559 -63.77116,0c-9.72148,-2.43037 -11.75061,-18.08824 -21.25705,-21.25705c-13.44414,-4.48138 -28.34274,0 -42.51411,0c-14.17137,0 -28.34274,0 -42.51411,0c-7.08568,0 -16.24672,5.01034 -21.25705,0c-5.01034,-5.01034 6.33763,-18.08824 0,-21.25705c-12.67526,-6.33763 -28.34274,0 -42.51411,0c-7.08568,0 -14.17137,0 -21.25705,0c-7.08568,0 -14.91942,-3.16881 -21.25705,0c-8.96276,4.48138 -12.29429,16.77567 -21.25705,21.25705c-6.33763,3.16881 -18.08824,-6.33763 -21.25705,0c-6.33763,12.67526 6.33763,29.83885 0,42.51411c-3.16881,6.33763 -14.17137,0 -21.25705,0c-7.08568,0 -14.91942,-3.16881 -21.25705,0c-8.96276,4.48138 -14.17137,14.17137 -21.25705,21.25705c-7.08568,7.08568 -16.77567,12.29429 -21.25705,21.25705c-4.43372,8.86743 4.94878,37.56533 0,42.51411c-5.01034,5.01034 -14.17137,0 -21.25705,0c-14.17137,0 -28.34274,0 -42.51411,0c-7.08568,0 -16.24672,-5.01034 -21.25705,0c-5.01034,5.01034 5.01034,16.24672 0,21.25705c-5.01034,5.01034 -16.24672,-5.01034 -21.25705,0c-5.01034,5.01034 0,14.17137 0,21.25705\" data-paper-data=\"{&quot;annotation&quot;:null}\" id=\"smooth_path_e729f50a-f9a1-484e-b77e-2645db6fc60f\" fill=\"none\" stroke=\"#00bfff\" stroke-width=\"21.25705\" stroke-linecap=\"butt\" stroke-linejoin=\"miter\" stroke-miterlimit=\"10\" stroke-dasharray=\"\" stroke-dashoffset=\"0\" font-family=\"sans-serif\" font-weight=\"normal\" font-size=\"12\" text-anchor=\"start\" mix-blend-mode=\"normal\"/></svg>"}}'  if (scene=="0")
    if (scene=="0")
      newAnnotation['on'] = '{"@type"=>"oa:SpecificResource", "full"=>"http://manifests.ydc2.yale.edu/LOTB/canvas/bv11", "selector"=>{"@type"=>"oa:SvgSelector", "value"=>"<svg xmlns=$$http://www.w3.org/2000/svg$$><path xmlns=\"http://www.w3.org/2000/svg\" d=\"M8523.67459,3171.28866c-214.81852,-104.43732 -519.18679,-165.44584 -823.43226,-165.41138c-304.24546,0.03445 -608.36812,61.11188 -823.43226,165.41138c-215.06414,104.29951 -341.06977,251.8211 -341.07681,399.3384c-0.00703,147.51731 125.98453,295.03033 341.07681,399.3384c215.09228,104.30808 522.72403,163.74025 823.43226,165.41138c300.70822,1.67113 606.45179,-60.20713 823.43226,-165.41138c216.98047,-105.20425 341.91271,-252.18349 341.07681,-399.3384c-0.8359,-147.15491 -126.25829,-294.90108 -341.07681,-399.3384z\" data-paper-data=\"{&quot;rotation&quot;:0,&quot;annotation&quot;:null}\" id=\"ellipse_06e8b769-13e7-4809-ab48-7a369924bcaa\" fill-opacity=\"0\" fill=\"#00bfff\" stroke=\"#00bfff\" stroke-width=\"15.50905\" stroke-linecap=\"butt\" stroke-linejoin=\"miter\" stroke-miterlimit=\"10\" stroke-dasharray=\"\" stroke-dashoffset=\"0\" font-family=\"sans-serif\" font-weight=\"normal\" font-size=\"12\" text-anchor=\"start\" mix-blend-mode=\"normal\"/></svg>"}}'
    end


    #newAnnotation['on'] = JSON.parse(newAnnotation['on'])
    #newAnnotation['on'] = '{"@type":"oa:SpecificResource","full":"http://manifests.ydc2.yale.edu/LOTB/canvas/bv11","selector":{"@type":"oa:SvgSelector","value":"<svg/>"}}'

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