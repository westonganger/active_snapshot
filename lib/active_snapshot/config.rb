# frozen_string_literal: true

module ActiveSnapshot
  class Config
    class InvalidStorageMethodError < StandardError
      def initialize(value)
        super("Invalid storage_method provided: `#{value}`. Valid options are: #{STORAGE_METHODS.join(', ')}")
      end
    end

    SERIALIZED_YAML = 'serialized_yaml'
    SERIALIZED_JSON = 'serialized_json'
    NATIVE_JSON = 'native_json'

    STORAGE_METHODS = [SERIALIZED_YAML, SERIALIZED_JSON, NATIVE_JSON].freeze
    private_constant :STORAGE_METHODS

    attr_reader :storage_method

    def initialize
      self.storage_method = SERIALIZED_JSON
    end

    def storage_method=(raw_value)
      value = raw_value.to_s

      raise InvalidStorageMethodError, value unless STORAGE_METHODS.include?(value)

      @storage_method = value
    end

    def storage_method_yaml?
      storage_method?(SERIALIZED_YAML)
    end

    def storage_method_json?
      storage_method?(SERIALIZED_JSON)
    end

    def storage_method_native_json?
      storage_method?(NATIVE_JSON)
    end

    private

    def storage_method?(method)
      storage_method == method
    end
  end
end
