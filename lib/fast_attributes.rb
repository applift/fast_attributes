require 'bigdecimal'
require 'date'
require 'time'
require 'fast_attributes/version'
require 'fast_attributes/builder'
require 'fast_attributes/type_cast'
require 'fast_attributes/type_casting'
require 'fast_attributes/default_attributes'

module FastAttributes
  TRUE_VALUES  = [true, 1, '1', 't', 'T', 'true', 'TRUE', 'on', 'ON'].freeze
  FALSE_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE', 'off', 'OFF'].freeze

  class << self
    def type_casting
      @type_casting ||= FastAttributes::TypeCasting.new
    end

    def get_type_casting(klass)
      type_casting[klass]
    end

    def set_type_casting(klass, casting)
      type_cast klass do
        from 'nil',      to: 'nil'
        from klass.name, to: '%s'
        otherwise casting
      end
    end

    def remove_type_casting(klass)
      type_casting.delete(klass)
    end

    def type_exists?(klass)
      type_casting.key?(klass)
    end

    def type_cast(*types_or_classes, &block)
      types_or_classes.each do |type_or_class|
        type_cast = TypeCast.new(type_or_class)
        type_cast.instance_eval(&block)

        type_casting.store(type_or_class, type_cast)
      end
    end
  end

  def define_attributes(options = {}, &block)
    builder = Builder.new(self, options)
    builder.instance_eval(&block)
    builder.compile!

    attribute_set.merge!(builder.attributes)
  end

  def attribute(*attributes, type)
    builder = Builder.new(self)
    builder.attribute(*attributes, type)
    builder.compile!

    attribute_set.merge!(builder.attributes)
  end

  def attribute_set
    @attribute_set ||= {}
  end

  set_type_casting String,     'String(%s)'
  set_type_casting Integer,    'Integer(%s)'
  set_type_casting Float,      'Float(%s)'
  set_type_casting Array,      'Array(%s)'
  set_type_casting Date,       'Date.parse(%s)'
  set_type_casting Time,       'Time.parse(%s)'
  set_type_casting DateTime,   'DateTime.parse(%s)'
  set_type_casting BigDecimal, 'Float(%s);BigDecimal(%s.to_s)'

  type_cast TypeCasting::ARRAY_KEY do
    from 'nil', to: 'nil'
    otherwise <<-EOS
      type = Array(self.class.attribute_set[:%a][:type])[0]
      type_cast = FastAttributes.get_type_casting(type)

      coercion = type_cast.compile_lambda(:%a)
      Array(%s).map { |item| coercion.call(item) }
    EOS
  end

  type_cast TypeCasting::SET_KEY do
    from 'nil', to: 'nil'
    otherwise <<-EOS
      type = Array(self.class.attribute_set[:%a][:type])[0]
      type_cast = FastAttributes.get_type_casting(type)

      coercion = type_cast.compile_lambda(:%a)
      items = Array(%s).map { |item| coercion.call(item) }
      Set.new(items)
    EOS
  end

  type_cast :boolean do
    otherwise <<-EOS
      if FastAttributes::TRUE_VALUES.include?(%s)
        true
      elsif FastAttributes::FALSE_VALUES.include?(%s)
        false
      elsif %s.nil?
        nil
      else
        raise FastAttributes::TypeCast::InvalidValueError, %(Invalid value "\#{%s}" for attribute "%a" of type ":boolean")
      end
    EOS
  end
end
