class ListAnnotationsMap < ActiveRecord::Base
  attr_accessible  :list_id,
                   :sequence,
                   :annotation_id

  def self.setMap within, anno_id
    if !within.nil?
      within.each do |list_id|
        #list_annotation_map = self.where("list_id = ? and annotation_id = ?", list_id, anno_id).first
        list_annotation_map = self.where(list_id: list_id, annotation_id: anno_id).first
        if list_annotation_map.nil?
          newHighSeq = getNextSeqForList(list_id)
          create!(:list_id => list_id, :sequence => newHighSeq, :annotation_id => anno_id)
        else
          p "  map record already exists for annotation: #{anno_id}:  list: #{list_id}"
        end
      end
    end
  end

  def self.getNextSeqForList list_id
    highestSeq = self.where(list_id: list_id).order(:sequence).last
    if !highestSeq.nil?
      nextSeq = highestSeq.sequence + 1
    else
      nextSeq = 1
    end
    nextSeq
  end

  def self.getListsForAnnotation anno_id
    within = Array.new
    @annotationLists = self.where(annotation_id: anno_id)
    @annotationLists.each do |annoList|
      within.push(annoList.list_id)
    end
    within
  end

  def self.getAnnotationsForList list_id
    resources = Array.new
    p "in getAnnotationsForList"
    p "list_id passed in: #{list_id}"
    @annoIds = self.where(list_id: list_id).order(:sequence)
    p "annoIds found in list:#{@annoIds.count}"
    @annoIds.each do |annotation|
      #resources.push(annotation.annotation_id)
      #p "looking for annotation_id: #{annotation.annotation_id}"

      @Anno = Annotation.where(annotation_id: annotation.annotation_id).first
=begin
      @annoJson = Hash.new
      @annoJson['@id'] = @Anno.annotation_id
      @annoJson['@type'] = @Anno.annotation_type
      @annoJson['@context'] = "http://iiif.io/api/presentation/2/context.json"

      p "resource = #{@Anno.resource}"
      #@Anno.resource.gsub!(/\r\n/,"")
      #@Anno.resource.gsub!(/\n/,"")
      #@Anno.resource.chomp
      @annoJson['resource'] = JSON.parse(@Anno.resource)
      #@annoJson['resource'] = @Anno.resource.to_json
      #@annoJson['annotatedBy'] = JSON.parse(@Anno.annotated_by) if !@Anno.annotated_by.blank?
      @annoJson['on'] = @Anno.on
      #resources.push(@annoJson)
=end
     resources.push(@Anno)
    end
    resources
  end

  # return list of annotations only
  def self.getAnnotationListForList list_id
    resources = Array.new
    @annoIds = self.where(list_id: list_id).order(:sequence)
    @annoIds.each do |annotation|
      #resources.push(annotation.annotation_id)
      @Anno = Annotation.where(annotation_id: annotation.annotation_id).first
      @annoJson = Hash.new
      @annoJson['@id'] = @Anno.annotation_id
      resources.push(@annoJson)
    end
    resources
  end

  def self.deleteAnnotationFromList anno_id
    @annotationLists = self.where(annotation_id: anno_id)
    @annotationLists.each do |annoList|
      annoList.destroy
    end
  end

  def self.deleteAnnotationsFromList list_id
    @annotationLists = self.where(list_id: list_id)
    @annotationLists.each do |annoList|
      annoList.destroy
    end
  end
end
