class ActiveSnapshot::Config
  class << self
    attr_reader :storage_method
  end

  def self.setup(&block)
    self.storage_method = :yaml
    instance_eval(&block) if block_given?
  end

  def self.storage_method=(value)
    if [:yaml, :json].include?(value)
      @storage_method = value
    end
  end

  def self.storage_method_yaml?
    @storage_method == :yaml
  end

  def self.storage_method_json?
    @storage_method == :json
  end
end

ActiveSnapshot::Config.setup
