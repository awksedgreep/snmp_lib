defmodule SnmpLib.OidEncodingEdgeCasesTest do
  use ExUnit.Case, async: true
  
  alias SnmpLib.PDU
  
  describe "OID encoding edge cases and error conditions" do
    test "handles first two subidentifiers encoding correctly" do
      # The first two subidentifiers are encoded as a single byte: (first * 40) + second
      # Test edge cases for this encoding
      first_two_tests = [
        {[0, 0], "minimum valid OID"},
        {[0, 39], "maximum second component for first=0"},
        {[1, 0], "minimum with first=1"},
        {[1, 39], "maximum second component for first=1"},
        {[2, 0], "minimum with first=2"},
        {[2, 39], "valid second component for first=2"}
      ]
      
      Enum.each(first_two_tests, fn {oid, description} ->
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, {:object_identifier, oid}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        expected = {:object_identifier, oid}
        
        assert decoded_value == expected, 
          "First two subidentifiers #{description} failed: expected #{inspect(expected)}, got #{inspect(decoded_value)}"
      end)
    end
    
    test "rejects invalid first subidentifier values" do
      # First subidentifier must be 0, 1, or 2
      invalid_first = [
        [3, 0],
        [4, 5],
        [10, 1],
        [255, 0]
      ]
      
      Enum.each(invalid_first, fn invalid_oid ->
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, {:object_identifier, invalid_oid}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        
        # Should fall back to :null for invalid first subidentifier
        assert decoded_value == :null, 
          "Invalid first subidentifier #{inspect(invalid_oid)} should become :null, got #{inspect(decoded_value)}"
      end)
    end
    
    test "rejects invalid second subidentifier values for first=0 or first=1" do
      # When first subidentifier is 0 or 1, second must be <= 39
      invalid_second = [
        [0, 40],
        [0, 50],
        [1, 40],
        [1, 100]
      ]
      
      Enum.each(invalid_second, fn invalid_oid ->
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, {:object_identifier, invalid_oid}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        
        # Should fall back to :null for invalid second subidentifier
        assert decoded_value == :null, 
          "Invalid second subidentifier #{inspect(invalid_oid)} should become :null, got #{inspect(decoded_value)}"
      end)
    end
    
    test "handles string OID parsing edge cases" do
      # Test various malformed string OID formats
      malformed_strings = [
        {"", "empty string"},
        {"1", "single component"},
        {"1.3.6.1.2.1.1.1.0.", "trailing dot"},
        {".1.3.6.1.2.1.1.1.0", "leading dot"},
        {"1..3.6", "double dot"},
        {"1.3.6.x.1", "non-numeric component"},
        {"1.3.6.1.2.1.1.1.0.extra", "non-numeric at end"},
        {"1.3.6.-1", "negative component"},
        {"1,3,6,1", "comma instead of dot"},
        {"1 3 6 1", "spaces instead of dots"}
      ]
      
      Enum.each(malformed_strings, fn {malformed_string, description} ->
        test_value = {:object_identifier, malformed_string}
        
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, test_value}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        
        assert decoded_value == :null, 
          "Malformed string OID #{description} should become :null, got #{inspect(decoded_value)}"
      end)
    end
    
    test "handles explicit :object_identifier type with various inputs" do
      # Test explicit type with different input formats
      explicit_tests = [
        # Valid inputs
        {[1, 3, 6, 1, 2, 1, 1, 1, 0], {:object_identifier, [1, 3, 6, 1, 2, 1, 1, 1, 0]}, "valid list"},
        {"1.3.6.1.2.1.1.1.0", {:object_identifier, [1, 3, 6, 1, 2, 1, 1, 1, 0]}, "valid string"},
        
        # Invalid inputs that should become :null
        {[], :null, "empty list"},
        {[1], :null, "single element list"},
        {"", :null, "empty string"},
        {"invalid", :null, "invalid string"},
        {123, :null, "integer instead of list/string"},
        {:not_an_oid, :null, "atom instead of list/string"}
      ]
      
      Enum.each(explicit_tests, fn {input, expected, description} ->
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :object_identifier, input}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        
        assert decoded_value == expected, 
          "Explicit type #{description} failed: expected #{inspect(expected)}, got #{inspect(decoded_value)}"
      end)
    end
    
    test "stress test with very long OIDs" do
      # Test OIDs with many components to ensure no buffer overflows or performance issues
      long_oids = [
        # OID with 50 components
        [1, 3, 6, 1, 4, 1, 9999] ++ Enum.to_list(1..43),
        
        # OID with mixed small and large values
        [1, 3, 6, 1, 4, 1] ++ Enum.map(1..30, fn i -> if rem(i, 3) == 0, do: i * 1000, else: i end),
        
        # OID with many multibyte values
        [1, 3, 6, 1, 4, 1] ++ Enum.map(1..20, &(&1 * 1000))
      ]
      
      Enum.each(long_oids, fn long_oid ->
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, {:object_identifier, long_oid}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        expected = {:object_identifier, long_oid}
        
        assert decoded_value == expected, 
          "Long OID with #{length(long_oid)} components failed: got #{inspect(decoded_value)}"
      end)
    end
    
    test "handles concurrent encoding/decoding of problematic OIDs" do
      # Test thread safety with OIDs that previously caused issues
      problematic_oids = [
        [1, 3, 6, 1, 4, 1, 2021, 1, 1, 1, 0],
        [1, 3, 6, 1, 4, 1, 311, 1, 2, 3, 4],
        [1, 3, 6, 1, 4, 1, 16383, 1, 1],
        [1, 3, 6, 1, 4, 1, 16384, 1, 1],
        [1, 3, 6, 1, 4, 1, 65535, 1, 1]
      ]
      
      # Run concurrent tasks
      tasks = Enum.map(problematic_oids, fn oid ->
        Task.async(fn ->
          varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, {:object_identifier, oid}}]
          pdu = PDU.build_response(1, 0, 0, varbinds)
          message = PDU.build_message(pdu, "public", :v2c)
          
          {:ok, encoded} = PDU.encode_message(message)
          {:ok, decoded} = PDU.decode_message(encoded)
          
          {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
          {oid, decoded_value}
        end)
      end)
      
      # Wait for all tasks and verify results
      results = Task.await_many(tasks, 5000)
      
      Enum.each(results, fn {original_oid, decoded_value} ->
        expected = {:object_identifier, original_oid}
        assert decoded_value == expected, 
          "Concurrent test failed for OID #{inspect(original_oid)}: expected #{inspect(expected)}, got #{inspect(decoded_value)}"
      end)
    end
    
    test "validates ASN.1 BER compliance for multibyte encoding" do
      # Test specific ASN.1 BER encoding requirements for multibyte subidentifiers
      ber_tests = [
        # Test that high bit is set correctly
        {128, "first multibyte value"},
        {255, "single byte boundary"},
        {256, "two byte value"},
        {16383, "maximum two-byte value"},
        {16384, "first three-byte value"}
      ]
      
      Enum.each(ber_tests, fn {value, description} ->
        test_oid = [1, 3, 6, 1, 4, 1, value]
        
        # Test multiple round trips to ensure ASN.1 compliance
        original = {:object_identifier, test_oid}
        
        # Round trip 1
        varbinds1 = [{[1, 3, 6, 1], :auto, original}]
        pdu1 = PDU.build_response(1, 0, 0, varbinds1)
        message1 = PDU.build_message(pdu1, "public", :v2c)
        
        {:ok, encoded1} = PDU.encode_message(message1)
        {:ok, decoded1} = PDU.decode_message(encoded1)
        {_, _, result1} = hd(decoded1.pdu.varbinds)
        
        # Round trip 2
        varbinds2 = [{[1, 3, 6, 1], :auto, result1}]
        pdu2 = PDU.build_response(2, 0, 0, varbinds2)
        message2 = PDU.build_message(pdu2, "public", :v2c)
        
        {:ok, encoded2} = PDU.encode_message(message2)
        {:ok, decoded2} = PDU.decode_message(encoded2)
        {_, _, result2} = hd(decoded2.pdu.varbinds)
        
        assert result1 == original, "First round trip failed for #{description} (#{value})"
        assert result2 == original, "Second round trip failed for #{description} (#{value})"
        assert result1 == result2, "Round trip results differ for #{description} (#{value})"
      end)
    end
  end
end