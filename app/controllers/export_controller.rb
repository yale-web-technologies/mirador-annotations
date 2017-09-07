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

      format.html do
        headers['Content-Type'] = 'text/html'
        @file_hash = SecureRandom.uuid
        @filename = build_download_file_name(@collection.label)
        filepath = build_export_file_path(@collection.label, @file_hash)
        job = ::Collection.delay.export(@collection, layers, filepath)
        @job_id = job.id
      end
    end
  end

  def check_status
    job_id = params[:job_id]
    job = Delayed::Job.find_by_id(job_id)

    if job.nil?
      isComplete = true
      errorCode = 0
    else
      isComplete = false
      errorMessage = job.last_error
      errorCode = errorMessage ? 1 : 0
    end

    render json: {
      jobId: job_id,
      isComplete: isComplete,
      errorCode: errorCode,
      errorMessage: errorMessage
    }
  end

  def download
    puts "DOWNLOAD"
    respond_to do |format|
      format.xlsx do
        puts "XLSX"
        filename = build_download_file_name(params[:label])
        filepath = build_export_file_path(params[:label], params[:file_hash])
        send_file(filepath,
          filename: filename,
          type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
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

  def build_export_file_path(collection_label, file_hash)
    name = collection_label.gsub(/\s+/, '_')
    "#{Rails.root}/tmp/export.#{name}.#{file_hash}.xlsx"
  end

  def build_download_file_name(collection_label)
    name = collection_label.gsub(/\s+/, '_')
    "#{name}.xlsx"
  end
end