module Util
  def self.make_array(object)
    return [] if object.nil?
    return object if object.kind_of?(Array)
    [object]
  end
end
