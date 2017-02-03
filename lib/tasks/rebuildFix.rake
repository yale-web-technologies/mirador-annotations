namespace :rebuild_fix do
  desc "rebuild fix incorrect layers in list_annotations_maps"
  task :fix_rebuild => :environment do
  #task :fix_rebuild, [:env] => :environment do |t, args|
    #env = args.env
    #p 'env: ' + env
    migrationDateTime = '2016-12-21 00:00:00.00000'
    @host = Rails.application.config.hostUrl
    puts "Current env host variable is #{ENV['IIIF_HOST_URL']}"
    @host = 'http://annotations.ten-thousand-rooms.yale.edu/' if @host.nil?
    @host += '/'   if !@host.end_with? '/'
    p "@host= #{@host}"

    count=0
    # get target list_annotations_maps and set up loop
    #sourceAnnoLists = ListAnnotationsMap.where("updated_at < ?", migrationDateTime)
    # first pass: KZJY canvas annos
    #sourceAnnoLists = ListAnnotationsMap.where("list_id like ?","%KZJY03%")
    # do %KZJY01-003 is mapped to http://manifest.tenthousandrooms.yale.edu/node/311/canvas/14191
    #newAnnoLists = ListAnnotationsMap.where("list_id like ? and updated_at > ?","%14191", migrationDateTime)  # chap1 p 3: done
    #newAnnoLists = ListAnnotationsMap.where("list_id like ? and updated_at > ?","%14201", migrationDateTime)  # chap1 p 5: KZJY01-005: done (had to add layer group rec for commentary for one anno)
    #newAnnoLists = ListAnnotationsMap.where("list_id like ? and updated_at > ?","%14211", migrationDateTime)  # chap1 p 7: KZJY01-007:  done
    #newAnnoLists = ListAnnotationsMap.where("list_id like ? and updated_at > ?","%14216", migrationDateTime)  # chap1 p 8: KZJY01-008

    # do all migrated records (6309)
    newAnnoLists = ListAnnotationsMap.where("updated_at > ?",migrationDateTime)  # chap1 p 5: KZJY01-005: done (had to add layer group rec for commentary for one anno)

    p "newAnnoLists.count = #{newAnnoLists.count}"

    newAnnoLists.each do |newAnnoList|
      count = count + 1
      #exit if count > 9

      p "->#{count}) anno_id = #{newAnnoList.annotation_id}"
      p "->#{count}) list_id = #{newAnnoList.list_id}"
      next if count < 2325
      #oldAnnoListId = newAnnoList.list_id

      if newAnnoList.updated_at < migrationDateTime
        p "  ** this listAnnoMap was updated at #{sourceAnnoList.updated_at}, before migration date so being skipped"
        next
      end

      # parse out the annotation_id to get the last uid part
      annoStart = newAnnoList.annotation_id.index('/annotations/')# + 1 
      annoUid = newAnnoList.annotation_id[annoStart..newAnnoList.annotation_id.length]
      p "     annoUid = #{annoUid}"

      # to get the correct layer, find the (latest) pre-migration listAnnosMaps record for this post-migration list_id
      # have to map to the old canvas_id and reconstruct the listId to search???? No
      targetAnnoList = ListAnnotationsMap.where("annotation_id like ? and updated_at < ?", "%#{annoUid}", migrationDateTime).order(updated_at: :desc).first
      #p "targetAnnoList.count = #{targetAnnoList.count}"
      p "targetAnnoList annotation_id = #{targetAnnoList.annotation_id}"
      p "targetAnnoList list_id = #{targetAnnoList.list_id}"

      # parse out the layerId of the targetId
      if !targetAnnoList.list_id.include?('/lists/')
        p "Skipping: annoList: #{newAnnoList.list_id}  because targetAnnoList:  #{targetAnnoList.list_id} does not contain '/lists/'"
        next
      end
      layerPartOfListIdStart = targetAnnoList.list_id.index('/lists/') + 7
      #p "       targetAnnoList.list_id = #{targetAnnoList.list_id}"
      #p "       layerPartOfListIdStart = #{layerPartOfListIdStart}"

      layerPartOfListIdEnd = targetAnnoList.list_id.index('_http:') - 1
      #p "       layerPartOfListIdEnd = #{layerPartOfListIdEnd}"

      targetLayerId = targetAnnoList.list_id[layerPartOfListIdStart..layerPartOfListIdEnd]
      p "       targetLayerId = #{targetLayerId}"

      # look up corresponding Layer_id from LayerMapping
      layerMapping = LayerMapping.where(layer_id: targetLayerId).first
      if layerMapping.nil?
        p "       no new layer for target layer: #{targetLayerId}"
        next
      else
        mappedTargetLayerId = layerMapping.new_layer_id
        p "       mappedTargetLayerId = #{mappedTargetLayerId}"
      end


      # re-construct the list_id  using mappedTargetLayerId and already remapped canvas from post-migration targetAnnoList
      # sample list_id for ref:
      #"http://annotations.ten-thousand-rooms.yale.edu/lists/http://manifest.tenthousandrooms.yale.edu/layers/251_http://manifest.tenthousandrooms.yale.edu/node/306/canvas/13181"
      p "            current newAnnoList.list_id for migrated listAnnoMaps record: #{newAnnoList.list_id}"

      indexLists = newAnnoList.list_id.index('/lists/') + 6
      indexCanvasIdStart = newAnnoList.list_id.index('_')
      indexLength = newAnnoList.list_id.length
      host_prefix = newAnnoList.list_id[0..indexLists]
      canvas_id = newAnnoList.list_id[indexCanvasIdStart+1..indexLength]
      newListId = host_prefix + mappedTargetLayerId + '_' + canvas_id
      p "            new corrected newAnnoList.list_id for migrated listAnnoMaps record: #{newListId}"

      # update the list_annotations_maps record to have the now-correct layer
      #targetAnnoList.update_columns(list_id: newListId, sequence: targetAnnoList.sequence)
      newAnnoList.update_columns(list_id: newListId, sequence: targetAnnoList.sequence)

      # remove the old list_anno_maps record with the wrong layer created in the migration ( or anno will still show up under old layer)
      #newAnnoList.destroy

      # check that there is an annotationList record for this new list, if not create it and the layer_lists_maps record
      checkListExists newListId, mappedTargetLayerId, canvas_id
    end

  end

  def checkListExists list_id, layer_id, canvas_id
    @annotation_list = AnnotationList.where(list_id: list_id).first
    if @annotation_list.nil?
      p "checkListExists: annotationList not found for #{list_id}"
      createAnnotationListForMap(list_id, layer_id, canvas_id)
    else
      p "checkListExists: annotationList found for #{list_id}"
    end
  end

  def createAnnotationListForMap list_id, layer_id, canvas_id
    @list = Hash.new
    @list['list_id'] = list_id
    @list['list_type'] = "sc:annotationlist"
    @list['label'] = "Annotation List for: #{canvas_id}"
    @list['description'] = ""
    @list['version'] = 1
    @within = Array.new
    @within.push(layer_id)
    p "test run: about to create list and setmaps for: #{list_id}"

    LayerListsMap.setMap @within,@list['list_id']
    #create_list_acls_via_parent_layers @list['list_id']
    @annotation_list = AnnotationList.create(@list)
  end

  # codeStash:
  # get the remapped canvas_id from the new one
  # Not used , now we are spinning through new ones and finding the old ones (target)to get the correct layer, not the old ones and gtting new canvases
  # http://localhost:5000/lists/http://localhost:5000/layers/Scenes_http://manifests.ydc2.yale.edu/LOTB/canvas/panel_01
  #CanvasPartOfListIdStart = targetAnnoList.list_id.index('_') + 1
  #newCanvasId = targetAnnoList.list_id[CanvasPartOfListIdStart..targetAnnoList.list_id.length]

end

