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
  has_many :annotation_tag_maps, dependent: :delete_all
  has_many :annotation_tags, through: :annotation_tag_maps

  has_many :annotation_lists, through: :list_annotations_map
  has_many :list_annotations_map, foreign_key: :annotation_id, primary_key: :annotation_id, dependent: :destroy
  has_many :canvases, through: :annotation_lists

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

  def annotation_layers
    layers = []
    annotation_lists.each do |list|
      layers.concat(list.annotation_layers)
    end
    layers.uniq
  end

  def getLayersForAnnotation(anno_id)
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

  #==========================================================================

  def self.get_xywh_from_svg(svg_paths, image_width, image_height)
    begin
      bbox = get_bounding_box(svg_paths, image_width, image_height)
    rescue Exception => e
        puts "ERROR calculating bounding box from paths #{svg_paths} - #{e}"
        xywh = "-99,-99,-99,-99"
    else
      x, y, width, height = force_square(bbox, image_width, image_height)
      xywh = [x.to_s, y.to_s, width.to_s, height.to_s].join(',')
    end
  end

  def self.force_square(bbox, image_width, image_height)
    box_x = bbox[:x]
    box_y = bbox[:y]
    box_width = bbox[:width]
    box_height = bbox[:height]

    thumb_width = [box_width, box_height].max
    thumb_height = thumb_width

    if box_x + thumb_width > image_width
      box_x -= box_x + thumb_width - image_width
    end

    if box_y + thumb_height > image_height
      box_y -= box_y + thumb_height - image_height
    end

    [box_x, box_y, thumb_width, thumb_height]
  end

  def self.get_bounding_box(paths, max_width, max_height)
    include Magick

    scale_factor = 10
    paths = paths.map { |path| self.scale_down_path(path, scale_factor) }
    max_width /= scale_factor
    max_height /= scale_factor

    #create a drawing object
    drawing = Magick::Draw.new

    #create a new image for finding out the offset
    canvas = Image.new(max_width, max_height) {self.background_color = 'white' }

    #draw the path into the canvas image
    paths.each { |path| drawing.path path }

    drawing.draw canvas

    #trim the whitespace of the image
    canvas.trim!

    #bounding box information
    { x: canvas.page.x * scale_factor,
      y: canvas.page.y * scale_factor,
      width: canvas.columns * scale_factor,
      height: canvas.rows * scale_factor
    }
  end

  def self.scale_down_path(path, factor)
    path.gsub(/[\d.]+/) do |match|
      (match.to_f / factor).to_s
    end
  end

  ## Recursively follow "on" relation to the end and return all annotations
  ## that targets a canvas directly.
  def self.find_target_annotations_on_canvas(annotation)
    self.find_target_annotations(annotation).select do |a|
      a.on.include?('oa:SvgSelector')
    end
  end

  ## Recursively follow "on" relation to find all transitive target annotations
  def self.find_target_annotations(annotation)
    target_annos = []
    anno = IIIFAdapter::Anno.new(annotation)
    targets = anno.targets.select do |target|
      IIIF::Target.is_annotation(target)  # exclude targets that are canvas fragments
    end
    targets.each do |target|
      target_id = target['full']
      target_annotations = Annotation.where(annotation_id: target_id, active: true)
      if target_annotations.empty?
        puts "ERROR target annotation doesn't exit with id #{target_id}"
      else
        if target_annotations.size > 1
          puts "ERROR duplicate annotation_id #{target_id}"
        end
        target_annotation = target_annotations.first
        target_annos << target_annotation
        target_annos.concat(self.find_target_annotations(target_annotation))
      end
    end
    target_annos
  end
end




