# Be sure to restart your server when you modify this file

# set a useRedis variable as flag to whether or not to use Redis for this instance
Rails.application.config.useRedis = ENV['USE_REDIS']
# Y/N
p "useRedis = #{Rails.application.config.useRedis}"

