class Collection < ActiveRecord::Base
  ## collection here is a IIIF::Collection, different from the model type ::Collection
  def self.export(collection, layers, file_path)
    exporter = Export::AxlsxExporter.new(collection, layers)

    Axlsx::Package.new do |p|
      exporter.export(p.workbook)
      p.serialize(file_path)
    end
  end
end