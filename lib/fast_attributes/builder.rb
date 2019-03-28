module FastAttributes
  class UnsupportedTypeError < TypeError
  end

  # Build instance methods
  #
  class Builder
    attr_reader :attributes

    def initialize(klass, options = {})
      @klass      = klass
      @options    = options
      @attributes = {}
      @methods    = Module.new
    end

    def attribute(*attributes, type, options)
      unless options.is_a?(Hash)
        (attributes ||= []) << type
        type = options
        options = {}
      end

      ensure_type_exists!(type)

      data = { type: type, options: (options || {}) }

      Array(attributes).each do |attr_name|
        @attributes[attr_name.to_sym] = data
      end
    end

    def compile!
      compile_getter
      compile_setter
      set_defaults

      compile_initialize if @options[:initialize]
      compile_attributes(@options[:attributes]) if @options[:attributes]

      include_methods
    end

    private

    def ensure_type_exists!(type)
      return if FastAttributes.type_exists?(type)
      raise UnsupportedTypeError, "Unsupported attribute type \"#{type.inspect}\""
    end

    def compile_getter
      each_attribute do |attribute, *|
        @methods.module_eval <<-EOS, __FILE__, __LINE__ + 1
          def #{attribute} # def name
            @#{attribute}  #   @name
          end              # end
        EOS
      end
    end

    def compile_setter
      each_attribute do |attribute, type, *|
        type_cast   = FastAttributes.get_type_casting(type)
        method_body = type_cast.compile_method_body(attribute, 'value')

        @methods.module_eval <<-EOS, __FILE__, __LINE__ + 1
          def #{attribute}=(value)
            @#{attribute} = #{method_body}
          end
        EOS
      end
    end

    def compile_initialize
      @methods.module_eval <<-EOS, __FILE__, __LINE__ + 1
        def initialize(attributes = {})
          #{attribute_string}.each do |name, value|
            public_send("\#{name}=", value)
          end
        end
      EOS
    end

    def attribute_string
      if FastAttributes.default_attributes(@klass).empty?
        'attributes'
      else
        'FastAttributes.default_attributes(self.class).merge(attributes)'
      end
    end

    def compile_attributes(mode)
      attributes = @attributes.flat_map(&:first)
      prefix = case mode
               when :accessors then ''
               else '@'
               end

      attributes = attributes.map do |attribute|
        "'#{attribute}' => #{prefix}#{attribute}"
      end

      @methods.module_eval <<-EOS, __FILE__, __LINE__ + 1
        def attributes                # def attributes
          {#{attributes.join(', ')}}  #   {'name' => @name, ...}
        end                           # end
      EOS
    end

    def include_methods
      @methods.instance_eval <<-EOS, __FILE__, __LINE__ + 1
        def inspect
          'FastAttributes(#{@attributes.flat_map(&:first).join(', ')})'
        end
      EOS
      @klass.send(:include, @methods)
    end

    def set_defaults
      each_attribute do |name, _type, options|
        next unless options[:default]
        FastAttributes.add_default_attribute(@klass, name, options[:default])
      end
    end

    def each_attribute
      @attributes.each do |attr_name, data|
        yield attr_name, data[:type], data[:options]
      end
    end
  end
end
