namespace :updateSVG do
  require 'csv'
  desc "updates the SVG portion in an annotation's on['selector']['value'] element"
  task :SVG_update, [:env] => :environment do |t, args|
    env = args.env
    p 'env: ' + env
    # rake updateSVG:SVG_update[local/dev/prod] > updatSvgsPanel_01_02_2017_local/dev/prod.log
    #svgFilename = "importData/SVG_adjustments_#{env}.csv"
    #svgFilename = "importData/SVG_Adjustments/SVGs_panel_01_#{env}_02_2017.csv"
    #svgFilename = "importData/SVG_Adjustments/SVGs_panel_01_#{env}_02_2017_Chap4_Scene2.csv"
    svgFilename = "importData/SVG_Adjustments/SVGs_panel_01_stg_Chap19.csv"
    #svgFilename = "importData/SVG_Adjustments/SVGs_panel_01_local_02_2017.csv"
    p "svgFilename = #{svgFilename}"

    CSV.foreach(svgFilename) do |row|
      anno_id = row[0]
      p "anno_id = #{anno_id}"
      canvas = row[1]
      p "canvas = #{canvas}"
      onBase = '{"@type": "oa:SpecificResource","full": "http://manifests.ydc2.yale.edu/LOTB/canvas/' + canvas + '","selector": {"@type": "oa:SvgSelector","value":"'
      onSVG = row[2]
      p "onSVG = #{onSVG}"

      on = onBase + onSVG +  '"}}'
      p "on = #{on}"

      annotation = Annotation.where(annotation_id: anno_id).first
      if annotation
        p "annotation_id = #{annotation.annotation_id}"
      else
        p "annotation_id: #{anno_id} not found!"
        #continue
        next
      end
      #if annotation.update_attributes(:on => annotation['on'])
      if annotation.update_attributes(:on => on)
        p "success"
      else
        p "failure"
      end
      puts
    end
  end

  desc "gets the SVG portion in an annotation's on['selector']['value'] element"
  task :SVG_get, [:anno_id] => :environment do |t, args|
    #p 'args: ' + args.inspect
    annotation_id = args.anno_id.to_s
    #annotation_id = 'http://localhost:5000/annotations/Panel_A_Chapter_9'
    puts "annotation_id = #{annotation_id}"

    annotation = Annotation.where(annotation_id: annotation_id).first
    on = JSON.parse(annotation.on)
    p "on = #{on.to_json}"
    #p "on = #{on}"
    svg = on["selector"]["value"].to_s
    p "svg = #{svg}"
  end

end










