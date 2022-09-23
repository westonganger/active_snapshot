module ActiveSnapshot
  class Config
    attr_reader :storage_method

    def initialize
      @storage_method = 'serialized_json'
    end

    def storage_method=(value)
      value_str = value.to_s

      if ['serialized_yaml', 'serialized_json', 'native_json'].include?(value_str)
        @storage_method = value_str
      else
        raise ArgumentError.new("Invalid storage_method provided")
      end
    end

    def storage_method_yaml?
      @storage_method == 'serialized_yaml'
    end

    def storage_method_json?
      @storage_method == 'serialized_json'
    end

    def storage_method_native_json?
      @storage_method == 'native_json'
    end
  end
end
