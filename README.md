# JSON Schema to `X`

## Introduction

This project was originally borne from the desire to reverse engineer simple [JSON Schema](http://json-schema.org/documentation.html) documents into different formats, say from [Scala case classes](https://github.com/coursera/autoschema) to `X` format, but more recently became useful for converting simple schemas into a [mongoid document](https://docs.mongodb.com/mongoid/master/tutorials/mongoid-documents/) friendly format.

The code is not fully featured but has support for some features as and when it was needed, for example, embedded schema [definitions](https://spacetelescope.github.io/understanding-json-schema/structuring.html) aren't supported but simple embedded references via `$ref` URLs are. Further supported can always be added but in the meantime the project may be of use to someone.

## Install

```bash
$ git clone git@github.com:dataday/json-schema-x.git && cd json-schema-x
$ bundle install --path vendor/bundle
$ bundle exec ruby bin/generate # generates examples from samples
```

## Generation

- [bin/generate](./bin/generate): schema generation file
- [schema/input](./schema/input): JSON Schema input files
- [schema/results](./schema/results): templated result files

The [example shown below](./schema/results/address.rb) was created from a sample schema provided by [json-schema.org](http://json-schema.org). This example can be generated using the following command. Executing this command will create example [files](./schema/results) containing both Ruby as well as the original JSON Schema.

```bash
$ bundle exec ruby bin/generate
>> /path/to/json-schema-x/schema/results/address.rb
...
```
```ruby
# http://json-schema.org/draft-04/schema#
# An Address following the convention of http://microformats.org/wiki/hcard

class Address
  include Mongoid::Document
  include Mongoid::Timestamps

  field :country_name, type: String
  field :region, type: String
  field :locality, type: String
  field :street_address, type: String
  field :postal_code, type: String
  field :post_office_box, type: String
  field :extended_address, type: String

  # :street_address dependents: post_office_box, extended_address
  validates :street_address, presence: true

  # required fields
  validates :locality, :region, :country_name, presence: true
end

__END__
...
```
```json
{
  "schema": "http://json-schema.org/draft-04/schema#",
  "properties": {
    "country_name": {
      "type": "string"
    },
    "region": {
      "type": "string"
    },
    "locality": {
      "type": "string"
    },
    "street_address": {
      "type": "string"
    },
    "postal_code": {
      "type": "string"
    },
    "post_office_box": {
      "type": "string"
    },
    "extended_address": {
      "type": "string"
    }
  },
  "dependencies": {
    "post_office_box": [
      "street_address"
    ],
    "extended_address": [
      "street_address"
    ]
  },
  "type": "object",
  "required": [
    "locality",
    "region",
    "country_name"
  ],
  "title": "Address",
  "description": "An Address following the convention of http://microformats.org/wiki/hcard"
}
```

Embedded documents require manual intervention. A simple `@todo` is added to fields which need special treatment, for example:

```ruby
# >> foo.rb
...
# field reference: http://json-schema.org/bar
# @todo: specify 'embedded_in :Foo' within class Bar
embeds_one :bar
...
```

The reference above would normally stem from the original reference shown below:

```json
# >> foo.json
...
"bar": {
  "$ref": "http://json-schema.org/bar"
}
...
```

## Validation

- [bin/validate](./bin/validate): schema validation file
- [mongoid.yml](./mongoid.yml): mongoid database configuration file

The results of schema generation can be validated by using the following command. This command has been provided for test purposes and can be customised to suit future need.

The approach includes the seralisation of schema test data to create a [mongoid](https://docs.mongodb.com/mongoid) friendly instance. This data can then be saved to [mongodb](https://www.mongodb.com/) but prior to saving the data is validated against it's respective JSON Schema. Errors raised as a result, either through the validation enforced by JSON Schema or at the point of [mongoid validation](https://mongoid.github.io/old/en/mongoid/docs/validation.html) when trying to save the data, and reported on a file by file basis. The JSON Schema used during validation can be found locally to each mongoid schema file, e.g., [address.rb](./schema/results/address.rb).

```bash
$ bundle exec ruby bin/validate
address - JSON Schema validation successful
...
```

## Caveats

There is a small, but no doubt noticable, difference between the JSON Schema [input](./schema/input) and [results](./schema/results). During schema generation, the property key is sanitised and it's format is optionally converted to [snake case](https://en.wikipedia.org/wiki/Snake_case). This feature can be ironed out if need be.

## Tests

Tests can be ran using this command.

```bash
$ bundle exec rspec spec/* # without coverage
$ export ENV=coverage; bundle exec rspec spec/* # with coverage
```

## Documentation

The following command will publish documentation associated to the project.

```bash
$ bundle exec yardoc
```

## Linting

The following commands can be ran for [Reek](https://github.com/troessner/reek) code smell detector and [slim-lint](https://github.com/sds/slim-lint), for linting [slim](https://github.com/slim-template/slim) templates, respectively.

```bash
$ bundle exec reek # ruby code
$ bundle exec slim-lint lib/schema/templates # slim templates
```

## Todo

Numerous, but again I hope the project proves useful to someone.

## Versioning

This project uses [Semantic Versioning](http://semver.org).

## Author

- [dataday](https://github.com/dataday)

## License

[MIT LICENSE](./MIT-LICENSE)
