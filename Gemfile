
source 'https://rubygems.org'
ruby '2.4.1'

# Use unicorn as the app server
gem 'unicorn', '~> 5.4.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
#gem 'rails'
gem 'rails', '~> 5.1.4'
gem 'bootstrap-sass', '~> 3.3.7'
gem 'sprockets', '~> 3.7.1'

gem 'pg', '~> 0.18'
gem 'therubyracer', '~> 0.12.3'

gem 'devise', '~> 4.4.0'
gem 'omniauth', '~> 1.8.1'
gem 'omniauth-cas', '~> 1.1.1'
gem 'cancancan', "~> 2.1.3"

gem 'rack-cors', '~> 1.0.2', :require => 'rack/cors'
gem 'uuid', '~> 2.3.8'

gem 'axlsx', '~> 2.0.1'

gem 'delayed_job_active_record', '~> 4.1.2'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0.7'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 4.1.3'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.2.2'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer',  platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails', '~> 4.3.1'
gem 'jquery-ui-rails', '~> 6.0.1'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', '~> 5.1.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.2', group: :doc

# Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
gem 'spring', '~> 2.0.2', group: :development

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.11'

# Use dropzone gem instead of having the javascript and css in /assets [jrl]
gem 'dropzonejs-rails', '~> 0.8.2'

gem 'rsolr', '~> 2.1.0'
gem 'rmagick', '~> 2.16.0'
gem 'redis', '~> 4.0.1'
gem 'aws-sdk', '~> 3.0.1'
gem 'aws-sdk-rails', '~> 2.0.1'

gem 'jwt', '~> 2.1.0'

group :production do
  gem 'rails_12factor', '~> 0.0.3'
end

group :development, :test do
  gem 'pry-byebug', '~> 3.5.1'
  gem 'pry-rails', '~> 0.3.6'
  gem 'database_cleaner', '~> 1.6.2'
  gem 'factory_bot_rails', '~> 4.8.2'
  gem 'simplecov', '~> 0.15.1', :require => false, :group => :test
  gem 'rubocop', '~> 0.52.1', require: false
  gem 'rspec', '~> 3.7.0'
  gem 'rspec-rails', '~> 3.7.2'
  gem 'shoulda', '~> 3.5.0'
  gem 'single_test', '~> 0.6.0'
  gem 'webmock', '~> 3.3.0'
end

group :development do
  gem 'listen', '~> 3.1.5'
end
