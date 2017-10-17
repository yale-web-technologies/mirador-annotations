module IIIFAdapter
  class Anno
    def self.make_array(object)
      return [] if object.nil?
      return object if object.kind_of?(Array)
      [object]
    end

    def self.get_targets(annotation)
      target = JSON.parse(annotation.on)
      self.make_array(target)
    end

    def self.get_resource(annotation)
      resource = JSON.parse(annotation.resource)
      self.make_array(resource)
    end

    ## annotation: an Annotation (model) object
    def initialize(annotation)
      @annotation = annotation
      @targets = self.class.get_targets(annotation)
      @resource = self.class.get_resource(annotation)
    end

    def id
      @annotation.annotation_id
    end

    def type
      @annotation.annotation_type
    end

    def body_text
      resource = get_text_resource
      return resource['chars'] if resource
      nil
    end

    def targets
      @targets
    end

    def target_annotations
      annos = []
      targets.each do |target|
        if target['@type'] === 'oa:Annotation'
          annos += Annotation.where(annotation_id: target['full'])
        end
      end
      annos
    end

    def targeting_annotations
      Annotation.where(canvas: @annotation.annotation_id)
    end

    def resource
      @resource
    end

    def tags
      @resource.select do |r|
        r['@type'] == 'oa:Tag'
      end
    end

    def motivation
      JSON.parse(@annotation.motivation)
    end

  private
    def get_text_resource
      resource = JSON.parse(@annotation.resource)
      resources = self.class.make_array(resource)
      items = resources.select { |item| item['@type'] === 'dctypes:Text' }

      if items.size > 0
        if items.size > 1
          Rails.logger.warn("get_text_resource too many text items: #{items.size}");
        end
        return items[0]
      else
        return nil
      end
    end
  end
end