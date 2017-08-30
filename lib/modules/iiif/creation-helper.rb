module IIIF
  LAYER_KEY_ENGLISH = :english
  LAYER_KEY_TIBETAN = :tibetan
  LAYER_KEY_ENGLISH_MANUAL = :english_manual
  LAYER_KEY_TIBETAN_MANUAL = :tibetan_manual
  LAYER_KEY_ENGLISH_INSCRIPTION = :english_inscription
  LAYER_KEY_TIBETAN_INSCRIPTION = :tibetan_inscription
  LAYER_KEY_CANONICAL_SOURCE = :canonical_source
  LAYER_KEY_CANONICAL_SOURCE_2RY_3RY = :canonical_source_2ry_3ry
  LAYER_KEY_SCENE_WORKING_NOTES = :working_notes

  TARGET_TYPE_CANVAS = 'oa:SpecificResource'
  TARGET_TYPE_ANNOTATION = 'oa:Annotation'

  class CreationHelper
    @@suffixes = {
      LAYER_KEY_ENGLISH => '_English_Sun_Of_Faith',
      LAYER_KEY_TIBETAN => '_Tibetan_Sun_Of_Faith',
      LAYER_KEY_ENGLISH_MANUAL => '_English_Manual',
      LAYER_KEY_TIBETAN_MANUAL => '_Tibetan_Manual',
      LAYER_KEY_ENGLISH_INSCRIPTION => '_English_Inscription',
      LAYER_KEY_TIBETAN_INSCRIPTION => '_Tibetan_Inscription',
      LAYER_KEY_CANONICAL_SOURCE => '_Canonical Source',
      LAYER_KEY_CANONICAL_SOURCE_2RY_3RY => '_Secondary/Tertiary Canonical Source',
      LAYER_KEY_SCENE_WORKING_NOTES => '_Scene Working Notes'
    }

    @@labels = {
      LAYER_KEY_ENGLISH => 'Sun of Faith - English',
      LAYER_KEY_TIBETAN => 'Sun of Faith - Tibetan',
      LAYER_KEY_ENGLISH_MANUAL => 'Manual - English',
      LAYER_KEY_TIBETAN_MANUAL => 'Manual - Tibetan',
      LAYER_KEY_ENGLISH_INSCRIPTION => 'Inscription - English',
      LAYER_KEY_TIBETAN_INSCRIPTION => 'Inscription - Tibetan',
      LAYER_KEY_CANONICAL_SOURCE => 'Canonical Source',
      LAYER_KEY_CANONICAL_SOURCE_2RY_3RY => 'Secondary/Tertiary Canonical Source',
      LAYER_KEY_SCENE_WORKING_NOTES => 'Scene Working Notes'
    }

    @@canvas_ids = {
      '1' => 'http://manifests.ydc2.yale.edu/LOTB/canvas/panel_01',
      '2' => 'http://manifests.ydc2.yale.edu/LOTB/canvas/bv11'
    }

    @@list_id_layer_parts = {
      LAYER_KEY_ENGLISH => 'English',
      LAYER_KEY_TIBETAN => 'Tibetan',
      LAYER_KEY_ENGLISH_MANUAL => 'English_PaintingManual',
      LAYER_KEY_TIBETAN_MANUAL => 'Tibetan_PaintingManual',
      LAYER_KEY_ENGLISH_INSCRIPTION => 'English_Inscription',
      LAYER_KEY_TIBETAN_INSCRIPTION => 'Tibetan_Inscription',
      LAYER_KEY_CANONICAL_SOURCE => 'CanonicalSources',
      LAYER_KEY_CANONICAL_SOURCE_2RY_3RY => 'SecondaryCanonicalSources',
      LAYER_KEY_SCENE_WORKING_NOTES => 'SceneWorkingNotes'
    }

    def initialize
      @host_url = Rails.application.config.hostUrl.sub(/\/$/, '')
    end

    def create_annotation(layer_key:, panel:, chapter:, scene:, sequence:,
      body_text:)

      annotation_id = create_annotation_id(
        layer_key: layer_key, panel: panel, chapter: chapter, scene: scene,
        sequence: sequence)
      annotation_type = 'oa:Annotation'
      motivation = ['commenting']
      label = create_label(layer_key: layer_key, panel: panel, chapter: chapter, scene: scene, sequence: sequence)
      target = create_target(target_type: TARGET_TYPE_ANNOTATION, panel: panel, chapter: chapter, scene: scene)
      manifest = 'tbd'
      body_text = process_body(layer_key: layer_key, text: body_text)
      resource = create_resource(body_text: body_text, chapter: chapter, scene: scene, sequence: sequence)
      canvas = create_canvas_id(panel)
      active = true
      version = 1

      Annotation.create(annotation_id: annotation_id,
        annotation_type: annotation_type,
        motivation: motivation.to_json,
        label:label,
        on: target.to_json,
        canvas: canvas,
        manifest: manifest,
        resource: resource.to_json,
        active: active,
        version: version)
    end

    def create_canvas_id(panel)
      canvas_id = @@canvas_ids[panel]
      raise "CreateionHelper#create_canvas_id: invalid panel [#{panel}]" unless canvas_id
      canvas_id
    end

    def process_body(layer_key:, text:)
      puts "ENCODING 1 #{text.encoding}"
      text = text.encode(Encoding.find('UTF-8'), {invalid: :replace, undef: :replace, replace: '?'})
      puts "ENCODING 2 #{text.encoding}"
      text.strip!
      text.gsub!(/\n/, '<br/>')
      ActionController::Base.helpers.sanitize(text)
      if [LAYER_KEY_TIBETAN, LAYER_KEY_TIBETAN_MANUAL, LAYER_KEY_TIBETAN_INSCRIPTION].include?(layer_key)
        text = "<p><span style=\"font-size: 24px;\">#{text}</span></p>"
      else
        text = "<p>#{text}</p>"
      end
    end

    def create_resource(body_text:, chapter:, scene:, sequence:)
      resource = [{
        '@type' => 'dctypes:Text',
        'format' => 'text/html',
        'chars' =>  body_text
      }]

      if chapter
        resource.push(create_tag(:chapter, chapter))
        if scene && scene != '0'
          resource.push(create_tag(:scene, scene))
          resource.push(create_tag(:p, sequence)) if sequence
        end
      end

      resource
    end

    def create_tag(prefix, suffix)
      {
        '@type' => 'oa:Tag',
        'chars' => "#{prefix}#{suffix}"
      }
    end

    def create_label(layer_key:, panel:, chapter:, scene:, sequence:)
      "[#{@@labels[layer_key]}] panel #{panel}, chapter #{chapter}, scene #{scene}, paragraph #{sequence}"
    end

    def create_target(target_type:, panel:, chapter:, scene:)
      {
        '@type': target_type,
        'full': create_target_url(target_type: target_type, panel: panel, chapter: chapter, scene: scene)
      }
    end

    def create_target_url(target_type:, panel:, chapter:, scene:)
      if scene == '0'
        return create_url_prefix_chapter(panel, chapter)
      else
        return create_url_prefix_scene(panel, chapter, scene)
      end
    end

    def create_url_prefix(panel, chapter, scene, sequence)
      "#{@host_url}/annotations/Panel_#{panel}_Chapter_#{chapter}_Scene_#{scene}_#{sequence}"
    end

    def create_url_prefix_chapter(panel, chapter)
      "#{@host_url}/annotations/Panel_#{panel}_Chapter_#{chapter}"
    end

    def create_url_prefix_scene(panel, chapter, scene)
      prefix = create_url_prefix_chapter(panel, chapter)
      "#{prefix}_Scene_#{scene}"
    end

    def create_url_prefix_sequence(panel, chapter, scene, sequence)
      prefix = create_url_prefix_scene(panel, chapter, scene)
      "#{prefix}_#{sequence}"
    end

    def create_annotation_id(layer_key:, panel:, chapter:, scene:, sequence:)
      prefix = create_url_prefix_sequence(panel, chapter, scene, sequence)
      suffix = @@suffixes[layer_key]
      "#{prefix}#{suffix}"
    end

    def create_list_id(layer_key:, panel:)
      canvas_id = create_canvas_id(panel)
      "#{@host_url}/lists/#{@host_url}/layers/#{@@list_id_layer_parts[layer_key]}_#{canvas_id}"
    end
  end
end
