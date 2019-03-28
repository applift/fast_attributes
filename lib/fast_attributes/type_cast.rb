module FastAttributes
  class TypeCast
    class UnknownTypeCastingError < StandardError
    end

    class InvalidValueError < TypeError
    end

    def initialize(type)
      @type              = type
      @if_conditions     = []
      @else_condition    = %q(raise FastAttributes::TypeCast::UnknownTypeCastingError, 'Type casting is not defined')
      @rescue_conditions = nil
      @default_rescue    = %(raise FastAttributes::TypeCast::InvalidValueError, %(Invalid value "\#{%s}" for attribute "%a" of type "#{@type}"))
    end

    class << self
      def escape_template(template, attribute_name, argument_name)
        template.gsub(/%+a|%+s/) do |match|
          match.each_char.each_slice(2).map do |placeholder|
            case placeholder
              when %w[% a] then attribute_name
              when %w[% s] then argument_name
              when %w[% %] then '%'
              else placeholder.join
            end
          end.join
        end
      end
    end

    def from(condition, options = {})
      @if_conditions << [condition, options[:to]]
    end

    def otherwise(else_condition)
      @else_condition = else_condition
    end

    def on_error(error, options = {})
      @rescue_conditions ||=[]
      @rescue_conditions << [error, options[:act]]
    end

    def type_casting_template
      @type_casting_template ||= begin
        if @if_conditions.any?
          conditions = @if_conditions.map do |from, to|
            "when #{from}\n" +
            "  #{to}\n"
          end

          "case %s\n" +
          conditions.join +
          "else\n" +
          "  #{@else_condition}\n" +
          "end"
        else
          @else_condition
        end
      end
    end

    def rescue_template
      rescues = @rescue_conditions || [['', @default_rescue]]
      rescues.map do |error, action|
        "rescue #{error} => e\n" +
        "  #{action}"
      end.join("\n")
    end

    def compile_lambda(attribute_name)
      code_string = compile_method_body(attribute_name, 'value')
      eval "lambda { |value| #{code_string} }"
    end

    def compile_method_body(attribute_name, argument_name)
      method_body = "begin\n" +
                    "  #{type_casting_template}\n" +
                    "#{rescue_template}\n" +
                    "end"

      self.class.escape_template(method_body, attribute_name, argument_name)
    end
  end
end
