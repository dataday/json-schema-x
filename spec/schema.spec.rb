# frozen_string_literal: true
require 'spec_helper'
require 'schema'

describe Schema do
  # source data fixture paths
  let :minimal { 'spec/fixtures/minimal.json' }
  let :full { 'spec/fixtures/full.json' }
  let :empty { 'spec/fixtures/empty.json' }

  # mock objects
  subject :schema_double { class_double(Schema).as_stubbed_const }
  subject :schema_instance { instance_double(Schema, init: true) }

  # test classes
  subject :schema_empty { Schema.new(empty) }
  subject :schema_minimal { Schema.new(minimal) }
  subject :schema_full { Schema.new(full) }

  # allow references to generate_document method
  def allow_generate_document
    allow_any_instance_of(Schema).to receive(
      :generate_document
    ).and_return(true)
  end

  # allow references to publish_document method
  def allow_publish_document
    allow_any_instance_of(Schema).to receive(
      :publish_document
    ).and_return(true)
  end

  describe '#new' do
    # source data fixture paths
    let :error_parser { 'spec/fixtures/error-parser.json' }
    let :error_no_file { 'spec/fixtures/error-no-file.json' }
    let :error_bad_type { 0 }

    context 'when valid input is specified' do
      it 'creates an instance of Schema' do
        expect(schema_double).to receive(:new).with(minimal)
        Schema.new(minimal)
      end
    end

    context 'when invalid input is specified' do
      it 'raises an error when the file argument is missing' do
        expect { Schema.new }.to raise_error ArgumentError
      end

      it 'raises an error when no file exists' do
        expect { Schema.new(error_no_file) }.to raise_error Errno::ENOENT
      end

      it 'raises an error when file content is malformed' do
        expect { Schema.new(error_parser) }.to raise_error JSON::ParserError
      end

      it 'raises an error when the file argument type isn\'t expected' do
        expect { Schema.new(error_bad_type) }.to raise_error TypeError
      end
    end
  end

  describe '#init' do
    context 'when valid input is specified' do
      it 'can be called on a instance of Schema' do
        expect(schema_instance.init).to eq true
        schema = Schema.new(minimal)
        schema.init
      end
    end
  end

  describe 'source' do
    context 'when specified' do
      it 'includes the expected references' do
        %w[type $schema required properties description].each do |fixture|
          result = schema_minimal.source[fixture]
          expect(result).to_not be_nil
        end
      end

      it 'doesn\'t include a \'title\' reference' do
        result = schema_minimal.source['title']
        expect(result).to be_nil
      end
    end
  end

  describe 'tranformations' do
    context 'when schema exceptions are specified' do
      it 'responds with exceptions excluded' do
        fixture = { 'definitions' => {} }
        result = schema_minimal.send(:transform, fixture)
        expect(result[:definitions]).to be_nil
      end
    end

    context 'when schema properties are specified' do
      it 'responds with the expected properties' do
        fixture = {
          'properties' => {
            'string' => { 'type' => 'string' }
          }
        }
        result = schema_minimal.send(:transform, fixture)
        type = result.dig(:properties, :string, :type)
        expect(type).to be_kind_of String
      end
    end
  end

  describe 'additions' do
    context 'when a schema title is specified' do
      it 'reflects the source file name' do
        fixture = {}
        result = schema_minimal.send(:add_title, fixture)
        expect(result[:title]).to be_kind_of String
        expect(result[:title]).to eq 'Minimal'
      end
    end

    context 'when a schema property is not specified' do
      it 'reflects the default reference (http://json-schema.org/schema#)' do
        fixture = {}
        result = schema_minimal.send(:add_schema_url, fixture)
        expect(result[:schema]).to be_kind_of String
        expect(result[:schema]).to eq 'http://json-schema.org/schema#'
      end
    end

    context 'when a schema property is specified' do
      it 'reflects the original reference' do
        fixture = { schema: 'original_schema' }
        result = schema_minimal.send(:add_schema_url, fixture)
        expect(result[:schema]).to be_kind_of String
        expect(result[:schema]).to eq 'original_schema'
      end
    end

    context 'when required fields are specified' do
      it 'expects required fields to be included' do
        fixture = {
          required: [:string],
          properties: {
            string: {
              type: 'string'
            },
            number: {
              type: 'number', required: true
            }
          }
        }

        result = schema_minimal.send(:add_required_fields, fixture)
        expect(result[:required]).to include :string
        expect(result[:required]).to include :number
      end
    end
  end

  describe 'generation' do
    before :each { allow_generate_document }

    context 'when data is not specified' do
      it 'expects no data to be returned' do
        fixture = {}
        result = schema_minimal.send(:generate, fixture)
        expect(result).to be_kind_of Hash
        expect(result).to be_empty
      end
    end

    context 'when data is specified' do
      it 'expects data to be returned' do
        fixture = {
          input: {
            properties: {
              foo: { type: 'string' }
            }
          },
          result: {
            properties: {
              foo: { type: 'string' }
            }
          }
        }

        result = schema_minimal.send(:generate, fixture[:input])
        expect(result).to eq fixture[:result]
      end
    end
  end

  describe 'document' do
    before :each { allow_publish_document }

    context 'when data is specified' do
      it 'expects data to be returned' do
        file = File.expand_path('./fixtures/schema.rb', __dir__)
        result = Helpers.get_file_content(file)

        fixture = {
          input: {
            title: 'Schema',
            schema: 'http://json-schema.org/draft-04/schema#',
            description: 'A Schema',
            properties: {
              foo: { type: 'string' }
            }
          },
          result: result
        }

        result = schema_full.send(:generate_document, fixture[:input])
        expect(result).to eq fixture[:result]
      end
    end
  end
end
