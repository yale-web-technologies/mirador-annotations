module IIIF
  class Target
    # true if the target is a canvas
    def self.is_canvas(target)
      target['@type'] != 'oa:Annotation'
    end

    # true if the target is an annotation (as as opposed to a canvas fragment)
    def self.is_annotation(target)
      target['@type'] == 'oa:Annotation'
    end

    ## target: an JSON_LD object representing a target ("on")
    def initialize(target)
      @target = target
    end

    def is_annotation
      self.class.is_annotation(@target)
    end
  end
end