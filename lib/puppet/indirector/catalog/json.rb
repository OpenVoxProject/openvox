# frozen_string_literal: true

require_relative '../../../puppet/resource/catalog'
require_relative '../../../puppet/indirector/json'

class Puppet::Resource::Catalog::Json < Puppet::Indirector::JSON
  desc "Store catalogs as flat files, serialized using JSON."

  def from_json(text)
    model.convert_from(json_format, text.force_encoding(Encoding::UTF_8))
  end

  def to_json(object)
    object.render(json_format)
  end

  private

  def json_format
    if Puppet[:rich_data]
      'rich_data_json'
    else
      'json'
    end
  end
end
