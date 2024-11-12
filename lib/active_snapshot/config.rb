module ActiveSnapshot
  class Config
    def initialize
    end

    def storage_method
      if @storage_method.nil?
        if ActiveSnapshot::SnapshotItem.table_exists? && ActiveSnapshot::SnapshotItem.type_for_attribute(:object).type == :text
          # for legacy active_snapshot configurations only
          self.storage_method = 'serialized_json'
        else
          self.storage_method = 'native_json'
        end
      end

      @storage_method
    end

    def storage_method=(value)
      # for legacy active_snapshot configurations only

      value_str = value.to_s

      if ['serialized_yaml', 'serialized_json', 'native_json'].include?(value_str)
        @storage_method = value_str
      else
        raise ArgumentError.new("Invalid storage_method provided")
      end
    end

    def storage_method_yaml?
      # for legacy active_snapshot configurations only
      storage_method == 'serialized_yaml'
    end

    def storage_method_serialized_json?
      # for legacy active_snapshot configurations only
      storage_method == 'serialized_json'
    end
    alias_method :storage_method_json?, :storage_method_serialized_json?

  end
end
