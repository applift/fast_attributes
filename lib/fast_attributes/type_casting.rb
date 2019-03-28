module FastAttributes
  # Store a type casting definitions
  #
  class TypeCasting < Hash
    ARRAY_KEY = :collection_array
    SET_KEY = :collection_set

    def [](key)
      symbol = normalize_klass_for_type_name(key)
      super(key) || super(symbol)
    end

    def delete(key)
      symbol = normalize_klass_for_type_name(key)
      super(key)
      super(symbol)
    end

    def key?(key)
      symbol = normalize_klass_for_type_name(key)
      super(key) || super(symbol)
    end

    def store(key, value)
      symbol = normalize_klass_for_type_name(key)
      self[key] = value
      self[symbol] = value
    end

    protected

    # DateTime => :date_time
    #
    def normalize_klass_for_type_name(klass)
      case klass
      when Symbol then klass
      when Array then ARRAY_KEY
      when Set then SET_KEY
      when String then underscore(klass)
      else
        underscore(klass.name)
      end
    end

    def underscore(value)
      value.to_s.gsub(/([a-z])([A-Z])/, '\1_\2').downcase.to_sym
    end
  end
end
