defmodule SnmpLib.AutoTypeEncodingTest do
  use ExUnit.Case, async: true
  
  alias SnmpLib.PDU
  
  describe "Auto type encoding for complex SNMP data types" do
    test "encodes and decodes valid tuple formats with :auto type" do
      # Test valid tuple formats that should work
      valid_tuple_tests = [
        {{:counter32, 12345}, "counter32 tuple"},
        {{:gauge32, 98765}, "gauge32 tuple"},
        {{:timeticks, 123456789}, "timeticks tuple"},
        {{:counter64, 9876543210}, "counter64 tuple"},
        {{:ip_address, <<192, 168, 1, 1>>}, "ip_address tuple"},
        {{:opaque, <<1, 2, 3, 4, 5>>}, "opaque tuple"},
        {{:object_identifier, [1, 3, 6, 1, 2, 1, 1, 1, 0]}, "object_identifier tuple with list"}
      ]
      
      Enum.each(valid_tuple_tests, fn {test_value, description} ->
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, test_value}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, decoded_type, decoded_value} = hd(decoded.pdu.varbinds)
        
        # With the standardized 3-tuple format, the type and value are separate
        {expected_type, expected_value} = case test_value do
          {:counter32, val} -> {:counter32, val}
          {:gauge32, val} -> {:gauge32, val}
          {:timeticks, val} -> {:timeticks, val}
          {:counter64, val} -> {:counter64, val}
          {:ip_address, val} -> {:ip_address, val}
          {:opaque, val} -> {:opaque, val}
          {:object_identifier, oid_list} when is_list(oid_list) ->
            # OIDs are decoded as lists
            {:object_identifier, oid_list}
        end
        
        assert decoded_type == expected_type, 
          "Auto type encoding failed for #{description}: expected type #{inspect(expected_type)}, got #{inspect(decoded_type)}"
        assert decoded_value == expected_value,
          "Auto type encoding failed for #{description}: expected value #{inspect(expected_value)}, got #{inspect(decoded_value)}"
      end)
    end
    
    test "handles valid string OIDs with :auto type" do
      # Test cases that should now succeed due to string OID support
      string_oid_tests = [
        {{:object_identifier, "1.3.6.1.2.1.1.1.0"}, "object_identifier tuple with valid string"}
      ]
      
      Enum.each(string_oid_tests, fn {test_value, description} ->
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, test_value}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        case PDU.encode_message(message) do
          {:ok, encoded} ->
            # Expected behavior - string OIDs should now be supported
            {:ok, decoded} = PDU.decode_message(encoded)
            {_oid, type, value} = hd(decoded.pdu.varbinds)
            assert type == :object_identifier
            assert value == [1, 3, 6, 1, 2, 1, 1, 1, 0]
          {:error, error} ->
            flunk("Expected success for #{description}, but got error: #{inspect(error)}")
        end
      end)
    end
    
    test "handles exception tuples with :auto type" do
      # Test that exception tuples encode successfully (they should NOT raise errors)
      exception_tuple_tests = [
        {{:no_such_object, nil}, "no_such_object exception tuple"},
        {{:no_such_instance, nil}, "no_such_instance exception tuple"},
        {{:end_of_mib_view, nil}, "end_of_mib_view exception tuple"}
      ]
      
      Enum.each(exception_tuple_tests, fn {test_value, description} ->
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, test_value}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        case PDU.encode_message(message) do
          {:ok, _encoded} ->
            # Expected behavior - exception tuples should encode successfully
            :ok
          {:error, reason} ->
            flunk("Expected #{description} to encode successfully, but got error: #{inspect(reason)}")
        end
      end)
    end
    
    test "handles structural errors gracefully with :auto type" do
      # Test invalid tuple formats that now encode as :null instead of raising errors
      # This reflects our design decision for graceful error handling
      graceful_error_tests = [
        {{:object_identifier, []}, "empty OID list"},
        {{:object_identifier, [1]}, "too short OID list"}
      ]
      
      Enum.each(graceful_error_tests, fn {test_value, description} ->
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, test_value}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        case PDU.encode_message(message) do
          {:ok, encoded} ->
            # Expected behavior - invalid formats should encode as :null
            {:ok, decoded} = PDU.decode_message(encoded)
            {_oid, type, value} = hd(decoded.pdu.varbinds)
            assert type == :null
            assert value == :null
          {:error, reason} ->
            flunk("Expected graceful handling for #{description}, but got error: #{inspect(reason)}")
        end
      end)
    end
    
    test "converts invalid values to null with :auto type" do
      # Test invalid values that should be converted to null (value range/type errors)
      null_conversion_tests = [
        {{:counter32, -1}, "negative counter32"},
        {{:counter32, "not_a_number"}, "non-numeric counter32"},
        {{:gauge32, -100}, "negative gauge32"},
        {{:timeticks, "invalid"}, "non-numeric timeticks"},
        {{:counter64, -5}, "negative counter64"},
        {{:ip_address, <<192, 168, 1>>}, "short IP address"},
        {{:ip_address, "192.168.1.1"}, "string IP address"},
        {{:opaque, 12345}, "non-binary opaque"}
      ]
      
      Enum.each(null_conversion_tests, fn {test_value, description} ->
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, test_value}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, decoded_type, decoded_value} = hd(decoded.pdu.varbinds)
        assert decoded_type == :null, "Invalid #{description} should become :null type"
        assert decoded_value == :null, "Invalid #{description} should become :null value"
      end)
    end
    
    test "preserves data integrity across encode/decode cycles for all types" do
      # Test round-trip integrity for valid complex types (no exception tuples)
      test_data = [
        {:counter32, 2147483647},
        {:gauge32, 1000000},
        {:timeticks, 12345678},
        {:counter64, 9223372036854775807},
        {:ip_address, <<10, 0, 0, 1>>},
        {:opaque, :crypto.strong_rand_bytes(32)},
        {:object_identifier, [1, 3, 6, 1, 4, 1, 2021, 1, 1, 1, 0]}
      ]
      
      Enum.each(test_data, fn test_value ->
        # Test multiple encode/decode cycles
        original = test_value
        
        # Cycle 1
        varbinds1 = [{[1, 3, 6, 1], :auto, original}]
        pdu1 = PDU.build_response(1, 0, 0, varbinds1)
        message1 = PDU.build_message(pdu1, "public", :v2c)
        
        {:ok, encoded1} = PDU.encode_message(message1)
        {:ok, decoded1} = PDU.decode_message(encoded1)
        {_, type1, value1} = hd(decoded1.pdu.varbinds)
        
        # Cycle 2 - use the decoded type and value
        varbinds2 = [{[1, 3, 6, 1], type1, value1}]
        pdu2 = PDU.build_response(2, 0, 0, varbinds2)
        message2 = PDU.build_message(pdu2, "public", :v2c)
        
        {:ok, encoded2} = PDU.encode_message(message2)
        {:ok, decoded2} = PDU.decode_message(encoded2)
        {_, type2, value2} = hd(decoded2.pdu.varbinds)
        
        # Cycle 3 - use the decoded type and value
        varbinds3 = [{[1, 3, 6, 1], type2, value2}]
        pdu3 = PDU.build_response(3, 0, 0, varbinds3)
        message3 = PDU.build_message(pdu3, "public", :v2c)
        
        {:ok, encoded3} = PDU.encode_message(message3)
        {:ok, decoded3} = PDU.decode_message(encoded3)
        {_, type3, value3} = hd(decoded3.pdu.varbinds)
        
        # Extract expected type and value from original tuple
        {expected_type, expected_value} = original
        
        # For object_identifier, lists are preserved
        # No need to convert to string format anymore
        
        assert type1 == expected_type, "First cycle type failed for #{inspect(original)}"
        assert value1 == expected_value, "First cycle value failed for #{inspect(original)}"
        assert type2 == expected_type, "Second cycle type failed for #{inspect(original)}"
        assert value2 == expected_value, "Second cycle value failed for #{inspect(original)}"
        assert type3 == expected_type, "Third cycle type failed for #{inspect(original)}"
        assert value3 == expected_value, "Third cycle value failed for #{inspect(original)}"
      end)
    end
    
    test "handles mixed complex types in single PDU" do
      # Test a PDU with multiple different complex types
      mixed_varbinds = [
        {[1, 3, 6, 1, 2, 1, 1, 3, 0], :auto, {:timeticks, 123456}},
        {[1, 3, 6, 1, 2, 1, 2, 2, 1, 10, 1], :auto, {:counter32, 987654}},
        {[1, 3, 6, 1, 2, 1, 2, 2, 1, 5, 1], :auto, {:gauge32, 100000000}},
        {[1, 3, 6, 1, 2, 1, 4, 20, 1, 1, 1], :auto, {:ip_address, <<192, 168, 1, 100>>}},
        {[1, 3, 6, 1, 2, 1, 1, 2, 0], :auto, {:object_identifier, [1, 3, 6, 1, 4, 1, 8072, 3, 2, 10]}},
        {[1, 3, 6, 1, 4, 1, 9999, 1, 1], :auto, {:opaque, <<0xDE, 0xAD, 0xBE, 0xEF>>}},
        {[1, 3, 6, 1, 2, 1, 99, 1, 0], :auto, {:no_such_object, nil}}
      ]
      
      pdu = PDU.build_response(1, 0, 0, mixed_varbinds)
      message = PDU.build_message(pdu, "public", :v2c)
      
      {:ok, encoded} = PDU.encode_message(message)
      {:ok, decoded} = PDU.decode_message(encoded)
      
      decoded_varbinds = decoded.pdu.varbinds
      assert length(decoded_varbinds) == 7, "Should have 7 varbinds in mixed PDU"
      
      # Check each varbind
      expected_values = [
        {:timeticks, 123456},
        {:counter32, 987654},
        {:gauge32, 100000000},
        {:ip_address, <<192, 168, 1, 100>>},
        {:object_identifier, [1, 3, 6, 1, 4, 1, 8072, 3, 2, 10]},
        {:opaque, <<0xDE, 0xAD, 0xBE, 0xEF>>},
        {:no_such_object, nil}
      ]
      
      Enum.zip(decoded_varbinds, expected_values)
      |> Enum.with_index()
      |> Enum.each(fn {{{_oid, decoded_type, decoded_value}, {expected_type, expected_value}}, index} ->
        assert decoded_type == expected_type, 
          "Mixed PDU varbind #{index + 1} type failed: expected #{inspect(expected_type)}, got #{inspect(decoded_type)}"
        assert decoded_value == expected_value, 
          "Mixed PDU varbind #{index + 1} value failed: expected #{inspect(expected_value)}, got #{inspect(decoded_value)}"
      end)
    end
    
    test "handles boundary values for numeric types" do
      # Test boundary values for all numeric types
      boundary_tests = [
        {:counter32, 0, "counter32 minimum"},
        {:counter32, 2147483647, "counter32 large value"},
        {:gauge32, 0, "gauge32 minimum"},
        {:gauge32, 2147483647, "gauge32 large value"},
        {:timeticks, 0, "timeticks minimum"},
        {:timeticks, 2147483647, "timeticks large value"},
        {:counter64, 0, "counter64 minimum"},
        {:counter64, 9223372036854775807, "counter64 large value"}
      ]
      
      Enum.each(boundary_tests, fn {type, value, description} ->
        test_tuple = {type, value}
        
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, test_tuple}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, decoded_type, decoded_value} = hd(decoded.pdu.varbinds)
        
        assert decoded_type == type, 
          "Boundary test #{description} failed: expected type #{inspect(type)}, got #{inspect(decoded_type)}"
        assert decoded_value == value,
          "Boundary test #{description} failed: expected value #{inspect(value)}, got #{inspect(decoded_value)}"
      end)
    end
    
    test "handles invalid OID strings gracefully with :auto type" do
      # Test cases that should encode as :null due to invalid OID format
      invalid_oid_tests = [
        {{:object_identifier, "not.a.valid.oid"}, "object_identifier tuple with invalid string"}
      ]
      
      Enum.each(invalid_oid_tests, fn {test_value, description} ->
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, test_value}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        case PDU.encode_message(message) do
          {:ok, encoded} ->
            # Expected behavior - invalid OID strings should encode as :null
            {:ok, decoded} = PDU.decode_message(encoded)
            {_oid, type, value} = hd(decoded.pdu.varbinds)
            assert type == :null
            assert value == :null
          {:error, error} ->
            flunk("Expected success with :null encoding for #{description}, but got error: #{inspect(error)}")
        end
      end)
    end
  end
end