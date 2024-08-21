require "test_helper"

class ActiveSnapshot::ConfigTest < ActiveSupport::TestCase

  describe "storage_method" do
    def setup
      @orig_storage_method = ActiveSnapshot.config.storage_method
    end

    def teardown
      ActiveSnapshot.config.storage_method = @orig_storage_method
    end

    def test_defaults_to_serialized_json
      if ENV["ACTIVE_SNAPSHOT_STORAGE_METHOD"].present?
        skip
      end

      assert_equal 'serialized_json', ActiveSnapshot.config.storage_method

      assert_equal false, ActiveSnapshot.config.storage_method_yaml?
      assert_equal true, ActiveSnapshot.config.storage_method_json?
      assert_equal false, ActiveSnapshot.config.storage_method_native_json?
    end

    def test_accepts_to_serialized_json
      ActiveSnapshot.config.storage_method = 'serialized_json'

      assert_equal 'serialized_json', ActiveSnapshot.config.storage_method

      assert_equal false, ActiveSnapshot.config.storage_method_yaml?
      assert_equal true, ActiveSnapshot.config.storage_method_json?
      assert_equal false, ActiveSnapshot.config.storage_method_native_json?
    end


    def test_accepts_serialized_yaml
      ActiveSnapshot.config.storage_method = 'serialized_yaml'

      assert_equal 'serialized_yaml', ActiveSnapshot.config.storage_method

      assert_equal true, ActiveSnapshot.config.storage_method_yaml?
      assert_equal false, ActiveSnapshot.config.storage_method_json?
      assert_equal false, ActiveSnapshot.config.storage_method_native_json?
    end

    def test_accepts_native_json
      ActiveSnapshot.config.storage_method = "native_json"

      assert_equal "native_json", ActiveSnapshot.config.storage_method, "native_json"

      assert_equal false, ActiveSnapshot.config.storage_method_yaml?
      assert_equal false, ActiveSnapshot.config.storage_method_json?
      assert_equal true, ActiveSnapshot.config.storage_method_native_json?
    end

    def test_config_doesnt_accept_not_specified_storage_methods
      assert ActiveSnapshot.config.storage_method.present?
      assert_raise do
        ActiveSnapshot.config.storage_method = "foobar"
      end
      refute_equal "foobar", ActiveSnapshot.config.storage_method
    end

    def test_converts_symbol_to_string
      ActiveSnapshot.config.storage_method = "serialized_yaml"
      assert_equal "serialized_yaml", ActiveSnapshot.config.storage_method
    end
  end

end
