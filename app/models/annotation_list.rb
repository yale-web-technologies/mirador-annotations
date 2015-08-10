class AnnotationList < ActiveRecord::Base
  attr_accessible  :list_id,
                   :list_type,
                   :resources,
                   :within,
                   :label,
                   :description,
                   :version
  def to_iiif
    # get the list's annotation records via the sequencing map table
    @resourcesArr = Array.new
    @annoIds = ListAnnotationsMap.where(list_id:list_id).order(:sequence)

    @annoIds.each do |annoId|
      @Anno = Annotation.where(annotation_id: annoId.annotation_id).first
      @annoJson = Hash.new
      @annoJson['@id'] = @Anno.annotation_id
      @annoJson['@type'] = @Anno.annotation_type
      @annoJson['@context'] = "http://iiif.io/api/presentation/2/context.json"
      @annoJson['resource'] = JSON.parse(@Anno.resource)
      #@annoJson['annotatedBy'] = JSON.parse(@Anno.annotated_by) if !@Anno.annotated_by.blank?
      @annoJson['on'] = @Anno.on
      @resourcesArr.push(@annoJson)
    end

    iiif = Hash.new
    iiif['@id'] = list_id
    iiif['@type'] = list_type
    iiif['@context'] = "http://iiif.io/api/presentation/2/context.json"
    iiif['label'] = label if !label.blank?
    iiif['within'] = LayerListsMap.getLayersForList list_id
    iiif['resources'] = @resourcesArr
    iiif
  end

  def to_version_content
    version_content = Hash.new
    version_content['@id'] = list_id
    version_content['@type'] = list_type
    version_content['@context'] = "http://iiif.io/api/presentation/2/context.json"
    version_content['label'] = label if !label.blank?
    version_content['within'] = LayerListsMap.getLayersForList list_id
    version_content
  end
end
