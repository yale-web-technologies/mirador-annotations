namespace :export do
  desc "Delete old temporary files from S3"
  task :clean_s3 => :environment do
    s3 = Remote::S3Proxy.new
    s3.delete_old_files('xlsx')
  end
end