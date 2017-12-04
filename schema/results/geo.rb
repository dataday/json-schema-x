# http://json-schema.org/draft-03/schema#
# A geographical coordinate

class Geo
  include Mongoid::Document
  include Mongoid::Timestamps

  field :latitude, type: Float
  field :longitude, type: Float
end

__END__
{
  "schema": "http://json-schema.org/draft-03/schema#",
  "type": "object",
  "description": "A geographical coordinate",
  "properties": {
    "latitude": {
      "type": "number"
    },
    "longitude": {
      "type": "number"
    }
  },
  "title": "Geo"
}