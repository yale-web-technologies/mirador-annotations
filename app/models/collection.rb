class Collection < ApplicationRecord
  ## collection here is a IIIF::Collection, different from the model type ::Collection
  def self.export(collection:, layers:, local_file_path:, remote_file_name:)
    exporter = Export::AxlsxExporter.new(collection, layers)

    Axlsx::Package.new do |p|
      exporter.export(p.workbook)
      p.serialize(local_file_path)
      s3 = Remote::S3Proxy.new
      logger.debug("Collection.export uploading")
      s3.upload_file(local_file_path, remote_file_name)
    end
  end
end
