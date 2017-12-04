#!/usr/bin/env ruby -w
# encoding: UTF-8

# http://api.rubyonrails.org/classes/ActiveSupport/Inflector.html
require 'active_support/core_ext/string'
# https://github.com/sporkmonger/addressable
require 'addressable'
# https://github.com/hamstergem/hamster
require 'hamster'
# https://ruby-doc.org/stdlib-2.0.0/libdoc/json/rdoc/JSON.html
require 'json'
# https://github.com/slim-template/slim
require 'slim'

# utilities
require_relative 'schema/utils'

# Transforms JSON Schema documents to custom output via slim template markup.
# @author dataday
# @abstract
class Schema
  attr_reader :version, :source, :schema, :config

  # Include utilities as instance methods
  # @see Utils
  include Utils

  # Initializes schema class
  # @param file [String] JSON schema file
  def initialize(file)
    root = File.expand_path('../', __dir__)
    file = File.expand_path(file, root)
    name = File.basename(file, '.json')
    data = File.read(file).freeze

    @schema = nil
    @version = '0.1.0'.freeze
    @source = Hamster::Hash[JSON.parse(data)]
    @config = Hamster::Hash[
      snake_case_keys: true,
      paths: {
        input: "#{root}/schema/input",
        output: "#{root}/schema/results"
      },
      schema: {
        name: "#{sanitise_string(name)}".upcase_first,
        versions: %w[schema hyper-schema draft-03 draft-04],
        exceptions: %I[definitions],
        urls: {
          default: 'http://json-schema.org/schema#',
          version: '{scheme}://{host}{/segments*}{#fragment}',
          reference: '{scheme}://{host}{/segments*}{#fragments*}',
          definition: '#/definitions{/segments*}'
        }
      },
      template: {
        root: "#{root}/schema/templates",
        options: {
          disable_escape: true,
          encoding: 'utf-8'
        }
      }
    ]
    # initialise utilities
    initialize_utils_mixin
  # handle errors
  rescue StandardError,
    TypeError,
    Errno::ENOENT,
    JSON::ParserError,
    ArgumentError => error
    raise_error(error)
  end

  # Adds required field associations
  # @return [void]
  def init
    @schema = transform @source
    @schema = add_title @schema
    @schema = add_schema_url @schema
    @schema = add_required_fields @schema
    @schema = generate @schema
  end

  # Generates schema from source data
  # @param source [Hamster::Hash] source data
  # @return [Hash] schema data
  # @see Slim::Template
  def generate(source)
    # return data without properties
    return source if source[:properties].nil? || source[:properties].keys.empty?
    # generates Slim template output
    generate_document(source)
    # returns source data
    source
  end

  private

  # Transform source data (immutable to mutable hash)
  # @param source [Hamster::Hash] source data
  # @return [Hash] updated source data
  def transform(source)
    results = {}
    schema = config.get(:schema)
    exceptions = schema[:exceptions]
    # tranform source data
    source.each_key do |key|
      # sanitise key name
      clone_key = sanitise_string(key, config.get(:snake_case_keys))
      # fetch original key value
      clone_value = source.fetch(key)
      # ignore unsupported schema references
      next if exceptions.include?(clone_key)
      # symbolise array values or pass cloned object through
      item = is_array_of_strings(clone_value) ?
        normalise_array_value(clone_value) :
        clone_value
      # create and assign result
      results[clone_key] = item.is_a?(Hash) ?
        # continue recursion
        transform(item) :
        # store item
        item
    end
    results
  end

  # Publishes source data to file
  # @param document [string] document
  # @return [void]
  def publish_document(document)
    schema = config.get(:schema)
    paths = config.get(:paths)
    file = "#{paths[:output]}/#{schema[:name].downcase}"
    puts "\n>> #{file}"
    # puts document
    File.write("#{file}.rb", document)
  end

  # Generates slim formatted template output
  # @param data [Hash] template data
  # @return [void]
  def generate_document(data)
    template = config.get(:template)
    options = template[:options]
    file = "#{template[:root]}/mongoid.slim"
    # create template
    document = Slim::Template.new(
      # delegate file read to slim
      file,
      # declare default options
      options
    )
    .render(
      # ensure helpers are scoped
      self,
      # pass data via parameter
      data: data
    )
    # publish data to file
    publish_document(document)
    # return document
    document
  end

  # Adds a source title
  # @param source [Hash] source data
  # @return [Hash] updated source data
  def add_title(source)
    schema = config.get(:schema)
    source[:title] = schema[:name]
    source
  end

  # Adds JSON Schema specific URL
  # @param source [Hash] source data
  # @return [void]
  def add_schema_url(source)
    schema = config.get(:schema)
    return source if source[:schema]
    source[:schema] = schema.dig(:urls, :default)
    source
  end

  # Adds required field associations
  # @param source [Hash] source data
  # @return [Hash] updated source data
  # @todo accompany fields with :required and specify the following locally:
  # Mongoid::Fields.option :required do |model, field, value|
  #   model.validates field, presence: true if value
  # end
  def add_required_fields(source)
    # retrieve required associations
    fields = get_field_property(source, :required)
    # continue if fields are populated
    return source unless fields.is_a?(Hamster::Set) && fields.size > 0
    # update source with associations
    update_field_property(source, :required, fields)
    # return source
    source
  end
end
