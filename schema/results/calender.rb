# http://json-schema.org/draft-03/schema#
# A representation of an event

class Calender
  include Mongoid::Document
  include Mongoid::Timestamps

  # field description: Event starting time
  field :dtstart, type: DateTime
  # field description: Event ending time
  field :dtend, type: DateTime
  field :summary, type: String
  field :location, type: String
  field :url, type: String
  # field description: Event duration
  field :duration, type: Time
  # field description: Recurrence date
  field :rdate, type: DateTime
  # field description: Recurrence rule
  field :rrule, type: String
  field :category, type: String
  field :description, type: String
  # field reference: http://json-schema.org/geo
  # @todo: specify 'embedded_in :Calender' within class Geo
  embeds_one :geo

  # required fields
  validates :dtstart, :summary, presence: true
end

__END__
{
  "schema": "http://json-schema.org/draft-03/schema#",
  "type": "object",
  "description": "A representation of an event",
  "required": [
    "dtstart",
    "summary"
  ],
  "properties": {
    "dtstart": {
      "format": "date-time",
      "type": "string",
      "description": "Event starting time"
    },
    "dtend": {
      "format": "date-time",
      "type": "string",
      "description": "Event ending time"
    },
    "summary": {
      "type": "string"
    },
    "location": {
      "type": "string"
    },
    "url": {
      "type": "string",
      "format": "uri"
    },
    "duration": {
      "format": "time",
      "type": "string",
      "description": "Event duration"
    },
    "rdate": {
      "format": "date-time",
      "type": "string",
      "description": "Recurrence date"
    },
    "rrule": {
      "type": "string",
      "description": "Recurrence rule"
    },
    "category": {
      "type": "string"
    },
    "description": {
      "type": "string"
    },
    "geo": {
      "ref": "http://json-schema.org/geo"
    }
  },
  "title": "Calender"
}