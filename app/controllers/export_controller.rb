require 'csv'
require 'open-uri'

class ExportController < ApplicationController
  def export
    project_id = params[:project_id]
    user_id = params[:user_id]
    puts "pid:#{project_id} uid:#{user_id}"

    @collection = get_collection(project_id, user_id)
    layers = get_layers(project_id)

    respond_to do |format|
      format.csv do
        exporter = Export::CsvExporter.new(@collection, layers)
        @lines = exporter.export

        filename = @collection.label.gsub(/\s+/, '_') + '.csv'
        headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
        headers['Content-Type'] = 'text/csv; charset: utf-8'
        #headers['Content-Type'] = 'text/html; charset: utf-8'
      end

      format.xlsx do
        @exporter = Export::AxlsxExporter.new(@collection, layers)
        filename = @collection.label.gsub(/\s+/, '_') + '.xlsx'
        headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
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
    logger.debug("Contacting #{service_host} to get collection data...")
    collection_json = open(url).read
    logger.debug("Collection data received")
    IIIF::Collection.parse_collection(collection_json)
  end

  def get_layers(project_id)
    group = Group.where(group_id: project_id).first
    group.annotation_layers
  end
end
