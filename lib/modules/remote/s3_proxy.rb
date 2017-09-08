module Remote
  class S3Proxy
    def initialize
      @bucket = Rails.application.config.S3_Bucket
      @bucket_folder = Rails.application.config.S3_Bucket_Folder
      key = Rails.application.config.S3_Key
      secret = Rails.application.config.S3_Secret

      @s3 = Aws::S3::Resource.new(region: 'us-east-1',
                                  access_key_id: key,
                                  secret_access_key: secret)
    end

    def upload_file(local_file_path, remote_file_name)
      remote_path = "#{@bucket_folder}/#{remote_file_name}"
      Rails.logger.debug("Uploading to S3: #{local_file_path} -> #{remote_path}")
      obj = @s3.bucket(@bucket).object(remote_path)
      obj.upload_file(local_file_path)
    end

    def delete_old_files(extension)
      bucket = @s3.bucket(@bucket)
      bucket.objects.each do |obj|
        puts "hello"
        puts "#{obj.key} => #{obj.etag}"
      end
    end
  end
end