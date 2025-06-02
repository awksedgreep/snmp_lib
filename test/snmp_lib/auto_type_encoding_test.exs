defmodule SnmpLib.AutoTypeEncodingTest do
  use ExUnit.Case, async: true
  
  alias SnmpLib.PDU
  
  describe "Auto type encoding for complex SNMP data types" do
    test "encodes and decodes all supported tuple formats with :auto type" do
      # Test all the tuple formats we added support for
      tuple_tests = [
        {{:counter32, 12345}, "counter32 tuple"},
        {{:gauge32, 98765}, "gauge32 tuple"},
        {{:timeticks, 123456789}, "timeticks tuple"},
        {{:counter64, 9876543210}, "counter64 tuple"},
        {{:ip_address, <<192, 168, 1, 1>>}, "ip_address tuple"},
        {{:opaque, <<1, 2, 3, 4, 5>>}, "opaque tuple"},
        {{:object_identifier, [1, 3, 6, 1, 2, 1, 1, 1, 0]}, "object_identifier tuple with list"},
        {{:object_identifier, "1.3.6.1.2.1.1.1.0"}, "object_identifier tuple with string"},
        {{:no_such_object, nil}, "no_such_object exception"},
        {{:no_such_instance, nil}, "no_such_instance exception"},
        {{:end_of_mib_view, nil}, "end_of_mib_view exception"}
      ]
      
      Enum.each(tuple_tests, fn {test_value, description} ->
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, test_value}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        
        # For object_identifier strings, the expected result is converted to list format
        expected = case test_value do
          {:object_identifier, oid_string} when is_binary(oid_string) ->
            oid_list = String.split(oid_string, ".") |> Enum.map(&String.to_integer/1)
            {:object_identifier, oid_list}
          _ ->
            test_value
        end
        
        assert decoded_value == expected, 
          "Auto type encoding failed for #{description}: expected #{inspect(expected)}, got #{inspect(decoded_value)}"
      end)
    end
    
    test "handles invalid tuple values gracefully" do
      # Test that invalid tuple values fall back to :null
      invalid_tests = [
        {{:counter32, -1}, "negative counter32"},
        {{:counter32, "not_a_number"}, "non-numeric counter32"},
        {{:gauge32, -100}, "negative gauge32"},
        {{:timeticks, "invalid"}, "non-numeric timeticks"},
        {{:counter64, -5}, "negative counter64"},
        {{:ip_address, <<192, 168, 1>>}, "short IP address"},
        {{:ip_address, "192.168.1.1"}, "string IP address"},
        {{:opaque, 12345}, "non-binary opaque"},
        {{:object_identifier, []}, "empty OID list"},
        {{:object_identifier, [1]}, "too short OID list"},
        {{:object_identifier, "invalid.oid.format"}, "invalid string OID"},
        {{:unknown_type, "value"}, "unknown tuple type"}
      ]
      
      Enum.each(invalid_tests, fn {test_value, description} ->
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, test_value}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        
        assert decoded_value == :null, 
          "Invalid #{description} should fall back to :null, got #{inspect(decoded_value)}"
      end)
    end
    
    test "preserves data integrity across encode/decode cycles for all types" do
      # Test round-trip integrity for all supported complex types
      test_data = [
        {:counter32, 2147483647},
        {:gauge32, 1000000},
        {:timeticks, 12345678},
        {:counter64, 9223372036854775807},
        {:ip_address, <<10, 0, 0, 1>>},
        {:opaque, :crypto.strong_rand_bytes(32)},
        {:object_identifier, [1, 3, 6, 1, 4, 1, 2021, 1, 1, 1, 0]},
        {:no_such_object, nil},
        {:no_such_instance, nil},
        {:end_of_mib_view, nil}
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
        {_, _, result1} = hd(decoded1.pdu.varbinds)
        
        # Cycle 2
        varbinds2 = [{[1, 3, 6, 1], :auto, result1}]
        pdu2 = PDU.build_response(2, 0, 0, varbinds2)
        message2 = PDU.build_message(pdu2, "public", :v2c)
        
        {:ok, encoded2} = PDU.encode_message(message2)
        {:ok, decoded2} = PDU.decode_message(encoded2)
        {_, _, result2} = hd(decoded2.pdu.varbinds)
        
        # Cycle 3
        varbinds3 = [{[1, 3, 6, 1], :auto, result2}]
        pdu3 = PDU.build_response(3, 0, 0, varbinds3)
        message3 = PDU.build_message(pdu3, "public", :v2c)
        
        {:ok, encoded3} = PDU.encode_message(message3)
        {:ok, decoded3} = PDU.decode_message(encoded3)
        {_, _, result3} = hd(decoded3.pdu.varbinds)
        
        assert result1 == original, "First cycle failed for #{inspect(original)}"
        assert result2 == original, "Second cycle failed for #{inspect(original)}"
        assert result3 == original, "Third cycle failed for #{inspect(original)}"
        assert result1 == result2, "Results differ between cycle 1 and 2 for #{inspect(original)}"
        assert result2 == result3, "Results differ between cycle 2 and 3 for #{inspect(original)}"
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
      |> Enum.each(fn {{{_oid, _type, decoded_value}, expected}, index} ->
        assert decoded_value == expected, 
          "Mixed PDU varbind #{index + 1} failed: expected #{inspect(expected)}, got #{inspect(decoded_value)}"
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
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        
        assert decoded_value == test_tuple, 
          "Boundary test #{description} failed: expected #{inspect(test_tuple)}, got #{inspect(decoded_value)}"
      end)
    end
  end
end