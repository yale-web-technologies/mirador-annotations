namespace :importLotBCheck do

  desc "imports LoTB annotation data from a csv file"
  #Sun of Faith - Structured Chapters - ch. 26.csv normalized
  # Assumption: will be loaded by worksheet per chapter: first column holds panel, second column holds chapter, third column holds scene
  # Iterating through sheet needs to check for new scene, but not for new panel or chapter
  task :LoTB_annotationsCheck => :environment do
    require 'csv'
    @ru = "http://localhost:5000"
    i = 0
    j=0

    #CSV.foreach('importData/LotB_ch26.txt') do |row|
    CSV.foreach('importData/LotB_ch23.csv') do |row|
      i+=1;
      puts "i = #{i}) #{row}"
    end
  end
end