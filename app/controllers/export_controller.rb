require 'csv'
require 'open-uri'

class ExportController < ApplicationController
  def export
    project_id = params[:project_id]
    user_id = params[:user_id]
    puts "pid:#{project_id} uid:#{user_id}"

    @collection = get_collection(project_id, user_id)

    respond_to do |format|
      format.csv do
        exporter = Export::CsvExporter.new(@collection)
        @lines = exporter.export

        filename = @collection['label'].gsub(/\s+/, '_') + '.csv'
        headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
        headers['Content-Type'] = 'text/csv'
      end
      format.html do
        headers['Content-Type'] = 'text/html'
      end
    end
  end

private
  def get_collection(project_id, user_id)
    service_host=Rails.application.config.iiif_collections_host
    url = "#{service_host}/node/#{project_id}/collection?user_id=#{user_id}"
    collection_json = open(url).read
    JSON.parse(collection_json)
  end
end
