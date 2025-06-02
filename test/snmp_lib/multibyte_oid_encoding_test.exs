defmodule SnmpLib.MultibyteOidEncodingTest do
  use ExUnit.Case, async: true
  
  alias SnmpLib.PDU
  
  describe "Multibyte OID subidentifier encoding (>127)" do
    test "correctly encodes and decodes boundary values around 127" do
      # Test values at the boundary where multibyte encoding starts
      boundary_values = [
        {126, "just below multibyte threshold"},
        {127, "exactly at threshold"},
        {128, "first multibyte value"},
        {129, "second multibyte value"},
        {255, "max single-byte value"},
        {256, "first two-byte value"}
      ]
      
      Enum.each(boundary_values, fn {value, description} ->
        # Test with list OID containing the value
        test_oid = [1, 3, 6, 1, 4, 1, value]
        
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, {:object_identifier, test_oid}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        expected = {:object_identifier, test_oid}
        
        assert decoded_value == expected, 
          "Boundary value #{description} (#{value}) failed: expected #{inspect(expected)}, got #{inspect(decoded_value)}"
      end)
    end
    
    test "correctly handles enterprise numbers requiring multibyte encoding" do
      # These enterprise numbers were specifically problematic before the fix
      enterprise_numbers = [
        {2021, "Net-SNMP enterprise number"},
        {311, "Microsoft enterprise number"},
        {1000, "Large enterprise number"},
        {9999, "Very large enterprise number"},
        {16383, "Maximum 2-byte multibyte value"},
        {16384, "First 3-byte multibyte value"},
        {65535, "Maximum 16-bit value"}
      ]
      
      Enum.each(enterprise_numbers, fn {enterprise, description} ->
        # Test full enterprise OID
        full_oid = [1, 3, 6, 1, 4, 1, enterprise, 1, 1, 1, 0]
        
        # Test with string format
        oid_string = Enum.join(full_oid, ".")
        test_value = {:object_identifier, oid_string}
        
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, test_value}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        expected = {:object_identifier, full_oid}
        
        assert decoded_value == expected, 
          "Enterprise #{description} (#{enterprise}) failed: expected #{inspect(expected)}, got #{inspect(decoded_value)}"
        
        # Also test with list format for the same enterprise number
        varbinds_list = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, full_oid}]
        pdu_list = PDU.build_response(2, 0, 0, varbinds_list)
        message_list = PDU.build_message(pdu_list, "public", :v2c)
        
        {:ok, encoded_list} = PDU.encode_message(message_list)
        {:ok, decoded_list} = PDU.decode_message(encoded_list)
        
        {_oid_list, _type_list, decoded_value_list} = hd(decoded_list.pdu.varbinds)
        
        assert decoded_value_list == expected, 
          "Enterprise #{description} (#{enterprise}) list format failed: expected #{inspect(expected)}, got #{inspect(decoded_value_list)}"
      end)
    end
    
    test "validates specific multibyte encoding patterns" do
      # Test specific values that require precise multibyte encoding
      multibyte_tests = [
        {2021, <<143, 101>>, "2021 should encode as [143, 101]"},
        {16383, <<255, 127>>, "16383 should encode as [255, 127] (max 2-byte)"},
        {16384, <<129, 128, 0>>, "16384 should encode as [129, 128, 0] (first 3-byte)"}
      ]
      
      Enum.each(multibyte_tests, fn {value, expected_bytes, description} ->
        test_oid = [1, 3, 6, 1, 4, 1, value]
        
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, {:object_identifier, test_oid}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        
        # Check that the expected bytes appear in the encoded message
        # (We can't easily extract just the subidentifier bytes, but we can verify round-trip)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        expected = {:object_identifier, test_oid}
        
        assert decoded_value == expected, 
          "Multibyte pattern #{description} failed round-trip: expected #{inspect(expected)}, got #{inspect(decoded_value)}"
      end)
    end
    
    test "handles very large subidentifiers correctly" do
      # Test values that require 3+ bytes in multibyte encoding
      large_values = [
        2097151,   # Maximum 3-byte value (2^21 - 1)
        2097152,   # First 4-byte value
        134217727, # Maximum 4-byte value (2^27 - 1)
        268435455  # Large value requiring careful encoding
      ]
      
      Enum.each(large_values, fn value ->
        test_oid = [1, 3, 6, 1, 4, 1, value]
        
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, {:object_identifier, test_oid}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        expected = {:object_identifier, test_oid}
        
        assert decoded_value == expected, 
          "Large value #{value} failed: expected #{inspect(expected)}, got #{inspect(decoded_value)}"
      end)
    end
    
    test "preserves multibyte values across multiple encode/decode cycles" do
      # Test that multibyte values maintain their integrity across multiple cycles
      test_values = [2021, 16383, 16384, 65535]
      
      Enum.each(test_values, fn value ->
        original_oid = [1, 3, 6, 1, 4, 1, value, 1, 1, 0]
        
        # First cycle
        varbinds1 = [{[1, 3, 6, 1], :auto, {:object_identifier, original_oid}}]
        pdu1 = PDU.build_response(1, 0, 0, varbinds1)
        message1 = PDU.build_message(pdu1, "public", :v2c)
        
        {:ok, encoded1} = PDU.encode_message(message1)
        {:ok, decoded1} = PDU.decode_message(encoded1)
        {_, _, result1} = hd(decoded1.pdu.varbinds)
        
        # Second cycle using result from first
        varbinds2 = [{[1, 3, 6, 1], :auto, result1}]
        pdu2 = PDU.build_response(2, 0, 0, varbinds2)
        message2 = PDU.build_message(pdu2, "public", :v2c)
        
        {:ok, encoded2} = PDU.encode_message(message2)
        {:ok, decoded2} = PDU.decode_message(encoded2)
        {_, _, result2} = hd(decoded2.pdu.varbinds)
        
        # Third cycle
        varbinds3 = [{[1, 3, 6, 1], :auto, result2}]
        pdu3 = PDU.build_response(3, 0, 0, varbinds3)
        message3 = PDU.build_message(pdu3, "public", :v2c)
        
        {:ok, encoded3} = PDU.encode_message(message3)
        {:ok, decoded3} = PDU.decode_message(encoded3)
        {_, _, result3} = hd(decoded3.pdu.varbinds)
        
        expected = {:object_identifier, original_oid}
        assert result1 == expected, "First cycle failed for value #{value}"
        assert result2 == expected, "Second cycle failed for value #{value}"  
        assert result3 == expected, "Third cycle failed for value #{value}"
        assert result1 == result2, "Results differ between cycle 1 and 2 for value #{value}"
        assert result2 == result3, "Results differ between cycle 2 and 3 for value #{value}"
      end)
    end
    
    test "handles mixed normal and multibyte values in same OID" do
      # Test OIDs that contain both single-byte and multibyte subidentifiers
      mixed_oids = [
        [1, 3, 6, 1, 4, 1, 2021, 42, 128, 7, 255],
        [1, 3, 6, 1, 2, 1, 2, 2, 1, 10, 1000],
        [1, 3, 16383, 1, 65535, 0, 127, 16384]
      ]
      
      Enum.each(mixed_oids, fn oid ->
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, {:object_identifier, oid}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        expected = {:object_identifier, oid}
        
        assert decoded_value == expected, 
          "Mixed OID #{inspect(oid)} failed: expected #{inspect(expected)}, got #{inspect(decoded_value)}"
      end)
    end
  end
end