
source 'https://rubygems.org'
ruby '2.6.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '5.2.3'
# gem 'rails', github: 'rails/rails', branch: '4-2-stable'  # avoid arel problem
gem 'bootstrap-sass', '~> 3.4.1'
gem 'sprockets', '~> 3.7.2'
gem 'bootsnap', '~> 1.4.4'
gem 'responders', '~> 2.4.1'

gem 'pg', '~> 1.1.4'

gem 'rack-cors', '~> 1.0.3'

gem 'axlsx', '2.1.0.pre'

gem 'delayed_job_active_record', '~> 4.1.2'

group :production do
  # Use postgres as the database for Active Record for dev

  gem 'rails_12factor', '0.0.3'
end

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0.7'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-ui-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0',          group: :doc

gem 'rsolr'
gem 'rmagick'
gem 'redis', '~>3.2'
gem 'aws-sdk', '~> 2'
gem 'aws-sdk-rails'

group :development do
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '~> 2.0.2'
  gem 'listen', '~> 3.1.5'
end

group :development, :test do
  gem 'rspec-rails'
  gem 'rspec'
  gem 'factory_girl_rails', '~> 4.2.0'
  gem 'simplecov', :require => false, :group => :test
  gem 'rubocop', require: false
end
