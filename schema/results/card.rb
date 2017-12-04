# http://json-schema.org/draft-03/schema#
# A representation of a person, company, organization, or place

class Card
  include Mongoid::Document
  include Mongoid::Timestamps

  # field description: Formatted Name
  field :fn, type: String
  field :family_name, type: String
  field :given_name, type: String
  # field items: string
  field :additional_name, type: Array
  # field items: string
  field :honorific_prefix, type: Array
  # field items: string
  field :honorific_suffix, type: Array
  field :nickname, type: String
  field :url, type: String
  # field properties: type, value
  field :email, type: Hash
  # field properties: type, value
  field :tel, type: Hash
  # field reference: http://json-schema.org/address
  # @todo: specify 'embedded_in :Card' within class Address
  embeds_one :address
  # field reference: http://json-schema.org/geo
  # @todo: specify 'embedded_in :Card' within class Geo
  embeds_one :geo
  field :tz, type: String
  field :photo, type: String
  field :logo, type: String
  field :sound, type: String
  field :bday, type: Date
  field :title, type: String
  field :role, type: String
  # field properties: organization_name, organization_unit
  field :org, type: Hash

  # required fields
  validates :family_name, :given_name, presence: true
end

__END__
{
  "schema": "http://json-schema.org/draft-03/schema#",
  "type": "object",
  "description": "A representation of a person, company, organization, or place",
  "required": [
    "family_name",
    "given_name"
  ],
  "properties": {
    "fn": {
      "description": "Formatted Name",
      "type": "string"
    },
    "family_name": {
      "type": "string"
    },
    "given_name": {
      "type": "string"
    },
    "additional_name": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "honorific_prefix": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "honorific_suffix": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "nickname": {
      "type": "string"
    },
    "url": {
      "type": "string",
      "format": "uri"
    },
    "email": {
      "type": "object",
      "properties": {
        "type": {
          "type": "string"
        },
        "value": {
          "type": "string",
          "format": "email"
        }
      }
    },
    "tel": {
      "type": "object",
      "properties": {
        "type": {
          "type": "string"
        },
        "value": {
          "type": "string",
          "format": "phone"
        }
      }
    },
    "adr": {
      "ref": "http://json-schema.org/address"
    },
    "geo": {
      "ref": "http://json-schema.org/geo"
    },
    "tz": {
      "type": "string"
    },
    "photo": {
      "type": "string"
    },
    "logo": {
      "type": "string"
    },
    "sound": {
      "type": "string"
    },
    "bday": {
      "type": "string",
      "format": "date"
    },
    "title": {
      "type": "string"
    },
    "role": {
      "type": "string"
    },
    "org": {
      "type": "object",
      "properties": {
        "organization_name": {
          "type": "string"
        },
        "organization_unit": {
          "type": "string"
        }
      }
    }
  },
  "title": "Card"
}