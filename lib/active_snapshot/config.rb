class ActiveSnapshot::Config
  class << self
    attr_accessor :storage_method
  end

  def self.setup(&block)
    @storage_method = :yaml
    instance_eval(&block) if block_given?
  end

  def self.storage_method_yaml?
    @storage_method == :yaml
  end

  def self.storage_method_json?
    @storage_method == :json
  end
end

ActiveSnapshot::Config.setup
