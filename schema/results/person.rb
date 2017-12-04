# http://json-schema.org/schema#
# 

class Person
  include Mongoid::Document
  include Mongoid::Timestamps

  field :first_name, type: String
  field :last_name, type: String
  # field description: Age in years
  field :age, type: Integer

  # required fields
  validates :first_name, :last_name, presence: true
end

__END__
{
  "title": "Person",
  "required": [
    "first_name",
    "last_name"
  ],
  "properties": {
    "first_name": {
      "type": "string"
    },
    "last_name": {
      "type": "string"
    },
    "age": {
      "description": "Age in years",
      "type": "integer",
      "minimum": 0
    }
  },
  "type": "object",
  "schema": "http://json-schema.org/schema#"
}