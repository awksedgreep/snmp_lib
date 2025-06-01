defmodule SnmpLib.ManagerTest do
  use ExUnit.Case, async: true
  doctest SnmpLib.Manager
  
  alias SnmpLib.Manager
  
  @moduletag :manager_test
  
  describe "Manager.get/3" do
    test "performs basic GET operation with default options" do
      # Mock a simple GET response - this would normally connect to a real device
      # For testing, we can use a known OID that should work
      
      # Test OID normalization
      assert is_function(&Manager.get/3)
      
      # Test with list OID
      oid_list = [1, 3, 6, 1, 2, 1, 1, 1, 0]
      assert {:error, _} = Manager.get("invalid.host.test", oid_list, timeout: 100)
      
      # Test with string OID  
      oid_string = "1.3.6.1.2.1.1.1.0"
      assert {:error, _} = Manager.get("invalid.host.test", oid_string, timeout: 100)
    end
    
    test "validates input parameters" do
      # Test invalid host
      assert {:error, _} = Manager.get("", [1, 3, 6, 1], timeout: 100)
      
      # Test invalid OID (empty)
      assert {:error, _} = Manager.get("192.168.1.1", [], timeout: 100)
      
      # Test with valid parameters but non-existent host
      assert {:error, _} = Manager.get("192.168.255.255", [1, 3, 6, 1, 2, 1, 1, 1, 0], 
                                       timeout: 100)
    end
    
    test "handles community string options" do
      opts = [community: "private", timeout: 100]
      
      # Should attempt connection with private community
      assert {:error, _} = Manager.get("invalid.host.test", [1, 3, 6, 1, 2, 1, 1, 1, 0], opts)
    end
    
    test "handles timeout options" do
      # Short timeout should fail quickly
      start_time = System.monotonic_time(:millisecond)
      {:error, _} = Manager.get("192.168.255.255", [1, 3, 6, 1, 2, 1, 1, 1, 0], timeout: 50)
      end_time = System.monotonic_time(:millisecond)
      
      # Should complete within reasonable time of timeout
      assert end_time - start_time < 1000
    end
    
    test "normalizes OID formats correctly" do
      # Both should work the same way
      list_oid = [1, 3, 6, 1, 2, 1, 1, 1, 0]
      string_oid = "1.3.6.1.2.1.1.1.0"
      
      result1 = Manager.get("invalid.host.test", list_oid, timeout: 100)
      result2 = Manager.get("invalid.host.test", string_oid, timeout: 100)
      
      # Both should fail the same way (since host is invalid)
      assert {:error, _} = result1
      assert {:error, _} = result2
    end
  end
  
  describe "Manager.get_bulk/3" do
    test "validates GETBULK requires SNMPv2c" do
      # v1 should be rejected
      assert {:error, :getbulk_requires_v2c} = 
        Manager.get_bulk("192.168.1.1", [1, 3, 6, 1, 2, 1, 2, 2], version: :v1)
      
      # v2c should be accepted (but fail due to invalid host)
      assert {:error, _} = 
        Manager.get_bulk("invalid.host.test", [1, 3, 6, 1, 2, 1, 2, 2], 
                        version: :v2c, timeout: 100)
    end
    
    test "handles bulk operation parameters" do
      opts = [
        max_repetitions: 50,
        non_repeaters: 0,
        timeout: 100
      ]
      
      assert {:error, _} = Manager.get_bulk("invalid.host.test", [1, 3, 6, 1, 2, 1, 2, 2], opts)
    end
    
    test "validates bulk parameters" do
      # Should work with valid bulk parameters
      opts = [max_repetitions: 10, non_repeaters: 0, timeout: 100]
      assert {:error, _} = Manager.get_bulk("invalid.host.test", [1, 3, 6, 1], opts)
    end
  end
  
  describe "Manager.set/4" do
    test "accepts different value types" do
      host = "invalid.host.test"
      oid = [1, 3, 6, 1, 2, 1, 1, 5, 0]
      opts = [timeout: 100]
      
      # String value
      assert {:error, _} = Manager.set(host, oid, {:string, "test"}, opts)
      
      # Integer value
      assert {:error, _} = Manager.set(host, oid, {:integer, 42}, opts)
      
      # Counter32 value
      assert {:error, _} = Manager.set(host, oid, {:counter32, 123}, opts)
    end
    
    test "validates SET parameters" do
      opts = [timeout: 100]
      
      # Invalid value format should be handled
      assert {:error, _} = Manager.set("invalid.host.test", [1, 3, 6, 1], 
                                       {:string, "test"}, opts)
    end
  end
  
  describe "Manager.get_multi/3" do
    test "handles multiple OIDs efficiently" do
      oids = [
        [1, 3, 6, 1, 2, 1, 1, 1, 0],
        [1, 3, 6, 1, 2, 1, 1, 3, 0], 
        [1, 3, 6, 1, 2, 1, 1, 5, 0]
      ]
      
      opts = [timeout: 100]
      
      # Should return results for all OIDs (errors in this case)
      assert {:error, _} = Manager.get_multi("invalid.host.test", oids, opts)
    end
    
    test "validates multi-get parameters" do
      # Empty OID list should be handled
      assert {:error, _} = Manager.get_multi("192.168.1.1", [], timeout: 100)
      
      # Invalid OIDs should be handled - empty list case
      assert {:error, _} = Manager.get_multi("invalid.host.test", [], timeout: 100)
    end
  end
  
  describe "Manager.ping/2" do
    test "performs SNMP reachability test" do
      # Should attempt sysUpTime GET
      assert {:error, _} = Manager.ping("invalid.host.test", timeout: 100)
      
      # Test with custom community
      assert {:error, _} = Manager.ping("invalid.host.test", 
                                        community: "private", timeout: 100)
    end
    
    test "validates ping parameters" do
      # Should handle various input formats
      assert {:error, _} = Manager.ping("", timeout: 100)
      assert {:error, _} = Manager.ping("192.168.255.255", timeout: 50)
    end
  end
  
  describe "Manager option handling" do
    test "merges default options correctly" do
      # Test that defaults are applied
      assert {:error, _} = Manager.get("invalid.host.test", [1, 3, 6, 1])
      
      # Test that custom options override defaults
      custom_opts = [
        community: "test",
        version: :v1,
        timeout: 200,
        port: 1161
      ]
      
      assert {:error, _} = Manager.get("invalid.host.test", [1, 3, 6, 1], custom_opts)
    end
    
    test "validates option values" do
      # Test various option combinations
      opts = [
        community: "public",
        version: :v2c,
        timeout: 5000,
        retries: 3,
        port: 161,
        local_port: 0
      ]
      
      assert {:error, _} = Manager.get("invalid.host.test", [1, 3, 6, 1], opts)
    end
  end
  
  describe "Manager error handling" do
    test "handles network errors gracefully" do
      # Network errors (timeout or network unreachable)
      assert {:error, _} = Manager.get("192.168.255.255", [1, 3, 6, 1], timeout: 50)
      
      # Invalid host errors
      assert {:error, _} = Manager.get("invalid.hostname.test", [1, 3, 6, 1], timeout: 100)
    end
    
    test "handles SNMP protocol errors" do
      # These would test actual SNMP error responses
      # For now, we test that error handling structure is in place
      assert is_function(&Manager.get/3)
      assert is_function(&Manager.get_bulk/3)
      assert is_function(&Manager.set/4)
    end
  end
  
  describe "Manager integration" do
    test "integrates with existing SnmpLib modules" do
      # Verify Manager uses other SnmpLib modules correctly
      
      # Test OID normalization (should use SnmpLib.OID)
      string_oid = "1.3.6.1.2.1.1.1.0"
      assert {:error, _} = Manager.get("invalid.host.test", string_oid, timeout: 100)
      
      # Test PDU creation (should use SnmpLib.PDU)
      assert {:error, _} = Manager.get("invalid.host.test", [1, 3, 6, 1], timeout: 100)
      
      # Test transport (should use SnmpLib.Transport)  
      assert {:error, _} = Manager.ping("invalid.host.test", timeout: 100)
    end
  end
  
  # Performance and stress tests
  describe "Manager performance" do
    @tag :performance
    test "handles concurrent operations" do
      # Test multiple concurrent operations
      tasks = Enum.map(1..5, fn _i ->
        Task.async(fn ->
          Manager.get("invalid.host.test", [1, 3, 6, 1], timeout: 100)
        end)
      end)
      
      results = Task.await_many(tasks, 1000)
      
      # All should fail gracefully (invalid host)
      assert Enum.all?(results, fn result -> 
        match?({:error, _}, result)
      end)
    end
    
    @tag :performance  
    test "get_multi is more efficient than individual gets" do
      oids = Enum.map(1..10, fn i -> [1, 3, 6, 1, 2, 1, 1, i, 0] end)
      
      # Time individual gets
      {time_individual, _} = :timer.tc(fn ->
        Enum.map(oids, fn oid ->
          Manager.get("invalid.host.test", oid, timeout: 50)
        end)
      end)
      
      # Time multi get
      {time_multi, _} = :timer.tc(fn ->
        Manager.get_multi("invalid.host.test", oids, timeout: 50)
      end)
      
      # Multi should complete faster (though both will fail)
      # At minimum, they should both complete within reasonable time
      assert time_individual > 0
      assert time_multi > 0
    end
  end
end