require "test_helper"

class ConfigTest < ActiveSupport::TestCase
    
    def setup
        @configured_storage_method = ActiveSnapshot::Config.storage_method
        ActiveSnapshot::Config.setup
    end

    def test_defaults_to_yaml
        assert_equal ActiveSnapshot::Config.storage_method, 'yaml'
        assert_equal ActiveSnapshot::Config.storage_method_yaml?, true
        assert_equal ActiveSnapshot::Config.storage_method_json?, false
    end

    def test_accepts_json_config_via_string
        ActiveSnapshot::Config.storage_method = 'json'

        assert_equal ActiveSnapshot::Config.storage_method, 'json'
        assert_equal ActiveSnapshot::Config.storage_method_json?, true
        assert_equal ActiveSnapshot::Config.storage_method_yaml?, false
    end
    
    def test_accepts_json_config_via_symbol
        ActiveSnapshot::Config.storage_method = :json

        assert_equal ActiveSnapshot::Config.storage_method, 'json'
        assert_equal ActiveSnapshot::Config.storage_method_json?, true
        assert_equal ActiveSnapshot::Config.storage_method_yaml?, false
    end

    def test_accepts_yaml_config_via_string
        switch_storage_method_to_json
        ActiveSnapshot::Config.storage_method = 'yaml'

        assert_equal ActiveSnapshot::Config.storage_method, 'yaml'
        assert_equal ActiveSnapshot::Config.storage_method_yaml?, true
        assert_equal ActiveSnapshot::Config.storage_method_json?, false
    end

    def test_accepts_yaml_config_via_symbol
        switch_storage_method_to_json
        ActiveSnapshot::Config.storage_method = :yaml

        assert_equal ActiveSnapshot::Config.storage_method, 'yaml'
        assert_equal ActiveSnapshot::Config.storage_method_yaml?, true
        assert_equal ActiveSnapshot::Config.storage_method_json?, false
    end

    def test_config_doesnt_accept_not_specified_storage_methods
        ActiveSnapshot::Config.storage_method = 'anything'
        ActiveSnapshot::Config.storage_method = 'jsoon'
        
        assert_equal ActiveSnapshot::Config.storage_method, 'yaml'
        assert_equal ActiveSnapshot::Config.storage_method_yaml?, true
    end

    def teardown
        ActiveSnapshot::Config.storage_method = @configured_storage_method
    end

    private

    def switch_storage_method_to_json
        ActiveSnapshot::Config.storage_method = 'json'
    end
end
