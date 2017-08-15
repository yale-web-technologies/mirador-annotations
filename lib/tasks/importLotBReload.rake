namespace :import do
  require 'csv'
  require 'open-uri'

  desc "Imports Life of the Buddha annotation data from a csv file"
  task :lotb_annotations_csv, [:csv_url] => :environment do |t, args|
    hostUrl = Rails.application.config.hostUrl.sub(/\/$/, '')
    importer = Import::CsvImporter.new(hostUrl)

    puts "Importing from: #{args.csv_url}"

    open(args.csv_url) do |f|
      importer.import(f.read)
    end
  end
end










