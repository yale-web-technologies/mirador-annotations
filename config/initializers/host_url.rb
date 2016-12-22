# Be sure to restart your server when you modify this file

# set a host url variable to provide consistent construction of @id's
Rails.application.config.hostUrl = ENV['IIIF_HOST_URL']
# http://annotations.ten-thousand-rooms.yale.edu/
p "hostUrl = #{Rails.application.config.hostUrl}"

