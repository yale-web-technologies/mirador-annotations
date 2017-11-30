
source 'https://rubygems.org'
ruby '2.2.4'

# Use unicorn as the app server
#gem 'unicorn'
gem 'unicorn', '5.1.0'
#gem 'unicorn', '5.2.0'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
#gem 'rails'
gem 'rails', github: 'rails/rails', branch: '4-2-stable'  # avoid arel problem
gem 'bootstrap-sass', '2.3.2.0'
gem 'sprockets', '2.12.3'

gem 'pg', '0.15.1'

gem 'json'

gem 'therubyracer'
gem 'devise', '~> 3.4.0'   # or later
gem 'omniauth'
gem 'omniauth-cas'
gem 'uuid'
#gem 'cancan'
gem 'cancancan', "~> 1.10"
gem 'rack-cors', :require => 'rack/cors'

gem 'axlsx', '2.1.0.pre'

gem 'delayed_job_active_record', '~> 4.1.2'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.3'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer',  platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-ui-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0',          group: :doc

# Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
gem 'spring',        group: :development

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use dropzone gem instead of having the javascript and css in /assets [jrl]
gem 'dropzonejs-rails'

#gem "bootstrap-sass", "~> 2.2.0"

gem 'protected_attributes'

gem 'rsolr'
gem 'rmagick'
gem 'redis', '~>3.2'
#gem 'aws/s3'
gem 'aws-sdk', '~> 2'
gem 'aws-sdk-rails'

#gem 'mirador-annotation-solr-loader', :path => "~/rails_projects/mirador-annotation-solr-loader/"
#gem 'annotation_solr_loader', github: 'ydc2/annotation-solr-loader', tag: 'v1.5'
#gem 'mirador-annotation-solr-loader', :path => "/Users/rlechich/rails_projects/"

#gem 'arel', '6.0.0.beta2'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

group :production do
  gem 'rails_12factor', '0.0.2'
end

group :development, :test do
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'database_cleaner'
  gem 'factory_girl_rails', '~> 4.2.0'
  gem 'simplecov', :require => false, :group => :test
  gem 'rubocop', require: false
  gem 'rspec'
  gem 'rspec-rails'
  gem 'shoulda'
  gem 'shoulda-matchers'
  gem 'single_test'
end
