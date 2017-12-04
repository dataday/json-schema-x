# https://ruby-doc.org/stdlib-2.4.2/libdoc/ostruct/rdoc/OpenStruct.html
require 'ostruct'
# https://github.com/ruby-json-schema/json-schema
require 'json-schema'

# module Helpers
# @todo write tests
module Helpers
  # Gets the contents of a specified file
  # @param file [String] file path
  # @return [String] file contents
  def self.get_file_content(file)
    File.read file if File.exist? file
  end

  # Validates data matches schema expectations
  # @param schema [String] schema path
  # @param data [Hash] source data
  # @raise JSON::Schema::ValidationError
  # @return [String] file contents
  def self.validate(schema, source)
    JSON::Validator.validate!(schema, source)
  rescue JSON::Schema::ValidationError => error
    puts "#{schema[:title]} - JSON::Schema::ValidationError: #{error}"
  end

  # Updates database field values
  # @param value [mixed] field value
  # @return [mixed] updated field value
  def self.update_db_fields(value)
    # convert value to ISO 8601 DateTime, Date, Time format
    value = DateTime.parse(value.to_s).utc.iso8601 if value.to_s.match(/^.*UTC$/)
    value
  end

  # Gets JSON Schema data
  # @param schema [string] schema path
  # @return [Hash] schema name and json data
  def self.get_json_schema(schema)
    OpenStruct.new(
      # extract file name
      name: File.basename(schema, '.rb').to_sym,
      # extract json DATA from __END__ of schema file
      json: JSON.parse(
        File.read(schema).split("__END__\n")[-1],
        symbolize_names: true
      )
    )
  end
end
