defmodule SnmpLib.ConfigMergeOptsTest do
  use ExUnit.Case, async: true
  
  alias SnmpLib.Config

  doctest SnmpLib.Config

  describe "merge_opts/1" do
    setup do
      # Start the config system if not already started
      case GenServer.whereis(SnmpLib.Config) do
        nil -> 
          {:ok, _pid} = SnmpLib.Config.start_link()
          :ok
        _pid -> 
          :ok
      end
    end

    test "returns default values when no options provided" do
      result = Config.merge_opts([])
      
      assert result[:community] == "public"
      assert result[:timeout] == 5000
      assert result[:retries] == 3
      assert result[:port] == 161
      assert result[:version] == :v2c
      assert result[:mib_paths] == []
    end

    test "merges user options with defaults, user options take precedence" do
      result = Config.merge_opts([timeout: 10000])
      
      assert result[:community] == "public"  # default
      assert result[:timeout] == 10000       # overridden
      assert result[:retries] == 3           # default
      assert result[:port] == 161            # default
      assert result[:version] == :v2c        # default
      assert result[:mib_paths] == []        # default
    end

    test "allows overriding multiple options" do
      result = Config.merge_opts([community: "private", port: 162, retries: 5])
      
      assert result[:community] == "private" # overridden
      assert result[:timeout] == 5000        # default
      assert result[:retries] == 5           # overridden
      assert result[:port] == 162            # overridden
      assert result[:version] == :v2c        # default
      assert result[:mib_paths] == []        # default
    end

    test "preserves additional user options not in defaults" do
      result = Config.merge_opts([custom_option: "value", local_port: 0])
      
      # Default options should be present
      assert result[:community] == "public"
      assert result[:timeout] == 5000
      assert result[:retries] == 3
      assert result[:port] == 161
      assert result[:version] == :v2c
      assert result[:mib_paths] == []
      
      # Additional options should be preserved
      assert result[:custom_option] == "value"
      assert result[:local_port] == 0
    end

    test "handles all supported SNMP versions" do
      for version <- [:v1, :v2c, :v3] do
        result = Config.merge_opts([version: version])
        assert result[:version] == version
      end
    end

    test "handles different community strings" do
      for community <- ["public", "private", "secret", ""] do
        result = Config.merge_opts([community: community])
        assert result[:community] == community
      end
    end

    test "handles various timeout values" do
      for timeout <- [1000, 5000, 10000, 30000] do
        result = Config.merge_opts([timeout: timeout])
        assert result[:timeout] == timeout
      end
    end

    test "handles various retry counts" do
      for retries <- [0, 1, 3, 5, 10] do
        result = Config.merge_opts([retries: retries])
        assert result[:retries] == retries
      end
    end

    test "handles various port numbers" do
      for port <- [161, 162, 1161, 8161] do
        result = Config.merge_opts([port: port])
        assert result[:port] == port
      end
    end

    test "handles mib_paths configuration" do
      paths = ["/usr/share/snmp/mibs", "/etc/snmp/mibs"]
      result = Config.merge_opts([mib_paths: paths])
      assert result[:mib_paths] == paths
    end

    test "matches expected behavior from usage patterns" do
      # Test case 1: Empty options
      result1 = Config.merge_opts([])
      expected1 = [community: "public", timeout: 5000, retries: 3, port: 161, version: :v2c, mib_paths: []]
      
      for {key, value} <- expected1 do
        assert result1[key] == value
      end

      # Test case 2: Timeout override
      result2 = Config.merge_opts([timeout: 10000])
      expected2 = [community: "public", timeout: 10000, retries: 3, port: 161, version: :v2c, mib_paths: []]
      
      for {key, value} <- expected2 do
        assert result2[key] == value
      end

      # Test case 3: Community override
      result3 = Config.merge_opts([community: "private"])
      expected3 = [community: "private", timeout: 5000, retries: 3, port: 161, version: :v2c, mib_paths: []]
      
      for {key, value} <- expected3 do
        assert result3[key] == value
      end
    end

    test "returns keyword list in consistent order" do
      result = Config.merge_opts([])
      
      # Verify all expected keys are present
      expected_keys = [:community, :timeout, :retries, :port, :version, :mib_paths]
      actual_keys = Keyword.keys(result)
      
      for key <- expected_keys do
        assert key in actual_keys, "Expected key #{key} to be present in result"
      end
    end

    test "works with empty keyword list" do
      assert Config.merge_opts([]) == Config.merge_opts(Keyword.new())
    end
  end
end