require 'csv'
require 'aws-sdk-rails'
namespace :loadAnnotationsToSolr do

  desc "add BoundingBox x,y height and width to annotations"
  task :addBB_XYWH => ["db:set_prod_env", :environment] do
  #task :addBB_XYWH => ["db:set_test_env", :environment] do
  #task :addBB_XYWH => ["db:set_dev_env", :environment] do
    host_url_prefix = Rails.application.config.hostUrl
    #host_url_prefix = 'http://localhost:5000/annotations'

    #@annotations = Annotation.all.order("id")
    @annotations = Annotation.where("annotation_id like ?", "%#{host_url_prefix}%").order("id")

    count = 0
      xywh = ''
      @annotations.each do |anno|
        count += 1
        # break if count > 100
        svg_path = ''

        #to-do: don't filter by orig_canvas, for any targeting annos get the orig_canvas by using getTargetedAnno below
        #next unless anno.on.include?("svg") && anno.annotation_id.include("http://annotations.ten-thousand-rooms.yale.edu/annotations/")
        if anno.on.include?("svg")
          onWithSVG = anno.on
        else
          annoWithSVG = getTargetedAnno anno
          if !annoWithSVG.nil?
            onWithSVG = annoWithSVG.on
          else
            next
          end
        end

        p ''
        p "count = #{count}) anno: #{anno.annotation_id}"
        p "count = #{count}) onWithSVG = #{onWithSVG}"
        p ''

        if onWithSVG.include?("oa:SvgSelector")
          # get svgpath from "d" attribute in the svg selector value
          svg_path = get_svg_path onWithSVG
          if svg_path!=''
            #p "svg_path: #{svg_path}"
            svg_path.gsub!(/<g>/,'')
            #p "svg_path(1,30): #{svg_path[0..30]}"
            firstComma = svg_path.index(',')
            #p "firstComma = #{firstComma.to_s}"
            svg_x = svg_path[1..firstComma-1].to_i + 5000
            xywh = Annotation.get_xywh_from_svg svg_path,svg_x,10000 if svg_path!=''
            #p "svg: #{xywh}"
          end
        end

        # update annotation here
        #anno.update_attributes(:service_block => xywh)
        p "processed: #{count.to_s}) #{anno.annotation_id}: #{xywh}"
      end
  end

  def get_svg_path onWithSVG
    p "     in get_svg_path: "

    p "onWithSVG: #{onWithSVG}"
    onN = onWithSVG.gsub(/=>/,':')
    onN.gsub!(/\\"/,'')
    p "!!!!!!!!!!!!!!!!!!!!!!!!!!  on = #{onN}"

    begin
      onJSON = JSON.parse(onN)
      svg = onJSON["selector"]["value"]
    rescue
        p 'error json-parsing annotation on'
        svg_path = ''
    else
      dStart =  svg.index('d=') + 2
      dEnd =  svg.index('data-paper-data') - 1
      svg_path =svg[dStart..dEnd]
      p "svg_path = #{svg_path}"
=begin
      begin
        p "***svg = #{svg}"
        svgHash = Hash.from_xml(svg)
      rescue
        p 'error creating svg hash from json-parsed anno'
        p "svg = #{svg.to_s}"
        svg_path = ''
      else
        begin
          svg_path = svgHash["svg"]["path"]["d"]
        rescue
          p "svgHash parsing d for #{anno.annotation_id}: svg_path: #{svg_path} failed"
          svg_path = ''
        end
      end
=end
    end
  end

  def getTargetedAnno inputAnno
    #return if inputAnno.nil?
    p "in Rake:getTargetedAnno: annoId = #{inputAnno.annotation_id}"
    onN = inputAnno.on
    p "onN = " + onN
    p ""
    onN = onN.gsub!(/=>/,':') if onN.include?("=>")
    p "onN now = " + onN.to_s
    onJSON = JSON.parse(onN)
    targetAnnotation = Annotation.where(annotation_id:onJSON['full']).first
    return if targetAnnotation.nil?
    return(targetAnnotation) if (targetAnnotation.on.to_s.include?("oa:SvgSelector"))
    getTargetedAnno targetAnnotation
  end

  desc "write csv for AnnosNoResource to a file"
  task :csvAnnosNoResource => ["db:set_prod_env", :environment] do  |t, args|
  #task :csvAnnosNoResource => ["db:set_test_env", :environment] do  |t, args|
  #task :csvAnnosNoResource => ["db:set_dev_env", :environment] do  |t, args|
      CSV.open("AnnosNoResourceLOTB.csv", "w") do |csv|
        Annotation.feedAnnosNoResource csv
      end

      # upload to AWS S3 bucket
      S3_Bucket = Rails.application.config.S3_Bucket
      S3_Bucket_Folder = Rails.application.config.S3_Bucket_Folder
      S3_Access_Key = Rails.application.config.S3_Key
      S3_Access_Secret = Rails.application.config.S3_Secret
      s3 = Aws::S3::Resource.new(region: 'us-east-1',
                                 access_key_id: S3_Access_Key,
                                 secret_access_key: S3_Access_Secret
      )
      file = 'AnnosNoResourceLOTB.csv'
      name = S3_Bucket_Folder + "/" + File.basename(file)
      obj = s3.bucket(S3_Bucket).object(name)
      obj.upload_file(file)
      p "file #{name} was uploaded to #{bucket}"
      puts "\n"
    end

  desc "write csv for AnnosResourceOnly to a file"
  task :csvAnnosResourceOnly => ["db:set_prod_env", :environment] do  |t, args|
  #task :csvAnnosResourceOnly => ["db:set_test_env", :environment] do  |t, args|
  #task :csvAnnosResourceOnly => ["db:set_dev_env", :environment] do  |t, args|
    CSV.open("AnnosResourceOnlyLOTB.csv", "w") do |csv|
      Annotation.feedAnnosResourceOnly csv
    end
    # upload to AWS S3 bucket
    S3_Bucket = Rails.application.config.S3_Bucket
    S3_Bucket_Folder = Rails.application.config.S3_Bucket_Folder
    S3_Access_Key = Rails.application.config.S3_Key
    S3_Access_Secret = S3_Secret

    #s3 = Aws::S3::Resource.new(region: 'us-east-1',
    #                          access_key_id: 'AKIAIMA6TZV7PEDMLY7Q',
    #                          secret_access_key: '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'
    #)
    s3 = Aws::S3::Resource.new(region: 'us-east-1',
                               access_key_id: S3_Access_Key,
                               secret_access_key: S3_Access_Secret
    )
    file = 'AnnosResourceOnlyLOTB.csv'
    name = "dev_annotation/" + File.basename(file)
    name = S3_Bucket_Folder + "/" + File.basename(file)
    #bucket = 'images.tenthousandrooms.yale.edu'
    #obj = s3.bucket(bucket).object(name)
    obj = s3.bucket(S3_Bucket).object(name)
    obj.upload_file(file)
    p "file: #{name} was uploaded to #{bucket}"
    puts "\n"
  end
end

namespace :db do
  desc "Custom dependency to set prod environment"
  task :set_prod_env do # Note that we don't load the :environment task dependency
    Rails.env = "production"
  end

  desc "Custom dependency to set test environment"
  task :set_test_env do # Note that we don't load the :environment task dependency
    Rails.env = "test"
  end

  desc "Custom dependency to set development environment"
  task :set_dev_env do # Note that we don't load the :environment task dependency
    Rails.env = "development"
  end
end


