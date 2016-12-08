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
    if (on.start_with?("{"))
      iiif['on'] = JSON.parse(on.gsub(/=>/,":"))
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
    lists = ListAnnotationsMap.getListsForAnnotation anno_id
    layerArray = Array.new
    lists.each do |list_id|
      layerLabels = LayerListsMap.getLayerLabelsForList list_id
      layerLabels.each do |layerLabel|
        layerArray.push(layerLabel) if !layerArray.include?(layerLabel)
      end
    end
    layerArray
  end

  #  move backwards from an annotations' target until the last (or first) targeted anno, then return this one's canvas
  def getTargetingAnnosCanvas inputAnno
    return(inputAnno.canvas) if (inputAnno.canvas.to_s.include?('/canvas/'))
    targetAnnotation = Annotation.where(annotation_id:inputAnno.canvas).first
    getTargetingAnnosCanvas targetAnnotation
  end

  def self.get_xywh_from_svg svg_path
    bbox = get_bounding_box(svg_path)
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

  def self.get_bounding_box(path)
    include Magick

    #create a drawing object
    drawing = Magick::Draw.new

    #create a new image for finding out the offset
    canvas = Image.new(6000,9000) {self.background_color = 'white' }

    #draw the path into the canvas image
    drawing.path path
    drawing.draw canvas

    #trim the whitespace of the image
    canvas.trim!

    #bounding box information
    { :x=> canvas.page.x, :y=>canvas.page.y, :width=> canvas.columns, :height=> canvas.rows}

  end

end
