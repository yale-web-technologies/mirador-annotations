require 'json'
class AnnotationList < ActiveRecord::Base
  attr_accessible  :list_id,
                   :list_type,
                   :resources,
                   :within
  def to_iiif
    # get the list's annotation records via the sequencing map table
    @resourcesArr = Array.new
    p 'list_id: ' + list_id
    @annoIds = ListAnnotationsMap.where(list_id:list_id).order(:sequence)
    @annoIds.each do |annoId|
      @Anno = Annotation.where(annotation_id: annoId.annotation_id).first
      @resourceJson = JSON.parse(@Anno.resource)
      @resourcesArr.push(@resourceJson)
    end

    iiif = attributes.clone
    iiif.delete('id')
    iiif.delete('list_id')
    iiif.delete('list_type')
    iiif.delete('resources')
    iiif.delete('within')
    iiif.delete('created_at')
    iiif.delete('updated_at')
    iiif['@id'] = list_id
    iiif['@type'] = list_type
    iiif['@context'] = "http://iiif.io/api/presentation/2/context.json"
    iiif['within'] = within.split(",")
    #iiif['resources'] = JSON.parse(resources) # for inline annotations
    iiif['resources'] = @resourcesArr
    iiif
  end
end
