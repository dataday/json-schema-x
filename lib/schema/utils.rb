#!/usr/bin/env ruby -w
# encoding: UTF-8

# https://github.com/hamstergem/hamster
require 'hamster'
# https://ruby-doc.org/stdlib-2.0.0/libdoc/json/rdoc/JSON.html
require 'json'
# https://github.com/slim-template/slim
require 'slim'

# Utility methods used during schema generation
# @author dataday
# @see https://spacetelescope.github.io/understanding-json-schema/reference/numeric.html
# @see https://docs.mongodb.com/mongoid/master/tutorials/mongoid-documents/#fields
# @see https://en.wikibooks.org/wiki/Ruby_Programming/Syntax/Literals#Numerics
module Utils
  attr_reader :dependencies, :types
  def self.included(base)
    base.class_exec do
      # Initialises mixin for inclusion
      # @return [void]
      def initialize_utils_mixin
        @dependencies = {}
        @types = Hamster::Hash[
          array: :Array,
          integer: :Integer,
          number: :Float,
          string: :String,
          boolean: :'Mongoid::Boolean',
          null: :Null,
          object: :Hash,
          date: :Date,
          date_time: :DateTime,
          time: :Time,
          uri: :String,
          email: :String,
          phone: :String,
          geo: :Hash,
          adr: :Hash
        ]
      end
    end
  end

  # Raises error experienced during execution
  # @raise [Mixed] exeception
  # @param error [Object] error object
  # @return [void]
  def raise_error(error)
    # @todo: log error
    raise error
  end

  # Gets literal field type or format
  # @param type [String] type value
  # @return [String] formatted string
  # @see @types
  def get_field_type(content)
    type, type_format = content.values_at(:type, :format)
    return content if type.nil? && type_format.nil?
    # formats have priority over type
    field_type = type_format ?
      sanitise_string(type_format, true) :
      sanitise_string(type, true)
    result = @types[field_type]
    "#{result}" if result
  end

  # Gets schema reference (schema URL)
  # @param type [String] type value
  # @return [String] formatted string
  def get_field_reference(content)
    reference = get_url(content[:ref], :reference)
    return content[:ref] if reference.nil?
    fragments = reference["fragments"]
    segments = reference["segments"]
    # inspect fragments
    # @todo: abstract fragment evaluation out
    unless fragments.nil?
      # find matching fragments
      match = fragments.find { |value|
        # match name space
        name_space = %r{\/definitions\/(.+)}.match(value)
        # return matched name space
        return name_space[1] unless name_space.nil?
      }
      return match unless match.nil?
    end
    # return first segment if no definitions exist
    return segments.first unless segments.nil?
  end

  # Sanitises a string to the expected format
  # Favours conversion to snake case symbols
  # @param value [Mixed] value to be sanitised
  # @param snake_case_keys [Boolean] enable snake cased keys
  # @return [Symbol] sanitised value
  # @todo revisit to allow for hyphens, dollars, etc
  def sanitise_string(value, snake_case_keys=false)
    # *disabled* return lower camel case formatted strings
    # return value.to_sym if value =~ /^[a-z]+[A-Z0-9][a-z0-9]+[A-Za-z0-9]*$/
    # remove '$' as prefixes, etc, e.g., $schema and $ref
    str = value.gsub(/[^a-zA-Z0-9_-]/, '')
    # convert to snake case where required
    str = str.underscore if snake_case_keys
    # convert to symbol
    str.to_sym
  end

  # Symbolises array values to a series of snake_case characters
  # @param source [String] string input
  # @param snake_case_keys [Boolean] enable snake cased keys
  # @return [Array] symbolised values
  # @see https://en.wikibooks.org/wiki/Ruby_Programming/Syntax/Literals
  def symbolise_array_strings(source, snake_case_keys=true)
    # returns snake case values
    return %I[#{sanitise_string(source, snake_case_keys)}]
  end

  # Normalise array values
  # @param source [Array] source data to be normalised
  # @return [Array] list of normalised values
  def normalise_array_value(source)
    source.map(&method(:symbolise_array_strings)).flatten!
  end

  # Determine if an source object is an array of strings
  # @param source [Mixed] source object
  # @return [Boolean] true if successful, otherwise false
  def is_array_of_strings(source)
    if source.is_a?(Array) && !source.empty?
      return source.all?{ |value| value.is_a? String }
    end
    false
  end

  # Gets preconfigured URL template by name
  # @param template [Symbol] template name, has :default
  # @return [Addressable::Template] URL template
  # @see Addressable::Template
  def get_url_template(template)
    schema = config.get(:schema)
    url = schema[:urls].fetch(template, schema[:urls][:version])
    Addressable::Template.new(url)
  end

  # Gets extracted URL via selected URL template
  # @param url [String] URL
  # @param template [Symbol] template name
  # @return [Hash] component parts of the URL
  def get_url(url, template)
    get_url_template(template).extract(url)
  end

  # Adds field dependencies for use with validation
  # @param dependent [Symbol] field name (dependent)
  # @param source [Array] list of source dependencies
  # @return [void]
  def add_dependencies(dependent, source)
    source.each do |dependency|
      dependents = @dependencies.fetch(dependency, [])
      # some fields may point at the same dependency,
      # to avoid duplicate validation the dependency
      # becomes the pointer to any dependent fields
      # e.g., dependency => [ dependent, dependent, ... ]
      @dependencies[dependency] = dependents.push(dependent)
    end
  end

  # Gets field dependencies for use with validation
  # @return [Hamster::Hash]
  def get_dependencies
    @dependencies
  end

  # Pretty prints source data as JSON
  # @param data [Hamster::Hash] source data
  # @return [JSON]
  # @see JSON.pretty_generate
  def pretty_print_json(source)
    JSON.pretty_generate(source)
  end

  # Gets fields associated to a named property
  # @param source [Hash] source data
  # @param property [Symbol] target property
  # @param fields [Hamster::Set] list of fields
  # @return [Hamster::Set] list of symbols
  # @see Hamster::List
  def get_field_property(source, property, fields=Hamster::Set[])
    source.each_key do |key|
      item = source[key]
      # continue if of the correct object type
      if item.is_a?(Hash)
        # add key to Hamster::Set if found
        fields = fields.add(key) if item[property] === true
        # continue recursion
        fields = get_field_property(item, property, fields)
      end
    end
    fields
  end

  # Updates fields associated to a named property
  # @param source [Hash] source data
  # @param property [Symbol] target property
  # @param fields [Hamster::Set] list of fields
  # @return [Hash] updated source data
  def update_field_property(source, property, fields=Hamster::Set[])
    field = source[property]
    # collect previous fields if present
    field.each do |value|
      # add previous fields
      fields = fields.add(value)
    end unless field.nil?
    # reassign fields
    source[property] = fields.to_a
    source
  end


  # Adds field associations
  # @param field [Hash] target field
  # @param results [Array] results array
  # @return [Array] list of associations
  def add_associations(field, results)
    schema = config.get(:schema)

    description = field[:description]
    results.push "description: #{description}" if description

    properties = field[:properties]
    results.push "properties: #{properties.keys.join(', ')}" if properties

    type = field.dig(:items, :type)
    results.push "items: #{type}" if type

    ref = field[:ref]
    if ref
      ref_key = get_field_reference(field).capitalize
      results.push "reference: #{ref}
  # @todo: specify 'embedded_in :#{schema[:name]}' within class #{ref_key}"
    end

    results
  end

  # Gets field associations
  # @param field [Hamster::Hash] field object
  # @return [String] formatted string
  def get_field_associations(field)
    results = []
    # add associations
    add_associations(field, results)
    # returns associations or line break
    results.length > 0 ?
      "\n  # field #{results * ', '}\n" :
      "\n"
  end

  # States template file inclusion
  # @param file [String] template file
  # @param locales [Hash] template locales
  # @return [Slim::Template] template
  # @see Slim::Template
  def partial(file, locales)
    template = config.get(:template)
    options = template[:options]
    path = "#{template[:root]}/#{file}.slim"
    Slim::Template.new(
      # delegate file read to slim
      path,
      # declare default options
      options
    ).render(
      # ensure helpers are scoped
      self,
      # pass locales via parameters
      locales
    )
  end
end
