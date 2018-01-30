# frozen_string_literal: true
require 'spec_helper'
require 'schema'
require 'schema/utils'

describe Utils do
  subject :utility_class {
    # mock object for utilities inclusion
    Class.new {
      # allow read access to :config
      attr_reader :config
      # include Utils module
      include Utils
      # initialise mock class
      def initialize
        schema_empty = Schema.new('spec/fixtures/empty.json')
        @config = schema_empty.config
        initialize_utils_mixin
      end
      # call #new (rspec > 3.3.0)
    }.new
  }

  describe '#raise_error' do
    context 'when a error is specified' do
      it 'raises a error' do
        expect { utility_class.raise_error(Exception) }.to raise_error Exception
      end
    end
  end

  describe '#get_field_type' do
    context 'when a field type is specified, but a format is not' do
      it 'returns the field type' do
        fixtures = [
          { type: 'null', result: 'Null' },
          { type: 'integer', result: 'Integer' },
          { type: 'array', result: 'Array' },
          { type: 'object', result: 'Hash' },
          { type: 'number', result: 'Float' },
          { type: 'string', result: 'String' },
          { type: 'boolean', result: 'Mongoid::Boolean' }
        ]

        fixtures.each do |fixture|
          result = utility_class.send(:get_field_type, fixture)
          expect(result).to eq fixture[:result]
        end
      end
    end

    context 'when a field type and format are specified' do
      it 'returns the field format' do
        fixtures = [
          { type: 'null', format: 'time', result: 'Time' },
          { type: 'integer', format: 'date', result: 'Date' },
          { type: 'array', format: 'date_time', result: 'DateTime' },
          { type: 'object', format: 'email', result: 'String' },
          { type: 'number', format: 'phone', result: 'String' },
          { type: 'string', format: 'geo', result: 'Hash' },
          { type: 'boolean', format: 'adr', result: 'Hash' }
        ]

        fixtures.each do |fixture|
          result = utility_class.send(:get_field_type, fixture)
          expect(result).to eq fixture[:result]
        end
      end
    end

    context 'when a field type and format are not specified' do
      it 'returns no field type' do
        fixture = {}
        result = utility_class.send(:get_field_type, fixture)
        expect(result).to eq fixture
      end
    end
  end

  describe '#has_field_reference' do
    context 'when a field reference is specified' do
      it 'returns true' do
        fixtures = [
          { ref: 'foo', key: :ref, result: true },
          { ref: 'bar', key: :ref, result: true }
        ]

        fixtures.each do |fixture|
          result = utility_class.send(
            :has_field_reference,
            fixture, fixture[:key]
          )
          expect(result).to eq fixture[:result]
        end
      end
    end

    context 'when a field reference is not specified' do
      it 'returns false' do
        fixtures = [
          { foo: '', key: :ref, result: false },
          { ref: nil, key: :ref, result: false },
          { ref: '', key: :ref, result: false }
        ]

        fixtures.each do |fixture|
          result = utility_class.send(
            :has_field_reference,
            fixture, fixture[:key]
          )
          expect(result).to eq fixture[:result]
        end
      end
    end
  end

  describe '#get_field_schema' do
    context 'when a reference is specified' do
      it 'returns the schema' do
        fixtures = [
          { ref: 'foo', result: nil },
          { ref: 'bar', result: nil },
          { ref: '', result: nil },
          { ref: nil, result: nil },
          { ref: {}, result: nil }
        ]

        fixtures.each do |fixture|
          result = utility_class.send(:get_field_schema, fixture[:ref])
          expect(result).to eq fixture[:result]
        end
      end
    end
  end

  describe '#get_field_reference' do
    context 'when a schema URL is specified' do
      it 'returns the namespace' do
        fixtures = [
          { ref: 'http://domain.co.uk/foo', result: 'foo' },
          { ref: 'http://domain.co.uk/foo#bar', result: 'foo' },
          { ref: 'http://domain.co.uk/#/definitions/foo', result: 'foo' },
          { ref: 'http://domain.co.uk/foo#/definitions/bar', result: 'bar' },
          { ref: 'http://domain.co.uk/foo/#/definitions/bar', result: 'bar' }
        ]

        fixtures.each do |fixture|
          result = utility_class.send(:get_field_reference, fixture)
          expect(result).to eq fixture[:result]
        end
      end
    end

    context 'when a invalid schema URL is specified' do
      it 'returns nothing' do
        fixtures = [
          { ref: '', result: nil },
          # { ref: 'http://', result: nil },
          { ref: 'http://domain.co.uk', result: nil },
          { ref: 'http://domain.co.uk/', result: nil },
          { ref: 'http://domain.co.uk/#', result: nil }
        ]

        fixtures.each do |fixture|
          result = utility_class.send(:get_field_reference, fixture)
          expect(result).to eq fixture[:result]
        end
      end
    end
  end

  describe '#sanitise_string' do
    context 'when mixed characters, alphanumberic + symbols, and case are specified' do
      it 'returns valid symbolised characters, preserving case and format' do
        fixtures = [
          { input: '&foo^/?><-+=0^bar^1', result: :'foo-0bar1' },
          { input: '&foo^/?><_+=0^bar^1', result: :foo_0bar1 },
          { input: '&foo^/?><-_+=0^bar^1', result: :'foo-_0bar1' },
          { input: '&1^0?<foo+=0^bar^1', result: :'10foo0bar1' },
          { input: '&1^?<foo+=0^bar^1', result: :'1foo0bar1' },
          { input: '&FOO^?<BAR+=^^', result: :FOOBAR },
          { input: '&BAR^?<FOO+=BAR^^', result: :BARFOOBAR },
          { input: '&1^?<0+=^^', result: :'10' },
          { input: '&BAR^?<FOO+=BAR^^', result: :BARFOOBAR }
        ]

        fixtures.each do |fixture|
          result = utility_class.send(:sanitise_string, fixture[:input])
          expect(result).to eq fixture[:result]
        end
      end
    end

    context 'when camelCase is specified but snake_case conversion is not' do
      it 'returns symbolised camelCase characters' do
        fixtures = [
          { input: 'fooBar', result: :fooBar },
          { input: 'MoreFooBar', result: :MoreFooBar }
        ]

        fixtures.each do |fixture|
          result = utility_class.send(:sanitise_string, fixture[:input])
          expect(result).to eq fixture[:result]
        end
      end
    end

    context 'when camelCase and snake_case conversion are specified' do
      it 'returns symbolised snake_case characters' do
        fixtures = [
          { input: 'fooBar', result: :foo_bar },
          { input: 'MoreFooBar', result: :more_foo_bar }
        ]

        fixtures.each do |fixture|
          result = utility_class.send(:sanitise_string, fixture[:input], true)
          expect(result).to eq fixture[:result]
        end
      end
    end

    context 'when snake_case is specified but snake_case conversion is not' do
      it 'returns symbolised snake_case characters' do
        fixtures = [
          { input: 'foo_bar', result: :foo_bar },
          { input: 'more_foo_bar', result: :more_foo_bar }
        ]

        fixtures.each do |fixture|
          result = utility_class.send(:sanitise_string, fixture[:input])
          expect(result).to eq fixture[:result]
        end
      end
    end

    context 'when snake_case and snake_case conversion are specified' do
      it 'returns symbolised snake_case characters' do
        fixtures = [
          { input: 'foo_bar', result: :foo_bar },
          { input: 'more_foo_bar', result: :more_foo_bar }
        ]

        fixtures.each do |fixture|
          result = utility_class.send(:sanitise_string, fixture[:input], true)
          expect(result).to eq fixture[:result]
        end
      end
    end
  end

  describe '#symbolise_array_strings' do
    context 'when a single term is specified' do
      it 'returns a list containing a single symbolised term' do
        fixtures = [
          { input: 'fooBar', result: [:foo_bar] },
          { input: 'FooBar', result: [:foo_bar] },
          { input: 'foo_bar', result: [:foo_bar] },
          { input: 'foo-bar', result: [:foo_bar] },
          { input: 'foobar', result: [:foobar] }
        ]

        fixtures.each do |fixture|
          result = utility_class.send(:symbolise_array_strings, fixture[:input])
          expect(result).to eq fixture[:result]
        end
      end
    end
  end

  describe '#normalise_array_value' do
    context 'when multiple terms are specified' do
      it 'returns a list containing multiple symbolised terms' do
        fixture = {
          input: %w[fooBar FooBar foo_bar foo-bar foobar],
          result: %i[foo_bar foo_bar foo_bar foo_bar foobar]
        }

        result = utility_class.send(:normalise_array_value, fixture[:input])
        expect(result).to eq fixture[:result]
      end
    end
  end

  describe '#is_array_of_strings' do
    context 'when multiple terms are specified' do
      it 'returns positively' do
        fixture = {
          input: %w[fooBar FooBar foo_bar foo-bar foobar],
          result: true
        }

        result = utility_class.send(:is_array_of_strings, fixture[:input])
        expect(result).to eq fixture[:result]
      end
    end

    context 'when a invalid term is specified' do
      it 'returns negatively' do
        fixtures = [
          { input: nil, result: false },
          { input: '', result: false },
          { input: [], result: false },
          { input: [0, 1, 2, 3], result: false },
          { input: ['', '', '', ''], result: false }
        ]

        fixtures.each do |fixture|
          result = utility_class.send(:is_array_of_strings, fixture[:input])
          expect(result).to eq fixture[:result]
        end
      end
    end
  end

  describe '#get_url_template' do
    context 'when a format is specified' do
      it 'returns a format' do
        fixtures = [{
          input: :version,
          result: '{scheme}://{host}{/segments*}{#fragment}'
        }, {
          input: :reference,
          result: '{scheme}://{host}{/segments*}{#fragments*}'
        }, {
          input: :definition,
          result: '#/definitions{/segments*}'
        }, {
          input: :unknown,
          result: '{scheme}://{host}{/segments*}{#fragment}'
        }]

        fixtures.each do |fixture|
          result = utility_class.send(:get_url_template, fixture[:input])
          expect(result.pattern).to eq fixture[:result]
        end
      end
    end
  end

  describe '#get_url' do
    context 'when a format is specified' do
      it 'returns the expected namespace' do
        fixtures = [{
          input: 'http://domain.co.uk/foo',
          format: :reference,
          result: 'foo'
        }, {
          input: 'http://domain.co.uk/bar',
          format: :reference,
          result: 'bar'
        }, {
          input: 'http://domain.co.uk/draft-04/foo#',
          format: :version,
          result: 'draft-04'
        }, {
          input: 'http://domain.co.uk/foo#',
          format: :unknown,
          result: 'foo'
        }, {
          input: 'http://domain.co.uk/foo#',
          format: :version,
          result: 'foo'
        }, {
          input: '#/definitions/foo',
          format: :definition,
          result: 'foo'
        }]

        fixtures.each do |fixture|
          result = utility_class.send(
            :get_url,
            fixture[:input],
            fixture[:format]
          )

          expect(result).to be_kind_of Hash
          expect(result['segments'].first).to eq fixture[:result]
        end
      end
    end
  end

  describe '#add_dependencies' do
    context 'when different dependents relate to the same dependency' do
      it 'returns the dependency as owner' do
        fixture = {
          input: {
            dependent_one: [:dependency_one],
            dependent_two: [:dependency_one]
          },
          result: {
            dependency_one: [:dependent_one, :dependent_two]
          }
        }

        input = fixture[:input]

        # add dependent one dependency
        dependent_one = input.keys.first
        dependent_one_dependency = input.values.first

        utility_class.send(
          :add_dependencies,
          dependent_one,
          dependent_one_dependency
        )

        # add dependent two dependency
        dependent_two = input.keys.last
        dependent_two_dependency = input.values.last

        utility_class.send(
          :add_dependencies,
          dependent_two,
          dependent_two_dependency
        )

        expect(utility_class.dependencies).to be_kind_of Hash
        expect(utility_class.dependencies).to eq fixture[:result]
      end
    end

    context 'when different dependents relate to different dependencies' do
      it 'returns the expected dependency' do
        fixture = {
          input: {
            dependent_one: [:dependency_one],
            dependent_two: [:dependency_two]
          },
          result: {
            dependency_one: [:dependent_one],
            dependency_two: [:dependent_two]
          }
        }

        input = fixture[:input]

        # add dependent one dependency
        dependent_one = input.keys.first
        dependent_one_dependency = input.values.first

        utility_class.send(
          :add_dependencies,
          dependent_one,
          dependent_one_dependency
        )

        # add dependent two dependency
        dependent_two = input.keys.last
        dependent_two_dependency = input.values.last

        utility_class.send(
          :add_dependencies,
          dependent_two,
          dependent_two_dependency
        )

        expect(utility_class.dependencies).to eq fixture[:result]
      end
    end
  end

  describe '#get_dependencies' do
    context 'when no dependencies are specified' do
      it 'returns a empty list of dependencies' do
        result = utility_class.send(:get_dependencies)
        expect(result).to be_kind_of Hash
        expect(result).to be_empty
      end
    end
  end

  describe '#get_field_property' do
    context 'when a invalid format is specified' do
      it 'returns a empty list of formats' do
        fixture = {
          input: {
            data: {
              field: {
                property: true
              }
            }
          },
          result: []
        }

        result = utility_class.send(
          :get_field_property,
          fixture[:input],
          :unkown
        )

        expect(result.to_a).to eq fixture[:result]
      end
    end

    context 'when a valid property is specified' do
      it 'returns the expected field' do
        fixture = {
          input: {
            data: {
              field: {
                property: true
              }
            }
          },
          result: %i(field)
        }

        result = utility_class.send(
          :get_field_property,
          fixture[:input],
          :property
        )

        expect(result.to_a).to eq fixture[:result]
      end
    end
  end

    context 'when a property name matches a field name' do
      it 'returns the expected field names' do
        fixtures = [{
          input: {
            data: {
              sub_field: {
                property: true
              }
            },
            field: {
              property: true
            }
          },
          result: [:sub_field, :field]
        }, {
          input: {
            data: {
              field: {
                property: true
              }
            },
            field: {
              property: true
            }
          },
          result: [:field]
        }]

        fixtures.each do |fixture|
          result = utility_class.send(
            :get_field_property,
            fixture[:input],
            :property
          )

          expect(result.to_a.sort).to eq fixture[:result].sort
        end
      end
    end

  describe '#update_field_property' do
    context 'when identical list values are specified' do
      it 'returns a condensed list of values' do
        fixture = {
          input: {
            property: [:item_one, :item_two, :item_one]
          },
          result: {
            property: [:item_one, :item_two]
          }
        }

        result = utility_class.send(
          :update_field_property,
          fixture[:input],
          :property
        )

        item_one = fixture[:result][:property].first
        item_two = fixture[:result][:property].last

        expect(result[:property].count(item_one)).to eq 1
        expect(result[:property].count(item_two)).to eq 1
      end
    end
  end

  describe '#add_associations' do
    context 'when a field is specified' do
      it 'returns the expected field description' do
        fixtures = [{
          input: { description: 'A description' },
          result: ['description: A description']
        }, {
          input: { properties: { item_one: '', item_two: '' } },
          result: ['properties: item_one, item_two']
        }, {
          input: { items: { type: 'string' } },
          result: ['items: string']
        }, {
          input: { ref: 'http://domain.co.uk/foo' },
          result: ["reference: http://domain.co.uk/foo
  # @todo: specify 'embedded_in :Empty' within class Foo"]
        }]

        fixtures.each do |fixture|
          result = utility_class.send(:add_associations, fixture[:input], [])
          expect(result).to eq fixture[:result]
        end
      end
    end

    context 'when multiple field associations are specified' do
      it 'returns the expected field descriptions' do
        fixture = {
          input: {
            description: 'A description',
            properties: { one: nil, two: '' },
            items: { type: 'string' },
            ref: 'http://domain.co.uk/foo'
          },
          result: [
            'description: A description',
            'properties: one, two',
            'items: string',
            "reference: http://domain.co.uk/foo
  # @todo: specify 'embedded_in :Empty' within class Foo"
          ]
        }

        result = utility_class.send(:add_associations, fixture[:input], [])
        expect(result).to eq fixture[:result]
      end
    end
  end

  describe '#get_field_associations' do
    context 'when multiple field associations are specified' do
      it 'returns the expected field description' do
        fixture = {
          input: {
            description: 'A description',
            properties: { one: nil }
          },
          result: "\n  # field description: A description, properties: one\n"
        }
        result = utility_class.send(:get_field_associations, fixture[:input])
        expect(result).to eq fixture[:result]
      end
    end

    context 'when no associations are specified' do
      it 'returns a single line break' do
        fixture = {
          input: {
            foo: 'bar',
            bar: 'foo'
          },
          result: "\n"
        }
        result = utility_class.send(:get_field_associations, fixture[:input])
        expect(result).to eq fixture[:result]
      end
    end
  end

  # @todo: stub partial response, and use a spec helper!
  describe '#partial' do
    context 'when requested without locales' do
      it 'returns a empty string' do
        result = utility_class.send(
          :partial,
          'partials/_mongoid.field',
          { locales: {} }
        )

        expect(result).to eq ''
      end
    end

    context 'when requested with locales' do
      it 'returns the expected field reference' do
        result = utility_class.send(
          :partial,
          'partials/_mongoid.field',
          {
            locales: {
              key: :foo,
              value: {
                field: {
                  description: 'A description'
                }
              }
            }
          }
        )

        expect(result).to eq "
  # field description: A description
  field :field, type: {:description=>\"A description\"}"
      end
    end
  end
end
