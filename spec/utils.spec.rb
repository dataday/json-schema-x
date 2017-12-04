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
      it 'raises the error' do
        expect { utility_class.raise_error(Exception) }.to raise_error Exception
      end
    end
  end

  describe '#get_field_type' do
    context 'when a type is specified but format is not specified' do
      it 'returns the type' do
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

    context 'when a type and format are both specified' do
      it 'returns the format' do
        fixtures = [
          { type: 'null', format: 'time', result: 'Time' },
          { type: 'null', format: 'date', result: 'Date' },
          { type: 'null', format: 'date_time', result: 'DateTime' },
          { type: 'null', format: 'email', result: 'String' },
          { type: 'null', format: 'phone', result: 'String' },
          { type: 'null', format: 'geo', result: 'Hash' },
          { type: 'null', format: 'adr', result: 'Hash' }
        ]

        fixtures.each do |fixture|
          result = utility_class.send(:get_field_type, fixture)
          expect(result).to eq fixture[:result]
        end
      end
    end

    context 'when neither type or format are specified' do
      it 'returns original input' do
        fixture = {}
        result = utility_class.send(:get_field_type, fixture)
        expect(result).to eq fixture
      end
    end
  end

  describe '#get_field_reference' do
    context 'when a valid reference is specified' do
      it 'returns the expected name space' do
        fixtures = [
          { ref: 'http://domain.co.uk/geo', result: 'geo' },
          { ref: 'http://domain.co.uk/geo#foo', result: 'geo' },
          { ref: 'http://domain.co.uk/#/definitions/geo', result: 'geo' },
          { ref: 'http://domain.co.uk/address', result: 'address' },
          { ref: 'http://domain.co.uk/address#foo', result: 'address' },
          {
            ref: 'http://domain.co.uk/schema#/definitions/address',
            result: 'address'
          }
        ]

        fixtures.each do |fixture|
          result = utility_class.send(:get_field_reference, fixture)
          expect(result).to eq fixture[:result]
        end
      end
    end
    context 'when a invalid reference is specified' do
      it 'returns the original reference' do
        fixtures = [
          { ref: '', result: '' }
        ]

        fixtures.each do |fixture|
          result = utility_class.send(:get_field_reference, fixture)
          expect(result).to eq fixture[:result]
        end
      end
    end
  end

  describe '#sanitise_string' do
    context 'when alphanumberic and symbols are specified' do
      it 'returns symbolised characters with hyphen preserved' do
        fixture = { input: '&d^/?><-+=7^d^9', result: :'d-7d9' }

        result = utility_class.send(:sanitise_string, fixture[:input])
        expect(result).to eq fixture[:result]
      end

      it 'returns symbolised characters with underscore preserved' do
        fixture = { input: '&d^/?><_+=7^d^9', result: :d_7d9 }

        result = utility_class.send(:sanitise_string, fixture[:input])
        expect(result).to eq fixture[:result]
      end
    end

    context 'when characters starting with a number are specified' do
      it 'returns symbolised characters starting with a number' do
        fixtures = [
          { input: '9^7^d^d', result: :'97dd' },
          { input: '7^d^9d^', result: :'7d9d' }
        ]

        fixtures.each do |fixture|
          result = utility_class.send(:sanitise_string, fixture[:input])
          expect(result).to eq fixture[:result]
        end
      end
    end

    context 'when UPPERCASE is specified' do
      it 'returns symbolised UPPERCASE characters' do
        fixtures = [
          { input: 'FOOBAR', result: :FOOBAR },
          { input: 'MOREFOOBAR', result: :MOREFOOBAR }
        ]

        fixtures.each do |fixture|
          result = utility_class.send(:sanitise_string, fixture[:input])
          expect(result).to eq fixture[:result]
        end
      end
    end

    context 'when camelCase is specified without snake_case conversion' do
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

    context 'when camelCase is specified with snake_case conversion' do
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

    context 'when snake_case is specified without snake_case conversion' do
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

    context 'when snake_case is specified with snake_case conversion' do
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
    context 'when a term is specified' do
      it 'returns a list containing the symbolised term' do
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
    context 'when a list of terms is specified' do
      it 'returns a list containing the symbolised terms' do
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
    context 'when an list of terms is specified' do
      it 'returns true for success' do
        fixture = {
          input: %w[fooBar FooBar foo_bar foo-bar foobar],
          result: true
        }

        result = utility_class.send(:is_array_of_strings, fixture[:input])
        expect(result).to eq fixture[:result]
      end
    end

    context 'when an list of numbers is specified' do
      it 'returns false for failure' do
        fixture = {
          input: [0, 1, 2, 3],
          result: false
        }

        result = utility_class.send(:is_array_of_strings, fixture[:input])
        expect(result).to eq fixture[:result]
      end
    end

    context 'when an empty list is specified' do
      it 'returns false for failure' do
        fixture = {
          input: [],
          result: false
        }

        result = utility_class.send(:is_array_of_strings, fixture[:input])
        expect(result).to eq fixture[:result]
      end
    end

    context 'when a invalid list is specified' do
      it 'returns false for failure' do
        fixture = {
          input: '',
          result: false
        }

        result = utility_class.send(:is_array_of_strings, fixture[:input])
        expect(result).to eq fixture[:result]
      end
    end
  end

  describe '#get_url_template' do
    context 'when a pre-configured template is specified' do
      it 'returns a valid template reference' do
        fixtures = [{
          input: :version,
          result: '{scheme}://{host}{/segments*}{#fragment}'
        }, {
          input: :reference,
          result: '{scheme}://{host}{/segments*}{#fragments*}'
        }, {
          input: :definition,
          result: '#/definitions{/segments*}'
        }]

        fixtures.each do |fixture|
          result = utility_class.send(:get_url_template, fixture[:input])
          expect(result.pattern).to eq fixture[:result]
        end
      end
    end

    context 'when a unconfigured template is specified' do
      it 'returns the \'version\' template reference' do
        fixture = {
          input: :unknown,
          result: '{scheme}://{host}{/segments*}{#fragment}'
        }

        result = utility_class.send(:get_url_template, fixture[:input])
        expect(result.pattern).to eq fixture[:result]
      end
    end
  end

  describe '#get_url' do
    context 'when a URL and template type are specified' do
      it 'returns hash with valid results' do
        fixtures = [{
          input: 'http://domain.co.uk/foo',
          type: :reference,
          result: 'foo'
        }, {
          input: 'http://domain.co.uk/bar',
          type: :reference,
          result: 'bar'
        }, {
          input: 'http://json-schema.org/draft-04/schema#',
          type: :version,
          result: 'draft-04'
        }, {
          input: 'http://json-schema.org/schema#',
          type: :version,
          result: 'schema'
        }, {
          input: '#/definitions/foo',
          type: :definition,
          result: 'foo'
        }, {
          input: '#/definitions/bar',
          type: :definition,
          result: 'bar'
        }]

        fixtures.each do |fixture|
          result = utility_class.send(:get_url, fixture[:input], fixture[:type])
          expect(result).to be_kind_of Hash
          expect(result['segments'].first).to eq fixture[:result]
        end
      end
    end
  end

  describe '#add_dependencies' do
    context 'when two dependents point at the same dependency' do
      it 'returns a normalised version of dependency relationship' do
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

    context 'when two dependents point at different dependencies' do
      it 'returns a valid version of the dependency relationship' do
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
      it 'returns an empty object' do
        result = utility_class.send(:get_dependencies)
        expect(result).to be_kind_of Hash
        expect(result).to be_empty
      end
    end
  end

  describe '#get_field_property' do
    context 'when a invalid property is specified' do
      it 'returns an empty list' do
        fixture = {
          input: {
            source: {
              parent: {
                required: true
              }
            }
          },
          result: []
        }

        result = utility_class.send(
          :get_field_property,
          fixture[:input],
          :unrequired
        )

        expect(result.to_a).to eq fixture[:result]
      end
    end

    context 'when a property with identical parent fields is specified' do
      it 'returns a list containing one reference to the parent field' do
        fixture = {
          input: {
            source: {
              parent: {
                required: true
              }
            },
            parent: {
              required: true
            }
          },
          result: [:parent]
        }

        result = utility_class.send(
          :get_field_property,
          fixture[:input],
          :required
        )

        expect(result.to_a).to eq fixture[:result]
      end
    end

    context 'when a valid property is specified' do
      it 'returns a list containing the parent field of that property' do
        fixture = {
          input: {
            source: {
              parent: {
                required: true
              }
            }
          },
          result: [:parent]
        }

        result = utility_class.send(
          :get_field_property,
          fixture[:input],
          :required
        )

        expect(result.to_a).to eq fixture[:result]
      end
    end
  end

  describe '#update_field_property' do
    context 'when duplicate list values are specified' do
      it 'returns a list of unique values' do
        fixture = {
          input: {
            required: [:item_one, :item_two, :item_one]
          },
          result: {
            required: [:item_one, :item_two]
          }
        }

        result = utility_class.send(
          :update_field_property,
          fixture[:input],
          :required
        )

        item_one = fixture[:result][:required].first
        item_two = fixture[:result][:required].last

        expect(result[:required].count(item_one)).to eq 1
        expect(result[:required].count(item_two)).to eq 1
      end
    end
  end

  describe '#add_associations' do
    context 'when single associations are specified' do
      it 'returns a list containing the stated association' do
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

    context 'when multiple associations are specified' do
      it 'returns a list containing the stated associations' do
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
    context 'when multiple associations are specified' do
      it 'returns a string of the stated associations' do
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
      it 'returns a string containing a line break' do
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
    context 'when a partial file is created without locales' do
      it 'returns a blank string' do
        result = utility_class.send(
          :partial,
          'partials/_mongoid.field',
          { locales: {} }
        )

        expect(result).to eq ''
      end
    end

    context 'when a partial file is created with locales' do
      it 'returns a populated partial containing one field reference' do
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
