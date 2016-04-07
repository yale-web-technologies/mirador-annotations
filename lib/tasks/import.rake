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
  #Sun of Faith - Structured Chapters - ch. 19.csv
  # Assumption: will be loaded by worksheet per chapter: first column holds panel, second column holds chapter, third column holds scene
  # Iterating through sheet needs to check for new scene, but not for new panel or chapter
  task :LoTB_annotations => :environment do
    require 'csv'
    #@ru = request.original_url.split('?').first
    #@ru += '/'   if !ru.end_with? '/'
    #@ru = "localhost"
    @ru = "mirador-annotations-lotb.herokuapp.com"
    labels = Array.new
    i = 0
    j=0
    panel = " "
    chapter = " "
    scene = " "
    lastScene = 0
    nextSceneSeq = 0
    makeLanguageLayers
    CSV.foreach('importData/lotb26_norm.txt') do |row|
      i+=1;
      puts "i = #{i}"
      # store the labels from row 0
      puts 'row.size = ' + row.size.to_s
      # First Row: set labels from column headings
      if (i==1)
        while j <= row.size
          labels[j] = row[j]
          puts "labels[#{j}] = #{labels[j]}"
          j += 1
        end
      else
        # Second Row: set and create Panel and Chapter
        if (i==2)
          # - layer for Panel (row[0]),
          panel = row[0]
          createNewPanel row
          # - layer,list and annotation for Chapter (row[1])
          chapter = row[1]
          createNewChapter row
        end
        # check for new Scene
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

        # create the Tibetan transcription annotation for this row ([5], [7] and [9])
        #annotation_id = Socket.gethostname + "/annotations/"+ "Panel_" + panel + "_Chapter_" + chapter + "_Scene_" + scene + "_" + nextSceneSeq.to_s + "_Tibetan"
        #annotation_id = "localhost"         + "/annotations/"+ "Panel_" + panel + "_Chapter_" + chapter + "_Scene_" + scene + "_" + nextSceneSeq.to_s + "_Tibetan"
        annotation_id = @ru + "/annotations/"+ "Panel_" + panel + "_Chapter_" + chapter + "_Scene_" + scene + "_" + nextSceneSeq.to_s + "_Tibetan"
        annotation_type = "oa:annotation"
        motivation = "oa:transcribing"
        label = "Tibetan transcription"
        description = ""
        on = @ru + "/annotations/"+ "Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" + scene #+ "_0"
        #canvas = @ru  + "/canvas/" + "SunOfFaith_Panel_B"
        canvas = "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
        manifest = "tbd"
        chars = Hash.new
        j = 0
        #build chars with hash of labels and values
        while j < row.size
          unless (j==6 || j==8 || j==10)
            chars[labels[j]] = row[j]
            puts chars[labels[j]]
          end
          j += 1
        end

        resource = '[{"@type":"dctypes:Text","format":"text/html","chars":' + chars.to_json + "}]"
        active = true
        version = 1
        @annotation = Annotation.create(annotation_id: annotation_id, annotation_type: annotation_type, motivation: motivation, label:label, on: on, canvas: canvas, manifest: manifest,  resource: resource, active: active, version: version)
        result = @annotation.save!(options={validate: false})
        sceneList =  @ru + "/lists/Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" + scene
        languageList = @ru + "/lists/Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" +scene + ":Tibetan"
        withinArray = Array.new
        withinArray.push(sceneList)
        withinArray.push(languageList)
        ListAnnotationsMap.setMap withinArray, @annotation['annotation_id']

        # create the English translation annotation for this row ([6], [8] and [10])
        #annotation_id = Socket.gethostname + "/annotations/"+ "Panel_" + panel + "_Chapter_" + chapter + "_Scene_" + scene + "_" + nextSceneSeq + "_English"
        annotation_id = "localhost" + "/annotations/"+ "Panel_" + panel + "_Chapter_" + chapter + "_Scene_" + scene + "_" + nextSceneSeq.to_s + "_English"
        annotation_id = @ru + "/annotations/"+ "Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" + scene + "_" + nextSceneSeq.to_s + "_English"
        annotation_type = "oa:annotation"
        motivation = "oa:translating"
        label = "English Translation"
        description = " "
        on = @ru + "/annotations/"+ "Panel_"  + "_Chapter_" +"_Scene_" + scene #+ "_0"
        #canvas = @ru  + "/canvas/" + "SunOfFaith_Panel_B"
        canvas = "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
        manifest = "tbd"
        chars = Hash.new
        j = 0
        #build chars with hash of labels and values
        while j < row.size
          unless (j==5 || j==7 || j==9)
            chars[labels[j]] = row[j]
            puts chars[labels[j]]
          end
          j += 1
        end
        resource = '[{"@type":"dctypes:Text","format":"text/html","chars":' + chars.to_json + "}]"
        active = true
        version = 1
        @annotation = Annotation.create(annotation_id: annotation_id, annotation_type: annotation_type, motivation: motivation, label:label, on: on, canvas: canvas, manifest: manifest,  resource: resource, active: active, version: version)
        result = @annotation.save!(options={validate: false})
        sceneList =  @ru + "/lists/Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" + scene
        languageList = @ru + "/lists/Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" +scene + ":English"
        withinArray = Array.new
        withinArray.push(sceneList)
        withinArray.push(languageList)
        ListAnnotationsMap.setMap withinArray, @annotation['annotation_id']
      end
    end
  end


  def makeLanguageLayers
    layer = Hash.new
    layer['layer_id'] = @ru + "/layers/Tibetan"
    layer['layer_type'] = "sc:layer"
    layer['label'] = "Sun of Faith Tibetan"
    layer['motivation'] = " "
    layer['description'] = "Sun of Faith Tibetan Transcriptions"
    layer['license'] = "http://creativecommons.org/licenses/by/4.0/"
    layer['version'] = " "
    createNewLayer layer

    layer = Hash.new
    layer['layer_id'] = @ru + "/layers/English"
    layer['layer_type'] = "sc:layer"
    layer['label'] = "Sun of Faith English"
    layer['motivation'] = " "
    layer['description'] = "Sun of Faith English Transcriptions"
    layer['license'] = "http://creativecommons.org/licenses/by/4.0/"
    layer['version'] = " "
    createNewLayer layer
  end

  def createNewPanel row
    layer = Hash.new
    layer['layer_id'] = @ru + "/layers/Panel_" + row[0]
    layer['layer_type'] = "sc:layer"
    layer['label'] = "Panel " + row[0]
    layer['motivation'] = " "
    layer['description'] = "Sun of Faith Panel " + row[0]
    layer['license'] = "http://creativecommons.org/licenses/by/4.0/"
    layer['version'] = " "
    createNewLayer layer
  end

  def createNewChapter row
    #create new layer, list and rendering annotation for new Chapter
    layer = Hash.new
    layer['layer_id'] = @ru + "/layers/Panel_" + row[0] + "_Chapter_" + row[1]
    layer['layer_type'] = "sc:layer"
    layer['motivation'] = " "
    layer['label'] = "Panel: " + row[0] + " Chapter: " + row[1]
    layer['description'] = "Sun of Faith Panel " + row[0]+ " Chapter: " + row[1]
    layer['license'] = "http://creativecommons.org/licenses/by/4.0/"
    layer['version'] = " "
    createNewLayer layer

    list = Hash.new
    list['list_id'] = @ru + "/lists/Panel_" + row[0] + "_Chapter_" + row[1]
    list['list_type'] = "sc:list"
    list['label'] = "Panel: " + row[0] + " Chapter: " + row[1]
    list['description'] = "Panel: " + row[0] + " Chapter: " + row[1]
    list['version'] = " "
    panelLayer =  @ru + "/layers/Panel_" + row[0]
    thisLayer   = @ru + "/layers/Panel_" + row[0] + "_Chapter_" + row[1]
    withinArray = Array.new
    withinArray.push(panelLayer)
    withinArray.push(thisLayer)
    list['within'] = withinArray
    createNewList list

    # create the Chapter annotation (for svg) (no scene)
    annotation_id = @ru + "/annotations/Panel_" + row[0] + "_Chapter_" + row[1]
    newAnnotation = Hash.new
    newAnnotation['annotation_id'] = annotation_id
    newAnnotation['annotation_type'] = "oa:annotation"
    newAnnotation['motivation'] =""
    newAnnotation['on'] = @ru + "/annotations/"+ "Panel_" + row[0] + "_Chapter_" + row[1]
    newAnnotation['description'] = "Panel: " + row[0] + " Chapter: " + row[1]
    newAnnotation['annotated_by'] = "annotator"
    newAnnotation['canvas']  = "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
    newAnnotation['manifest'] = "tbd"
    newAnnotation['resource']  = ""
    newAnnotation['active'] = true
    newAnnotation['version'] = 1
    thisList = @ru + "/lists/Panel_" + row[0] + "_Chapter_" + row[1]
    withinArray = Array.new
    withinArray.push(thisList)
    newAnnotation['within'] = withinArray
    createNewRenderingAnnotation newAnnotation
  end

  def createNewScene row
    # create new list ChapterX_SceneY and attach to layers PanelB and Chapter_X
    scene = row[2]
    scene = "0" if (scene.nil?)

    list = Hash.new
    list['list_id'] = @ru + "/lists/Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" +scene
    list['list_type'] = "sc:list"
    list['label'] = "Panel:" + row[0] + " Chapter: " + row[1]
    list['description'] = "Sun of Faith Panel: " + row[0] + " Chapter: " + row[1] + " Scene: " +scene
    list['version'] = " "
    panelLayer =  @ru + "/layers/Panel_" + row[0]
    thisLayer   = @ru + "/layers/Panel_" + row[0] + "_Chapter_" + row[1]
    withinArray = Array.new
    withinArray.push(panelLayer)
    withinArray.push(thisLayer)
    list['within'] = withinArray
    createNewList list

    # create new annotation ChapterXSceneY (for svg) and attach to lists for ChapterX and ChapterXSceneY
    annotation_id = @ru + "/annotations/Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" + scene
    newAnnotation = Hash.new
    newAnnotation['annotation_id'] = annotation_id
    newAnnotation['annotation_type'] = "oa:annotation"
    newAnnotation['motivation'] =" "
    newAnnotation['on'] = @ru + "/annotations/"+ "Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" + scene #+ "_0"
    newAnnotation['description'] = "Panel: " + row[0] + " Chapter: " + row[1] + " Scene: " + scene
    newAnnotation['annotated_by'] = "annotator"
    newAnnotation['canvas']  = "http://manifests.ydc2.yale.edu/LOTB/canvas/bv11"
    newAnnotation['manifest'] = "tbd"
    newAnnotation['resource']  = ""
    newAnnotation['active'] = true
    newAnnotation['version'] = 1
    thisList = @ru + "/lists/Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" + scene
    chapterList = @ru + "/lists/Panel_" + row[0] + "_Chapter_" + row[1]
    withinArray = Array.new
    withinArray.push(thisList)
    withinArray.push(chapterList)
    #newAnnotation['within'] = withinArray
    #createNewRenderingAnnotation newAnnotation
    createNewRenderingAnnotation newAnnotation withinArray

    # create Tibetan and English lists for this scene
    list = Hash.new
    list['list_id'] = @ru + "/lists/Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" +scene + ":Tibetan"
    list['list_type'] = "sc:list"
    list['label'] = "Panel:" + row[0] + " Chapter: " + row[1]
    list['description'] = "Sun of Faith: Panel: " + row[0] + " Chapter: " + row[1] + " Scene: " +scene + ":Tibetan"
    list['version'] = " "
    languageLayer =   @ru + "/layers/Tibetan"
    withinArray = Array.new
    withinArray.push(languageLayer)
    list['within'] = withinArray
    createNewList list

    list = Hash.new
    list['list_id'] = @ru + "/lists/Panel_" + row[0] + "_Chapter_" + row[1] + "_Scene_" +scene + ":English"
    list['list_type'] = "sc:list"
    list['label'] = "Panel: " + row[0] + " Chapter: " + row[1]
    list['description'] = "Sun of Faith: Panel:" + row[0] + " Chapter: " + row[1] + " Scene: " +scene + ":English"
    list['version'] = " "
    languageLayer =   @ru + "/layers/English"
    withinArray = Array.new
    withinArray.push(languageLayer)
    list['within'] = withinArray
    createNewList list
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
  end

  def createNewRenderingAnnotation newAnnotation, withinArray
    annotations = Annotation.where(annotation_id: newAnnotation['annotation_id']).first
    if (annotations.nil?)
      @annotation = Annotation.create(newAnnotation)
      #ListAnnotationsMap.setMap newAnnotation['within'], newAnnotation['annotation_id']
      ListAnnotationsMap.setMap withinArray, newAnnotation['annotation_id']
    end
  end


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