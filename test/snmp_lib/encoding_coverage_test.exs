defmodule SnmpLib.EncodingCoverageTest do
  use ExUnit.Case, async: true
  
  alias SnmpLib.PDU
  
  @moduletag :unit
  @moduletag :encoding_coverage
  
  describe "Encoding function coverage through public API" do
    test "encode_message/1 with valid SNMP message" do
      # Test encoding through the public API
      pdu = PDU.build_get_request([1, 3, 6, 1, 2, 1, 1, 1, 0], 12345)
      message = PDU.build_message(pdu, "public", :v2c)
      
      # This should succeed
      result = PDU.encode_message(message)
      assert {:ok, encoded} = result
      assert is_binary(encoded)
      assert byte_size(encoded) > 0
    end
    
    test "encode_message/1 with invalid message format" do
      # This should fail with invalid message format
      result = PDU.encode_message("not_a_map")
      assert {:error, :invalid_message_format} = result
    end
    
    test "encode_message/1 with missing required fields" do
      # Missing PDU field
      invalid_message = %{version: 1, community: "public"}
      result = PDU.encode_message(invalid_message)
      assert {:error, :invalid_message_format} = result
    end
    
    test "OID normalization through PDU building" do
      # Test that string OIDs are properly normalized in PDU building
      string_oid = "1.3.6.1.2.1.1.1.0"
      pdu = PDU.build_get_request(string_oid, 12345)
      
      # The varbind should contain the normalized OID as a list
      [{oid, _, _}] = pdu.varbinds
      assert oid == [1, 3, 6, 1, 2, 1, 1, 1, 0]
    end
    
    test "OID normalization with invalid string falls back gracefully" do
      # Test that invalid OID strings fall back to a safe default
      # This tests the normalize_oid function indirectly
      invalid_oid = "not.a.valid.oid"
      pdu = PDU.build_get_request(invalid_oid, 12345)
      
      # Should fallback to the default OID
      [{oid, _, _}] = pdu.varbinds
      assert oid == [1, 3, 6, 1]
    end
  end
  
  describe "PDU validation edge cases" do
    test "validate/1 with missing type field" do
      invalid_pdu = %{request_id: 123, varbinds: []}
      result = PDU.validate(invalid_pdu)
      assert {:error, :missing_required_fields} = result
    end
    
    test "validate/1 with invalid type" do
      invalid_pdu = %{type: :invalid_type, request_id: 123, varbinds: []}
      result = PDU.validate(invalid_pdu)
      assert {:error, :invalid_pdu_type} = result
    end
    
    test "validate/1 with GETBULK missing specific fields" do
      # Missing non_repeaters and max_repetitions
      invalid_bulk = %{
        type: :get_bulk_request, 
        request_id: 123, 
        varbinds: []
      }
      result = PDU.validate(invalid_bulk)
      assert {:error, :missing_bulk_fields} = result
    end
    
    test "validate/1 with standard PDU missing error fields" do
      # Missing error_status and error_index
      invalid_standard = %{
        type: :get_request, 
        request_id: 123, 
        varbinds: []
      }
      result = PDU.validate(invalid_standard)
      assert {:error, :missing_required_fields} = result
    end
    
    test "validate/1 with non-map input" do
      result = PDU.validate("not_a_map")
      assert {:error, :invalid_pdu_format} = result
    end
  end
  
  describe "Error masking prevention" do
    test "encode_message/1 should not mask encoding errors silently" do
      # Create a message that would trigger encoding errors
      invalid_pdu = %{type: :invalid_type, request_id: 123, varbinds: []}
      message = %{version: 1, community: "public", pdu: invalid_pdu}
      
      # This should return an error, not succeed silently
      result = PDU.encode_message(message)
      assert {:error, _} = result
    end
    
    test "round-trip encoding/decoding preserves data integrity" do
      # Test that what we encode can be decoded back correctly
      original_pdu = PDU.build_get_request([1, 3, 6, 1, 2, 1, 1, 1, 0], 12345)
      message = PDU.build_message(original_pdu, "public", :v2c)
      
      # Encode
      {:ok, encoded} = PDU.encode_message(message)
      
      # Decode
      {:ok, decoded} = PDU.decode_message(encoded)
      
      # Verify critical fields are preserved
      assert decoded.version == 1  # v2c maps to 1
      assert decoded.community == "public"
      assert decoded.pdu.type == :get_request
      assert decoded.pdu.request_id == 12345
      assert length(decoded.pdu.varbinds) == 1
      
      # Verify OID is preserved (this was the bug we fixed)
      [{oid, _, _}] = decoded.pdu.varbinds
      assert oid == [1, 3, 6, 1, 2, 1, 1, 1, 0]
    end
    
    test "GETBULK round-trip preserves specific fields" do
      # Test GETBULK PDU specifically since it has different validation
      original_pdu = PDU.build_get_bulk_request([1, 3, 6, 1, 2, 1], 12345, 1, 10)
      message = PDU.build_message(original_pdu, "public", :v2c)
      
      # Encode
      {:ok, encoded} = PDU.encode_message(message)
      
      # Decode
      {:ok, decoded} = PDU.decode_message(encoded)
      
      # Verify GETBULK specific fields are preserved
      assert decoded.pdu.type == :get_bulk_request
      assert decoded.pdu.non_repeaters == 1
      assert decoded.pdu.max_repetitions == 10
      
      # Verify OID is preserved
      [{oid, _, _}] = decoded.pdu.varbinds
      assert oid == [1, 3, 6, 1, 2, 1]
    end
  end
  
  describe "Historical bug reproduction" do
    test "OID truncation bug would have been caught" do
      # This test demonstrates the bug that was happening:
      # OIDs were being truncated to [1, 3, 6, 1] regardless of input
      
      # Test various OID formats that should be preserved
      test_oids = [
        [1, 3, 6, 1, 2, 1, 1, 1, 0],
        [1, 3, 6, 1, 4, 1, 9, 9, 1, 1, 1, 1, 1],
        "1.3.6.1.2.1.2.2.1.1.1",
        "1.3.6.1.4.1.2021.10.1.3.1"
      ]
      
      for test_oid <- test_oids do
        pdu = PDU.build_get_request(test_oid, 12345)
        message = PDU.build_message(pdu, "public", :v2c)
        
        # Encode and decode
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        # The OID should NOT be truncated to [1, 3, 6, 1]
        [{oid, _, _}] = decoded.pdu.varbinds
        
        expected_oid = case test_oid do
          list when is_list(list) -> list
          string when is_binary(string) -> 
            {:ok, parsed} = SnmpLib.OID.string_to_list(string)
            parsed
        end
        
        assert oid == expected_oid, 
          "OID #{inspect(test_oid)} was truncated to #{inspect(oid)}, expected #{inspect(expected_oid)}"
      end
    end
  end
end
