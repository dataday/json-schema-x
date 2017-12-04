# http://json-schema.org/draft-03/schema#
# An Address following the convention of http://microformats.org/wiki/hcard

class Address
  include Mongoid::Document
  include Mongoid::Timestamps

  field :post_office_box, type: String
  field :extended_address, type: String
  field :street_address, type: String
  field :locality, type: String
  field :region, type: String
  field :postal_code, type: String
  field :country_name, type: String

  # :street_address dependents: post_office_box, extended_address
  validates :street_address, presence: true

  # required fields
  validates :locality, :region, :country_name, presence: true
end

__END__
{
  "schema": "http://json-schema.org/draft-03/schema#",
  "dependencies": {
    "post_office_box": [
      "street_address"
    ],
    "extended_address": [
      "street_address"
    ]
  },
  "type": "object",
  "description": "An Address following the convention of http://microformats.org/wiki/hcard",
  "required": [
    "locality",
    "region",
    "country_name"
  ],
  "properties": {
    "post_office_box": {
      "type": "string"
    },
    "extended_address": {
      "type": "string"
    },
    "street_address": {
      "type": "string"
    },
    "locality": {
      "type": "string"
    },
    "region": {
      "type": "string"
    },
    "postal_code": {
      "type": "string"
    },
    "country_name": {
      "type": "string"
    }
  },
  "title": "Address"
}