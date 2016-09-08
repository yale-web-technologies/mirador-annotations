namespace :updateSVG do
  require 'csv'
  desc "updates the SVG portion in an annotation's on['selector']['value'] element"
  task :SVG_update, [:env] => :environment do |t, args|
    env = args.env
    p 'env: ' + env
    svgFilename = "importData/SVG_adjustments_#{env}.csv"
    p "svgFilename = #{svgFilename}"

    CSV.foreach(svgFilename) do |row|
      anno_id = row[0]
      canvas = row[1]
      onBase = '{"@type": "oa:SpecificResource","full": "http://manifests.ydc2.yale.edu/LOTB/canvas/' + canvas + '","selector": {"@type": "oa:SvgSelector","value":"'
      onSVG = row[2]

      on = onBase + onSVG +  '"}}'
      p "on = #{on}"

      annotation = Annotation.where(annotation_id: anno_id).first
      p "annotation_id = #{annotation.annotation_id}"

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










