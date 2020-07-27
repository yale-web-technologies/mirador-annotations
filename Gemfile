
source 'https://rubygems.org'
ruby '2.4.1'

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

gem 'json', '~> 2.3.1'

gem 'therubyracer'
gem 'devise', '~> 3.4.0'   # or later
gem 'omniauth', '~> 1.3.1'
gem 'omniauth-cas', '~> 1.1.1'
gem 'uuid', '~> 2.3.8'

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
gem 'jquery-rails', '~> 4.2.1'
gem 'jquery-ui-rails', '~> 5.0.5'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', '~> 5.0.1'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use dropzone gem instead of having the javascript and css in /assets [jrl]
gem 'dropzonejs-rails', '~> 0.7.3'

#gem "bootstrap-sass", "~> 2.2.0"

gem 'protected_attributes', '~> 1.1.3'

gem 'rsolr', '~> 1.1.2'
gem 'rmagick', '~> 2.16.0'
gem 'redis', '~> 3.2'
#gem 'aws/s3'
gem 'aws-sdk', '~> 2'
gem 'aws-sdk-rails', '~> 1.0.1'

gem 'jwt', '~> 2.1.0'

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
  gem 'pry-byebug', '~> 3.5.0'
  gem 'pry-rails', '~> 0.3.6'
  gem 'database_cleaner', '~> 1.6.2'
  gem 'factory_girl_rails', '~> 4.2.0'
  gem 'simplecov', :require => false, :group => :test
  gem 'rubocop', require: false
  gem 'rspec-rails', '~> 3.5.2'
  gem 'shoulda', '~> 3.5.0'
  gem 'shoulda-matchers', '~> 2.8.0'
  gem 'single_test', '~> 0.6.0'
  gem 'webmock', '~> 3.1.0'
end

group :development do
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '~> 2.0.0', group: :development

  gem 'jekyll', '~> 3.3.1'

  group :jekyll_plugins do
    gem 'jekyll-seo-tag', '~> 2.1.0'
    gem 'jekyll-sitemap', '~> 0.12.0'
  end
end
