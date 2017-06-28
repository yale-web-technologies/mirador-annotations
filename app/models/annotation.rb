include Magick

class Annotation < ActiveRecord::Base
  attr_accessible :annotation_id,
                  :annotation_type,
                  :motivation,
                  :description,
                  :on,
                  :label,
                  :canvas,
                  :manifest,
                  :resource,
                  :version,
                  :annotated_by,
                  :active,
                  :version,
                  :service_block,
                  :order_weight
  has_many :webacls, foreign_key: "resource_id"

  def to_iiif
    #return if (label.startsWith?=='Tibetan')
    iiif = Hash.new
    #p "to_iiif: annotation_id = #{annotation_id}: resource: #{resource}"
    iiif['@id'] = annotation_id
    iiif['@type'] = annotation_type
    iiif['@context'] = "http://iiif.io/api/presentation/2/context.json"
    #iiif['resource'] = resource
    resource.gsub!(/\n/,"")
    iiif['resource'] = JSON.parse(resource)
    #iiif['resource'] = resource.to_json # becomes blank in mirador
    iiif['within'] = ListAnnotationsMap.getListsForAnnotation annotation_id
    motivation.gsub!(/\"/,'')
    motivation.gsub!(/\]/,'')
    motivation.gsub!(/\[/,'')
    motivation.gsub!(' ','')
    #iiif['motivation'] = motivation
    iiif['motivation'] = motivation.split(",")
    #iiif['annnotatedBy'] = JSON.parse(annotated_by) if !annnotated_by.nil?
    iiif['on'] = on
    #p "anno_id = #{annotation_id} and on = #{on}"
    begin
    #if (on.start_with?("{"))
    if (on.start_with?("{") or on.start_with?("["))
      on.gsub!(/=>/,":")
      iiif['on'] = JSON.parse(on)
    end
    rescue
      p "error in to_iiif: could not json.parse [on] for anno #{annotation_id}"
    end
    iiif#.to_json
  end

  def to_version_content
    version_content = Hash.new
    version_content['@id'] = annotation_id
    version_content['@type'] = annotation_type
    version_content['@context'] = "http://iiif.io/api/presentation/2/context.json"
    version_content['motivation'] = motivation
    version_content['within'] = ListAnnotationsMap.getListsForAnnotation annotation_id
    version_content['resource'] = resource.to_json
    #version_content['annnotatedBy'] = annotated_by.to_json
    version_content['on'] = on
    version_content.to_json
  end

  def to_preAuth
    preAuth = Hash.new
    preAuth['@id'] = annotation_id
    preAuth['serviceBlock'] = service_block
    p preAuth.to_s
    preAuth.to_json
  end

  # not used
  def to_solr
    # separate out resource into separate feed, for multiple resource stanzas add a within-resource id (a-z, 1-9 or random)
    solr = Hash.new
    #p "to_solr: annotation_id = #{annotation_id}: resource: #{resource}"
    solr['@id'] = annotation_id
    solr['@type'] = annotation_type
    solr['@context'] = "http://iiif.io/api/presentation/2/context.json"
    resource.gsub!(/\n/,"")
    solr['resource'] = JSON.parse(resource)
    #solr['within'] = ListAnnotationsMap.getListsForAnnotation annotation_id
    motivation.gsub!(/\"/,'')
    motivation.gsub!(/\]/,'')
    motivation.gsub!(/\[/,'')
    motivation.gsub!(' ','')
    solr['motivation'] = motivation.split(",")
    if !(defined?(annnotated_by)).nil?
      if !annnotated_by.nil?
        solr['annnotatedBy'] = JSON.parse(annotated_by)
      end
    end

    # todo: just send on[full]. If on['full'] is a canvas leave it blank]
    #solr['on'] = on
    #onJSON = JSON.parse(on)
    onJSON = JSON.parse(on.gsub(/=>/,":"))

    #p "getSolrFeed: full = #{onJSON['full']} for annotation #{annotation_id}"

    if onJSON['full'].include?("/canvas/")
      solr['on'] = ''
    else
      solr['on'] = onJSON['full']
    end

    # todo: add original canvas, layers ?and manifest into?
    @canvas_id = onJSON['full']
    if (!onJSON['full'].include?('/canvas/'))
      @annotation = Annotation.where(annotation_id:onJSON['full']).first
      @canvas_id = getTargetingAnnosCanvas(@annotation)
    end
    solr['canvas_id'] = @canvas_id

    #todo: add layers
    layers = Array.new
    solr['layers'] = getLayersForAnnotation annotation_id

    solr#.to_json
  end

  def getLayersForAnnotation anno_id
    #p "in Annotation.getLayersForAnnotation: annotation_id = #{anno_id}"
    lists = ListAnnotationsMap.getListsForAnnotation anno_id
    #p "getLayers: list count = #{lists.count}"
    layerArray = Array.new
    lists.each do |list_id|
      #p "getLayers: processing list: #{list_id}"
      layerLabels = LayerListsMap.getLayerLabelsForList list_id
      #p "getLayers: number of layers: #{layerLabels.size} for this list"
      layerLabels.each do |layerLabel|
        #p "getLayers: layer for this list: #{layerLabel}" if !layerArray.include?(layerLabel)
        layerArray.push(layerLabel) if !layerArray.include?(layerLabel)
      end
      #p ""
    end
    layerArray
  end

  #  move backwards from an annotations' target until the last (or first) targeted anno, then return this one's canvas
  def self.getTargetingAnnosCanvas inputAnno
    if inputAnno.nil?
      p "there is no target anno!"
      return nil
    end
    #p "in getTargetingAnnosCanvas: #{inputAnno.annotation_id}"
    return(inputAnno.canvas) if (inputAnno.canvas.to_s.include?('/canvas/'))
    targetAnnotation = Annotation.where(annotation_id:inputAnno.canvas).first
    getTargetingAnnosCanvas targetAnnotation
  end


  #==========================================================================

  def self.get_xywh_from_svg svg_path, height, width
    return if svg_path==''
    begin
      bbox = get_bounding_box(svg_path, height, width)
    rescue
        xywh = "-99,-99,-99,-99"
    else
      x = bbox[:x]
      y = bbox[:y]
      width = bbox[:width]
      height = bbox[:height]
      # force square using the larger of width and height
      width = [width, height].max
      height = width

      #puts "x="+x.to_s
      #puts "y="+y.to_s
      #puts "width="+width.to_s
      #puts "height="+height.to_s
      #puts ""
      #puts "svg_path = #{svg_path}"
      #puts ""

      xywh = [x.to_s, y.to_s, width.to_s, height.to_s].to_csv
    end
  end

  def self.get_bounding_box(path,height,width)
    include Magick

    #create a drawing object
    drawing = Magick::Draw.new

    #create a new image for finding out the offset
    #canvas = Image.new(16000,16000) {self.background_color = 'white' }
    canvas = Image.new(height,width) {self.background_color = 'white' }

    #draw the path into the canvas image
    drawing.path path
    drawing.draw canvas

    #trim the whitespace of the image
    canvas.trim!

    #bounding box information
    { :x=> canvas.page.x, :y=>canvas.page.y, :width=> canvas.columns, :height=> canvas.rows}
  end


  # this expects to be called from the controller or a rake task, and receives a csv object as a parameter
  # todo: should also receive an allorDelta param from either rake task or controller REST call
  def self.feedAnnosNoResource (csv) #,allorDelta)
    p "in Annotation.feedAnnosNoResource!"
    host_url_prefix = Rails.application.config.hostUrl
    #host_url_prefix = 'http://localhost:5000/annotations'
    #allOrDelta = "all" if allOrDelta.nil? or allOrDelta == '0'
    p "host_url_prefix = #{host_url_prefix}"
    context = "http://iiif.io/api/presentation/2/context.json"

    #if allOrDelta == 'all'
      @annotations = Annotation.all
      #@annotations = Annotation.where("annotation_id like ?", "%#{host_url_prefix}%")
      #@annotations = Annotation.where("annotation_id like ? and resource not like ? and resource not like ?" , "%#{host_url_prefix}%","%WordDocument%","OfficeDocumentSettings")

    p "annotations found: #{@annotations.count}"
    #else
    #  @annotations = Annotation.where(['updated_at > ?', DateTime.now-allOrDelta.to_i.days])
    #end

    # Headers
    csv << ["annotation_id", "annotation_type", "context", "on", "canvas", "motivation","layers", "bounding_box", "panel", "chapter", "scene", "display_name"]

    count = 0
    @annotations.each do |anno|
      count += 1

       next if count > 30

      # check anno.on and canvas
      p "#{count}) #{anno.annotation_id}"
      next if !anno.on.start_with?('{') && !anno.on.start_with?('[')
      next if anno.canvas.nil?
      @feedOn = nil
      @canvas_id = nil
      @targetAnno = anno

      # if anno is not directly on a canvas: set feedOn = anno.canvas and set @canvas_id to original canvas

      if !anno.on.start_with?('[')            # on is not an array
        if !anno.canvas.include?("/canvas/")  # on is not a canvas
          #@feedOn = anno.canvas
          # get original canvas
          @targetAnno = Annotation.getTargetedAnno(anno)
          if !@targetAnno.nil?
            #@canvas_id = @targetAnno.canvas
            @feedOn = @targetAnno.canvas
          end
        else
          @canvas_id = anno.canvas
        end
      else
        # todo: I will have to deal with 'on' arrays; that is how Mirador is sending them now
        p "on is on an array for anno: #{anno.annotation_id}"
      end
      #p "@canvas_id: #{@canvas_id}  feedOn: #{@feedOn}" #if !@feedOn.nil?

      xywh = anno.service_block.gsub(/\r\n?/, "") unless anno.service_block.nil?

      layers = Array.new

      ## shouldn't it be anno.getLayersForAnnotation??
      layers = @targetAnno.getLayersForAnnotation @targetAnno.annotation_id unless @targetAnno.nil?

      if !layers.nil?
        #p "layers = #{layers} for #{anno.annotation_id}" if layers.size > 0
        layers = layers.to_s.gsub(/"/,'')
        layers = layers.gsub(/\[/,'')
        layers = layers.gsub(/]/,'')
      else
        p "no layers for anno: #{anno.annotation_id}"
      end

      anno.motivation.gsub!(/"/,'')

      panel = ''
      chapter = ''
      scene = ''
      startSceneNumberIndex = 0
      sceneNumberLength = 0
      fromSequenceOn = ''

#=begin
      #for LOTB panels, chapters and scenes
      annoLength = anno.annotation_id.length
      panelIndex = anno.annotation_id.index("Panel")
      chapterIndex = anno.annotation_id.index("Chapter")
      sceneIndex = anno.annotation_id.index("Scene")
      if !sceneIndex.nil?
        startSceneNumberIndex = sceneIndex+6
        fromSceneNumberOn = anno.annotation_id[startSceneNumberIndex..annoLength]

        if fromSceneNumberOn.index("_")
          sceneNumberLength = fromSceneNumberOn.index("_") -1
          #sceneNumberLength = fromSceneNumberOn
          sceneNumber = anno.annotation_id[startSceneNumberIndex..startSceneNumberIndex + sceneNumberLength]
          fromSequenceOn = "Sequence " + fromSceneNumberOn[fromSceneNumberOn.index("_")+1..fromSceneNumberOn.length]
          p "fromSequenceOn = #{fromSequenceOn}"
        else
          sceneNumber = fromSceneNumberOn
        end
      else
        sceneIndex = anno.annotation_id.length
      end

      begin
        panel = anno.annotation_id[panelIndex..chapterIndex-2].gsub!(/_/," ")
        p "panel = #{panel}"
        # To-do
        # qualify block below: if !panel.nil?
        panel = "Panel 1" if panel=="Panel A"
        panel = "Panel 2" if panel=="Panel B"
        chapter = anno.annotation_id[chapterIndex..sceneIndex-2].gsub!(/_/," ")
        scene = "Scene " + sceneNumber if !sceneNumber.nil?
        # end LOTB panels, chapters and scenes
      rescue
        p "panel, chapter or scene error"
      end

      #Set Display Name
      #dispName = anno.annotation_id
      dispName = " "
      if fromSequenceOn != ''
        #dispName = anno.annotation_id[0..startSceneNumberIndex+sceneNumberLength] + ' ' + fromSequenceOn
        dispName = panel + " " +  chapter + " " + scene + " " + fromSequenceOn
        dispName.gsub!(/_/," ")
      end
      p ''
      #end

#=end
      csv << [anno.annotation_id, anno.annotation_type, context, @feedOn, @canvas_id,anno.motivation,layers, xywh.to_s, panel, chapter, scene, dispName]
    end
  end

  def self.getTargetedAnno inputAnno
    #p "in Annotation.getTargetedAnno: annoId = #{inputAnno.annotation_id}"
    onN = inputAnno.on
    onN = onN.gsub(/=>/,':')# if onN.include?("=>")
    onJSON = JSON.parse(onN)
    targetAnnotation = Annotation.where(annotation_id:onJSON['full']).first
    return if targetAnnotation.nil?
    return(targetAnnotation) if (targetAnnotation.on.to_s.include?("oa:SvgSelector"))
    getTargetedAnno targetAnnotation
  end

  def self.feedAnnosResourceOnly (csv) #,allorDelta)
    p "in Annotation.feedAnnosNoResource!"
    host_url_prefix = Rails.application.config.hostUrl
    #host_url_prefix = 'http://localhost:5000/annotations'
    #p "host_url_prefix = #{host_url_prefix}"
    allOrDelta = "all" if allOrDelta.nil? or allOrDelta == '0'

    #if allOrDelta == 'all'
      #@annotations = Annotation.all
      #@annotations = Annotation.where("annotation_id like ?", "%#{host_url_prefix}%")
      @annotations = Annotation.where("annotation_id like ? and resource not like ? and resource not like ?" , "%#{host_url_prefix}%","%WordDocument%","OfficeDocumentSettings")
      p "annotations found: #{@annotations.count}"
    #else
    #  @annotation = Annotation.where(['updated_at > ?', DateTime.now-allOrDelta.to_i.days])
    #end
    count = 0
    #headers
    csv << ["annotation_id","resource_id", "type", "format", "chars"]
    @annotations.each do |anno|
      count += 1
      p "#{count}) #{anno.annotation_id}"
      resource_id = anno.annotation_id + "_" + SecureRandom.uuid
      resource = anno.resource.gsub(/=>/,":")
      resourceJSON = JSON.parse(resource)

      if !resource.start_with?('[')
        chars = ActionView::Base.full_sanitizer.sanitize(resourceJSON{"chars"})
        csv << [anno.annotation_id, resource_id, resourceJSON["@type"], resourceJSON["format"], chars]
      else
        chars = ActionView::Base.full_sanitizer.sanitize(resourceJSON[0]["chars"])
        csv << [anno.annotation_id, resource_id, resourceJSON[0]["@type"], resourceJSON[0]["format"], chars]
      end
    end
  end

end




