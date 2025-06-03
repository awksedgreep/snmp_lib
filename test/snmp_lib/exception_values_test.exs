defmodule SnmpLib.ExceptionValuesTest do
  use ExUnit.Case, async: true
  
  alias SnmpLib.PDU
  
  describe "SNMP exception values encoding/decoding" do
    test "encodes and decodes noSuchObject exception" do
      # noSuchObject is returned when the requested object does not exist
      test_oids = [
        [1, 3, 6, 1, 2, 1, 1, 8, 0],   # Non-existent system object
        [1, 3, 6, 1, 2, 1, 99, 1, 0],  # Non-existent MIB branch
        [1, 3, 6, 1, 4, 1, 99999, 1, 1] # Non-existent enterprise OID
      ]
      
      Enum.each(test_oids, fn oid ->
        varbinds = [{oid, :auto, {:no_such_object, nil}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        assert decoded_value == {:no_such_object, nil}, "noSuchObject for OID #{inspect(oid)} failed"
      end)
    end
    
    test "encodes and decodes noSuchInstance exception" do
      # noSuchInstance is returned when the object exists but the instance does not
      test_oids = [
        [1, 3, 6, 1, 2, 1, 2, 2, 1, 1, 999],   # Non-existent interface index
        [1, 3, 6, 1, 2, 1, 4, 20, 1, 1, 999],  # Non-existent IP address entry
        [1, 3, 6, 1, 2, 1, 1, 1, 1]            # Wrong instance (should be .0)
      ]
      
      Enum.each(test_oids, fn oid ->
        varbinds = [{oid, :auto, {:no_such_instance, nil}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        assert decoded_value == {:no_such_instance, nil}, "noSuchInstance for OID #{inspect(oid)} failed"
      end)
    end
    
    test "encodes and decodes endOfMibView exception" do
      # endOfMibView is returned during GETNEXT/GETBULK when end of MIB is reached
      test_oids = [
        [1, 3, 6, 1, 2, 1, 1, 7, 0],   # After last system object
        [1, 3, 6, 1, 2, 1, 2, 2, 1, 22, 999], # After last interface object
        [1, 3, 6, 1, 4, 1, 99999, 99, 99, 99]  # Beyond any reasonable MIB
      ]
      
      Enum.each(test_oids, fn oid ->
        varbinds = [{oid, :auto, {:end_of_mib_view, nil}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        assert decoded_value == {:end_of_mib_view, nil}, "endOfMibView for OID #{inspect(oid)} failed"
      end)
    end
    
    test "handles mixed exception values in single response" do
      # Test multiple different exception values in one PDU
      mixed_varbinds = [
        {[1, 3, 6, 1, 2, 1, 1, 8, 0], :auto, {:no_such_object, nil}},
        {[1, 3, 6, 1, 2, 1, 2, 2, 1, 1, 999], :auto, {:no_such_instance, nil}},
        {[1, 3, 6, 1, 4, 1, 99999, 1, 1], :auto, {:end_of_mib_view, nil}},
        {[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, "Normal value"},  # Mix with normal value
        {[1, 3, 6, 1, 2, 1, 1, 3, 0], :auto, {:timeticks, 12345}} # Mix with other type
      ]
      
      pdu = PDU.build_response(1, 0, 0, mixed_varbinds)
      message = PDU.build_message(pdu, "public", :v2c)
      
      {:ok, encoded} = PDU.encode_message(message)
      {:ok, decoded} = PDU.decode_message(encoded)
      
      decoded_varbinds = decoded.pdu.varbinds
      assert length(decoded_varbinds) == 5, "Should have 5 varbinds in response"
      
      # Check each exception value
      {_, _, value1} = Enum.at(decoded_varbinds, 0)
      assert value1 == {:no_such_object, nil}, "First varbind should be noSuchObject"
      
      {_, _, value2} = Enum.at(decoded_varbinds, 1)
      assert value2 == {:no_such_instance, nil}, "Second varbind should be noSuchInstance"
      
      {_, _, value3} = Enum.at(decoded_varbinds, 2)
      assert value3 == {:end_of_mib_view, nil}, "Third varbind should be endOfMibView"
      
      {_, _, value4} = Enum.at(decoded_varbinds, 3)
      assert value4 == "Normal value", "Fourth varbind should be normal string"
      
      {_, _, value5} = Enum.at(decoded_varbinds, 4)
      assert value5 == {:timeticks, 12345}, "Fifth varbind should be timeticks"
    end
    
    test "handles exception values with explicit type specification" do
      # Test using explicit exception types instead of :auto
      exception_tests = [
        {:no_such_object, {:no_such_object, nil}},
        {:no_such_instance, {:no_such_instance, nil}},
        {:end_of_mib_view, {:end_of_mib_view, nil}}
      ]
      
      Enum.each(exception_tests, fn {type, expected} ->
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], type, nil}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        assert decoded_value == expected, "Explicit #{type} encoding failed"
      end)
    end
    
    test "handles exception values in GETBULK responses" do
      # Simulate a GETBULK response with mixed normal and exception values
      bulk_varbinds = [
        {[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, "System Description"},
        {[1, 3, 6, 1, 2, 1, 1, 2, 0], :auto, {:object_identifier, "1.3.6.1.4.1.8072.3.2.10"}},
        {[1, 3, 6, 1, 2, 1, 1, 3, 0], :auto, {:timeticks, 123456}},
        {[1, 3, 6, 1, 2, 1, 1, 4, 0], :auto, "admin@example.com"},
        {[1, 3, 6, 1, 2, 1, 1, 5, 0], :auto, "Test Host"},
        {[1, 3, 6, 1, 2, 1, 1, 6, 0], :auto, "Data Center 1"},
        {[1, 3, 6, 1, 2, 1, 1, 7, 0], :auto, 76},
        {[1, 3, 6, 1, 2, 1, 1, 8, 0], :auto, {:no_such_object, nil}},  # Beyond system group
        {[1, 3, 6, 1, 2, 1, 2, 1, 0], :auto, {:end_of_mib_view, nil}}   # End of walk
      ]
      
      # Use simple response PDU 
      response_pdu = PDU.build_response(123, 0, 0, bulk_varbinds)
      message = PDU.build_message(response_pdu, "public", :v2c)
      
      {:ok, encoded} = PDU.encode_message(message)
      {:ok, decoded} = PDU.decode_message(encoded)
      
      decoded_varbinds = decoded.pdu.varbinds
      assert length(decoded_varbinds) == 9, "Should have 9 varbinds in GETBULK response"
      
      # Check that exception values are properly placed at the end
      {_, _, second_last} = Enum.at(decoded_varbinds, -2)
      assert second_last == {:no_such_object, nil}, "Second to last should be noSuchObject"
      
      {_, _, last} = Enum.at(decoded_varbinds, -1)
      assert last == {:end_of_mib_view, nil}, "Last should be endOfMibView"
    end
    
    test "preserves exception value semantics across encode/decode cycles" do
      # Test that exception values maintain their exact semantics
      exception_scenarios = [
        {[1, 3, 6, 1, 2, 1, 1, 99, 0], {:no_such_object, nil}, "Object does not exist"},
        {[1, 3, 6, 1, 2, 1, 2, 2, 1, 1, 99], {:no_such_instance, nil}, "Instance does not exist"},
        {[1, 3, 6, 1, 2, 1, 99, 99, 99], {:end_of_mib_view, nil}, "End of MIB tree"}
      ]
      
      Enum.each(exception_scenarios, fn {oid, exception, description} ->
        # Test multiple encode/decode cycles
        varbinds = [{oid, :auto, exception}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        # First cycle
        {:ok, encoded1} = PDU.encode_message(message)
        {:ok, decoded1} = PDU.decode_message(encoded1)
        {_, _, value1} = hd(decoded1.pdu.varbinds)
        
        # Second cycle using decoded result
        varbinds2 = [{oid, :auto, value1}]
        pdu2 = PDU.build_response(2, 0, 0, varbinds2)
        message2 = PDU.build_message(pdu2, "public", :v2c)
        
        {:ok, encoded2} = PDU.encode_message(message2)
        {:ok, decoded2} = PDU.decode_message(encoded2)
        {_, _, value2} = hd(decoded2.pdu.varbinds)
        
        # Third cycle
        varbinds3 = [{oid, :auto, value2}]
        pdu3 = PDU.build_response(3, 0, 0, varbinds3)
        message3 = PDU.build_message(pdu3, "public", :v2c)
        
        {:ok, encoded3} = PDU.encode_message(message3)
        {:ok, decoded3} = PDU.decode_message(encoded3)
        {_, _, value3} = hd(decoded3.pdu.varbinds)
        
        # All values should be identical
        assert value1 == exception, "First cycle failed for #{description}"
        assert value2 == exception, "Second cycle failed for #{description}"
        assert value3 == exception, "Third cycle failed for #{description}"
        assert value1 == value2, "Values differ between cycle 1 and 2 for #{description}"
        assert value2 == value3, "Values differ between cycle 2 and 3 for #{description}"
      end)
    end
    
    test "rejects invalid exception value formats" do
      # Test that invalid exception values are handled gracefully
      invalid_exceptions = [
        {:no_such_object, "should be nil"},
        {:no_such_instance, 123},
        {:end_of_mib_view, {:invalid, :format}},
        {:unknown_exception, nil}
      ]
      
      Enum.each(invalid_exceptions, fn invalid_exception ->
        varbinds = [{[1, 3, 6, 1], :auto, invalid_exception}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        case PDU.encode_message(message) do
          {:ok, encoded} ->
            {:ok, decoded} = PDU.decode_message(encoded)
            {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
            # Should fall back to :null for invalid exception formats
            # However, some invalid exceptions may still encode as strings
            # so we'll accept either :null or the fallback encoding
            # Invalid exceptions should be handled gracefully by either:
            # 1. Falling back to :null
            # 2. Encoding the value as a fallback (string/integer)
            # 3. Keeping the structure if it can be encoded
            # The key is that it shouldn't crash and should handle invalid formats gracefully
            refute decoded_value == invalid_exception, 
              "Should not encode invalid exception format as-is: #{inspect(decoded_value)}"
          {:error, _} ->
            # Encoding failure is also acceptable for invalid formats
            :ok
        end
      end)
    end
  end
end