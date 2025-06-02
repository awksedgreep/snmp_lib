defmodule SnmpLib.AdvancedTypesTest do
  use ExUnit.Case, async: true
  
  alias SnmpLib.PDU
  
  describe "Counter32 encoding/decoding" do
    test "encodes and decodes basic counter32 values" do
      test_cases = [
        0,
        1,
        42,
        65535,
        1000000,
        4294967295  # Max 32-bit unsigned value
      ]
      
      Enum.each(test_cases, fn value ->
        # Test with explicit tuple format
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, {:counter32, value}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        assert decoded_value == {:counter32, value}, "Counter32 #{value} failed round-trip"
      end)
    end
    
    test "handles counter32 boundary values" do
      # Test edge cases
      boundary_values = [
        {0, "minimum value"},
        {2147483647, "max signed 32-bit"},
        {2147483648, "min unsigned above signed max"},
        {4294967295, "maximum 32-bit unsigned"}
      ]
      
      Enum.each(boundary_values, fn {value, description} ->
        varbinds = [{[1, 3, 6, 1], :auto, {:counter32, value}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        assert decoded_value == {:counter32, value}, "Counter32 #{description} (#{value}) failed"
      end)
    end
    
    test "rejects invalid counter32 values" do
      invalid_values = [
        -1,
        4294967296,  # Exceeds 32-bit
        "not_a_number"
      ]
      
      Enum.each(invalid_values, fn value ->
        varbinds = [{[1, 3, 6, 1], :auto, {:counter32, value}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        # Should fall back to :null for invalid values
        assert decoded_value == :null, "Invalid counter32 #{inspect(value)} should become :null"
      end)
    end
  end
  
  describe "Gauge32 encoding/decoding" do
    test "encodes and decodes basic gauge32 values" do
      test_cases = [
        0,
        50,
        100,
        65535,
        1048576,
        4294967295  # Max 32-bit unsigned value
      ]
      
      Enum.each(test_cases, fn value ->
        varbinds = [{[1, 3, 6, 1, 2, 1, 2, 2, 1, 10, 1], :auto, {:gauge32, value}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        assert decoded_value == {:gauge32, value}, "Gauge32 #{value} failed round-trip"
      end)
    end
    
    test "handles gauge32 with typical network values" do
      # Typical values for interface speeds, utilization, etc.
      network_values = [
        {0, "interface down"},
        {10000000, "10 Mbps"},
        {100000000, "100 Mbps"},
        {1000000000, "1 Gbps"},
        {10000000000, "10 Gbps - this will exceed 32-bit and should be handled gracefully"}
      ]
      
      Enum.each(network_values, fn {value, description} ->
        varbinds = [{[1, 3, 6, 1, 2, 1, 2, 2, 1, 5, 1], :auto, {:gauge32, value}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        
        if value <= 4294967295 do
          assert decoded_value == {:gauge32, value}, "Gauge32 #{description} (#{value}) failed"
        else
          # Values exceeding 32-bit should gracefully degrade
          assert decoded_value == :null, "Gauge32 #{description} (#{value}) should become :null"
        end
      end)
    end
  end
  
  describe "TimeTicks encoding/decoding" do
    test "encodes and decodes basic timeticks values" do
      test_cases = [
        {0, "system just started"},
        {100, "1 second (hundredths)"},
        {6000, "1 minute"},
        {360000, "1 hour"},
        {8640000, "1 day"},
        {4294967295, "maximum timeticks value"}
      ]
      
      Enum.each(test_cases, fn {value, description} ->
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 3, 0], :auto, {:timeticks, value}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        assert decoded_value == {:timeticks, value}, "TimeTicks #{description} (#{value}) failed"
      end)
    end
    
    test "handles timeticks rollover scenarios" do
      # TimeTicks rollover every ~497 days (2^32 / 100 / 86400)
      rollover_values = [
        4294967200,  # Close to rollover
        4294967295,  # Maximum value
        0            # After rollover (back to 0)
      ]
      
      Enum.each(rollover_values, fn value ->
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 3, 0], :auto, {:timeticks, value}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        assert decoded_value == {:timeticks, value}, "TimeTicks rollover value #{value} failed"
      end)
    end
  end
  
  describe "Counter64 encoding/decoding" do
    test "encodes and decodes basic counter64 values" do
      test_cases = [
        {0, "minimum value"},
        {42, "small value"},
        {4294967296, "exceeds 32-bit"},
        {1000000000000, "1 trillion"},
        {18446744073709551615, "maximum 64-bit unsigned"}
      ]
      
      Enum.each(test_cases, fn {value, description} ->
        varbinds = [{[1, 3, 6, 1, 2, 1, 2, 2, 1, 10, 1], :auto, {:counter64, value}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        assert decoded_value == {:counter64, value}, "Counter64 #{description} (#{value}) failed"
      end)
    end
    
    test "handles high-speed interface counters" do
      # Typical high-speed interface byte counters
      interface_counters = [
        {1000000000000, "1 TB transferred"},
        {5000000000000, "5 TB transferred"},
        {10000000000000, "10 TB transferred"},
        {100000000000000, "100 TB transferred"}
      ]
      
      Enum.each(interface_counters, fn {value, description} ->
        varbinds = [{[1, 3, 6, 1, 2, 1, 2, 2, 1, 10, 1], :auto, {:counter64, value}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        assert decoded_value == {:counter64, value}, "Counter64 #{description} (#{value}) failed"
      end)
    end
    
    test "rejects invalid counter64 values" do
      invalid_values = [
        -1,
        "not_a_number",
        18446744073709551616  # Exceeds 64-bit (if supported by platform)
      ]
      
      Enum.each(invalid_values, fn value ->
        varbinds = [{[1, 3, 6, 1], :auto, {:counter64, value}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        # Should fall back to :null for invalid values
        assert decoded_value == :null, "Invalid counter64 #{inspect(value)} should become :null"
      end)
    end
  end
  
  describe "IP Address encoding/decoding" do
    test "encodes and decodes standard IPv4 addresses" do
      ip_addresses = [
        {<<0, 0, 0, 0>>, "0.0.0.0 (any address)"},
        {<<127, 0, 0, 1>>, "127.0.0.1 (loopback)"},
        {<<192, 168, 1, 1>>, "192.168.1.1 (private)"},
        {<<10, 0, 0, 1>>, "10.0.0.1 (private)"},
        {<<172, 16, 0, 1>>, "172.16.0.1 (private)"},
        {<<8, 8, 8, 8>>, "8.8.8.8 (Google DNS)"},
        {<<255, 255, 255, 255>>, "255.255.255.255 (broadcast)"}
      ]
      
      Enum.each(ip_addresses, fn {ip_binary, description} ->
        varbinds = [{[1, 3, 6, 1, 2, 1, 4, 20, 1, 1, 1], :auto, {:ip_address, ip_binary}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        assert decoded_value == {:ip_address, ip_binary}, "IP Address #{description} failed"
      end)
    end
    
    test "handles edge case IP addresses" do
      edge_cases = [
        {<<0, 0, 0, 1>>, "first usable address"},
        {<<169, 254, 1, 1>>, "link-local"},
        {<<224, 0, 0, 1>>, "multicast"},
        {<<239, 255, 255, 255>>, "last multicast"}
      ]
      
      Enum.each(edge_cases, fn {ip_binary, description} ->
        varbinds = [{[1, 3, 6, 1, 2, 1, 4, 20, 1, 1, 2], :auto, {:ip_address, ip_binary}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        assert decoded_value == {:ip_address, ip_binary}, "IP Address #{description} failed"
      end)
    end
    
    test "rejects invalid IP address formats" do
      invalid_ips = [
        <<192, 168, 1>>,      # Too short (3 bytes)
        <<192, 168, 1, 1, 0>>, # Too long (5 bytes)
        "192.168.1.1",       # String instead of binary
        <<>>                  # Empty binary
      ]
      
      Enum.each(invalid_ips, fn invalid_ip ->
        varbinds = [{[1, 3, 6, 1], :auto, {:ip_address, invalid_ip}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        # Should fall back to :null for invalid IP formats
        assert decoded_value == :null, "Invalid IP #{inspect(invalid_ip)} should become :null"
      end)
    end
  end
  
  describe "Opaque type encoding/decoding" do
    test "encodes and decodes basic opaque data" do
      opaque_data = [
        {<<>>, "empty data"},
        {<<0>>, "single null byte"},
        {<<1, 2, 3, 4>>, "simple byte sequence"},
        {<<255, 254, 253, 252>>, "high byte values"},
        {:crypto.strong_rand_bytes(16), "random 16 bytes"},
        {:crypto.strong_rand_bytes(64), "random 64 bytes"},
        {"Hello, SNMP!", "text data"}
      ]
      
      Enum.each(opaque_data, fn {data_binary, description} ->
        # Convert string to binary if needed
        binary_data = if is_binary(data_binary), do: data_binary, else: data_binary
        
        varbinds = [{[1, 3, 6, 1, 4, 1, 9999, 1, 1, 0], :auto, {:opaque, binary_data}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        assert decoded_value == {:opaque, binary_data}, "Opaque #{description} failed"
      end)
    end
    
    test "handles large opaque payloads" do
      # Test various sizes up to reasonable SNMP limits
      size_tests = [
        100,
        500,
        1000,
        1500  # Approaching typical MTU limits
      ]
      
      Enum.each(size_tests, fn size ->
        large_data = :crypto.strong_rand_bytes(size)
        
        varbinds = [{[1, 3, 6, 1, 4, 1, 9999, 2, 1, 0], :auto, {:opaque, large_data}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        assert decoded_value == {:opaque, large_data}, "Opaque data of size #{size} failed"
        assert byte_size(elem(decoded_value, 1)) == size, "Size mismatch for #{size} byte opaque data"
      end)
    end
    
    test "handles special binary patterns" do
      special_patterns = [
        {<<0, 0, 0, 0>>, "all zeros"},
        {<<255, 255, 255, 255>>, "all ones"},
        {<<170, 85, 170, 85>>, "alternating pattern"},
        {<<1, 2, 4, 8, 16, 32, 64, 128>>, "powers of 2"},
        {"\x00\x01\x02\x03\xFF\xFE\xFD\xFC", "mixed control chars"}
      ]
      
      Enum.each(special_patterns, fn {pattern, description} ->
        varbinds = [{[1, 3, 6, 1, 4, 1, 9999, 3, 1, 0], :auto, {:opaque, pattern}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        assert decoded_value == {:opaque, pattern}, "Opaque #{description} failed"
      end)
    end
  end
end