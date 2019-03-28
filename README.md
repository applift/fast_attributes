# FastAttributes
[![Gem Version](http://img.shields.io/gem/v/fast_attributes.svg)](http://rubygems.org/gems/fast_attributes)
[![Build Status](http://img.shields.io/travis/applift/fast_attributes.svg)](https://travis-ci.org/applift/fast_attributes)
[![Coverage Status](http://img.shields.io/coveralls/applift/fast_attributes.svg)](https://coveralls.io/r/applift/fast_attributes?branch=master)
[![Code Climate](http://img.shields.io/codeclimate/github/applift/fast_attributes.svg)](https://codeclimate.com/github/applift/fast_attributes)
[![Dependency Status](http://img.shields.io/gemnasium/applift/fast_attributes.svg)](https://gemnasium.com/applift/fast_attributes)

## Motivation
There are already a lot of good and flexible gems which solve a similar problem, allowing attributes to be defined with their types, for example: [virtus](https://github.com/solnic/virtus) or [attrio](https://github.com/jetrockets/attrio). However, the disadvantage of these gems is performance. So, the goal of `fast_attributes` is to provide a simple solution which is fast, understandable and extendable.

This is the [performance benchmark](https://github.com/applift/fast_attributes/blob/master/benchmarks/comparison.rb) of `fast_attributes` compared to other popular gems.

```
Comparison:
FastAttributes: without values                       :  1528209.4 i/s
FastAttributes: integer values for integer attributes:    88794.2 i/s - 17.21x slower
FastAttributes: string values for integer attributes :    77673.3 i/s - 19.67x slower
Virtus: integer values for integer attributes        :    21104.7 i/s - 72.41x slower
Attrio: integer values for integer attributes        :    11932.2 i/s - 128.07x slower
Attrio: string values for integer attributes         :    11007.2 i/s - 138.84x slower
Virtus: without values                               :    10151.0 i/s - 150.55x slower
Attrio: without values                               :     7164.3 i/s - 213.31x slower
Virtus: string values for integer attributes         :     3195.6 i/s - 478.22x slower
```

## Installation

Add this line to your application's Gemfile:

    gem 'fast_attributes'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fast_attributes

## Usage

Define getter/setter methods:
```ruby
class Book
  extend FastAttributes

  attribute :title, :name, String
  attribute :pages,        Integer
  attribute :authors,      Array
  attribute :published,    Date
  attribute :sold,         Time
  attribute :finished,     DateTime
end

book = Book.new
book.title     = 'There and Back Again'
book.name      = 'The Hobbit'
book.pages     = '200'
book.authors   = 'Tolkien'
book.published = '1937-09-21'
book.sold      = '2014-06-25 13:45'
book.finished  = '1937-08-20 12:35'

#<Book:0x007f9a0110be20
 @authors=["Tolkien"],
 @finished=
  #<DateTime: 1937-08-20T12:35:00+00:00 ((2428766j,45300s,0n),+0s,2299161j)>,
 @name="The Hobbit",
 @pages=200,
 @published=#<Date: 1937-09-21 ((2428798j,0s,0n),+0s,2299161j)>,
 @sold=2014-06-25 13:45:00 +0200,
 @title="There and Back Again">
```

To generate `initialize` and `attributes` methods, attribute definition should be wrapped with `define_attributes`:
```ruby
class Book
  extend FastAttributes

  define_attributes initialize: true, attributes: true do
    attribute :title, :name, String
    attribute :pages,        Integer
    attribute :authors,      Array
    attribute :published,    Date
    attribute :sold,         Time
    attribute :finished,     DateTime
  end
end

book = Book.new(
  title:     'There and Back Again',
  name:      'The Hobbit',
  pages:     '200',
  authors:   'Tolkien',
  published: '1937-09-21',
  sold:      '2014-06-25 13:45',
  finished:  '1937-08-20 12:35'
)

book.attributes
{"title"=>"There and Back Again",
 "name"=>"The Hobbit",
 "pages"=>200,
 "authors"=>["Tolkien"],
 "published"=>#<Date: 1937-09-21 ((2428798j,0s,0n),+0s,2299161j)>,
 "sold"=>2014-06-25 13:45:00 +0200,
 "finished"=>
  #<DateTime: 1937-08-20T12:35:00+00:00 ((2428766j,45300s,0n),+0s,2299161j)>}
```

## Default values

Requires `define_attributes` to be used with `initialize: true` (this is where the default values are set):

```ruby
class Book
  extend FastAttributes

  define_attributes initialize: true do
    attribute :author, String, default: "Some String"
  end
end

book = Book.new
book.attributes
{"author" => "Some String"}
```

## Attributes via accessors

Sometimes you want `attributes` to return the value of your accessors, rather than the instance variables.
This is slower than using ivars directly, so use `attributes: :accessors`:

```ruby
class Book
  extend FastAttributes

  define_attributes attributes: :accessors do
    attribute :author, String
  end

  def author
    @author || "No author set"
  end
end

book = Book.new
book.attributes
{"author" => "No author set"}
```

## Collection Member Coercions

```
class Book
  include Virtus.model

  attribute :page_numbers, Array[Integer]
end

book = Book.new(:page_numbers => %w[1 2 3])
book.page_numbers # => [1, 2, 3]
```

### Support EmbeddedValues, too!

``` ruby
class Address
  extend FastAttributes

  define_attributes initialize: true, attributes: true do
    attribute :address,     String
    attribute :locality,    String
    attribute :region,      String
    attribute :postal_code, String
  end
end

FastAttributes.set_type_casting(Address, 'Address.new(%s)')

class User
  extend FastAttributes

  define_attributes initialize: true, attributes: true do
    attribute :name, String
    attribute :addresses, Set[Address]
  end
end
```

## Custom Type
It's easy to add a custom attribute type.
```ruby
FastAttributes.set_type_casting(OpenStruct, 'OpenStruct.new(name: %s)')

class Book
  extend FastAttributes
  attribute :author, OpenStruct
end

book = Book.new
book.author = 'Rowling'
book.author
# => #<OpenStruct name="Rowling">
```

Notice, that second parameter is a string. It's necessary because this code is compiled into a ruby method in runtime. The placeholder `%s` represents a value which this method accepts.

It's possible to refer to a placeholder several times.
```ruby
Size = Class.new(Array)
FastAttributes.set_type_casting Size, <<-EOS
  Size[%s, %s]
EOS

class Square
  extend FastAttributes
  attribute :size, Size
end

square = Square.new
square.size = 5
square.size
# => [5, 5]
```

Method `FastAttributes.set_type_casting` generates the following template:
```ruby
FastAttributes.set_type_casting String, 'String(%s)'
# begin
#   case %s
#   when nil    then nil
#   when String then %s
#   else String(%s)
#   end
# rescue => e
#   raise FastAttributes::TypeCast::InvalidValueError, %(Invalid value "\#{%s}" for attribute "%a" of type "String")
# end
```
and when the attribute is defined, `fast_attributes` generates the following setter method:
```ruby
class A
  extend FastAttributes
  attribute :name, String
end

# def name=(value)
#   @name = begin
#     case value
#     when nil    then nil
#     when String then value
#     else String(value)
#     end
#   rescue => e
#     raise FastAttributes::TypeCast::InvalidValueError, %(Invalid value "#{value}" for attribute "name" of type "String")
#   end
# end
```
Notice, placeholder `%a` represents method name. Also, `set_type_casting` method generates lenient date type. See [Lenient Data Types](https://github.com/applift/fast_attributes/blob/lenient_data_types/README.md#lenient-data-types) section.

If you need to conrol the whole type casting process, you can use the following DSL:
```ruby
FastAttributes.type_cast String do     # begin
                                       #   case String
  from 'nil',    to: 'nil'             #   when nil    then nil
  from 'String', to: '%s'              #   when String then %s
  otherwise 'String(%s)'               #   else String(%s)
                                       #   end
  on_error 'TypeError', act: 'nil'     # rescue TypeError => e
                                       #   nil
  on_error 'StandardError', act: '""'  # rescue StandardError => e
                                       #   ""
end                                    # end
```

## Lenient Data Types
It's also possible to define a lenient data type which doesn't correspond to any of ruby classes:
```ruby
FastAttributes.type_cast :yes_no do
  from '"yes"', to: 'true'
  from '"no"',  to: 'false'
  otherwise 'nil'
end

class Order
  extend FastAttributes

  attribute :terms_of_service, :yes_no
end

order = Order.new
order.terms_of_service = 'yes'
order.terms_of_service
# => true
order.terms_of_service = 'no'
order.terms_of_service
# => false
order.terms_of_service = 42
order.terms_of_service
# => nil
```

All default data types have lenient notation:
```ruby
class Book
  extend FastAttributes

  attribute :title,     :string
  attribute :pages,     :integer
  attribute :price,     :big_decimal
  attribute :authors,   :array
  attribute :published, :date
  attribute :sold,      :time
  attribute :finished,  :date_time
  attribute :rate,      :float
  attribute :active,    :boolean
end
```
Notice, `Boolean` attribute can be defined only via symbol, `fast_attribute` doesn't create `Boolean` class.

## Extensions
* [fast_attributes-uuid](https://github.com/applift/fast_attributes-uuid) - adds support of `UUID` to `fast_attributes`

## Contributing

1. Fork it ( http://github.com/applift/fast_attributes/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
