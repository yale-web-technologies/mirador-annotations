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
    p "to_iiif: annotation_id = #{annotation_id}: resource: #{resource}"
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
    #iiif['orderWeight'] =  order_weight
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

end
