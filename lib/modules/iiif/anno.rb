module IIIF
  class Anno
    ## annotation: an Annotation (model) object
    def initialize(annotation)
      @annotation = annotation
    end

    def id
      @annotation.annotation_id
    end

    def body_text
      resource = get_text_resource
      return resource['chars'] if resource
      nil
    end

    def targets
      target = JSON.parse(sanitize_json(@annotation.on))
      makeArray(target)
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

  private
    def get_text_resource
      resource = JSON.parse(@annotation.resource)
      resources = makeArray(resource)
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

    def makeArray(object)
      return [] if object.nil?
      return object if object.kind_of?(Array)
      [object]
    end

    def sanitize_json(json)
      json2 = json.gsub('\n', '\\n')
      json2.gsub('=>', ':')
    end
  end
end