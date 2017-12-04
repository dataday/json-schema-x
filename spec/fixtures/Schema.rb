# http://json-schema.org/draft-04/schema#
# A Schema

class Schema
  include Mongoid::Document
  include Mongoid::Timestamps

  field :foo, type: String
end

__END__
{
  "title": "Schema",
  "schema": "http://json-schema.org/draft-04/schema#",
  "description": "A Schema",
  "properties": {
    "foo": {
      "type": "string"
    }
  }
}