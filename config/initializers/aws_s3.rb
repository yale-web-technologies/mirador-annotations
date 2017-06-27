# Be sure to restart your server when you modify this file

# set a useRedis variable as flag to whether or not to use Redis for this instance
Rails.application.config.S3_Bucket = ENV['S3_Bucket']
Rails.application.config.S3_Bucket_Folder = ENV['S3_Bucket_Folder']
Rails.application.config.S3_Key = ENV['S3_Key']
Rails.application.config.S3_Secret = ENV['S3_Secret']

p "AWS S3 info read"

