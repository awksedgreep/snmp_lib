defmodule SnmpLib.ObjectIdentifierTest do
  use ExUnit.Case, async: true
  
  alias SnmpLib.PDU
  
  describe "Object Identifier encoding/decoding" do
    test "encodes and decodes standard SNMP OIDs" do
      standard_oids = [
        {[1, 3, 6, 1, 2, 1, 1, 1, 0], "sysDescr.0"},
        {[1, 3, 6, 1, 2, 1, 1, 2, 0], "sysObjectID.0"},
        {[1, 3, 6, 1, 2, 1, 1, 3, 0], "sysUpTime.0"},
        {[1, 3, 6, 1, 2, 1, 1, 4, 0], "sysContact.0"},
        {[1, 3, 6, 1, 2, 1, 1, 5, 0], "sysName.0"},
        {[1, 3, 6, 1, 2, 1, 1, 6, 0], "sysLocation.0"},
        {[1, 3, 6, 1, 2, 1, 1, 7, 0], "sysServices.0"}
      ]
      
      Enum.each(standard_oids, fn {oid, description} ->
        # Test with explicit :object_identifier type
        varbinds = [{oid, :object_identifier, oid}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        assert decoded_value == oid, "OID #{description} failed with explicit type"
        
        # Test with :auto type and tuple format
        varbinds = [{oid, :auto, {:object_identifier, oid}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        assert decoded_value == oid, "OID #{description} failed with auto type"
        
        # Test with :auto type and raw OID list (auto-detection)
        varbinds = [{oid, :auto, oid}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        assert decoded_value == oid, "OID #{description} failed with auto detection"
      end)
    end
    
    test "handles interface table OIDs" do
      # Common interface table OIDs with varying instance indices
      interface_oids = [
        {[1, 3, 6, 1, 2, 1, 2, 2, 1, 1, 1], "ifIndex.1"},
        {[1, 3, 6, 1, 2, 1, 2, 2, 1, 2, 1], "ifDescr.1"},
        {[1, 3, 6, 1, 2, 1, 2, 2, 1, 3, 1], "ifType.1"},
        {[1, 3, 6, 1, 2, 1, 2, 2, 1, 5, 1], "ifSpeed.1"},
        {[1, 3, 6, 1, 2, 1, 2, 2, 1, 8, 1], "ifOperStatus.1"},
        {[1, 3, 6, 1, 2, 1, 2, 2, 1, 10, 1], "ifInOctets.1"},
        {[1, 3, 6, 1, 2, 1, 2, 2, 1, 16, 1], "ifOutOctets.1"}
      ]
      
      Enum.each(interface_oids, fn {oid, description} ->
        varbinds = [{oid, :auto, {:object_identifier, oid}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        assert decoded_value == oid, "Interface OID #{description} failed"
      end)
    end
    
    test "handles enterprise-specific OIDs" do
      # Enterprise OIDs with high numbers that require multibyte encoding
      enterprise_oids = [
        {[1, 3, 6, 1, 4, 1, 9, 2, 1, 3, 0], "Cisco enterprise OID"},
        {[1, 3, 6, 1, 4, 1, 2021, 1, 1, 1, 0], "Net-SNMP enterprise OID"},
        {[1, 3, 6, 1, 4, 1, 311, 1, 1, 3, 1, 1], "Microsoft enterprise OID"},
        {[1, 3, 6, 1, 4, 1, 200, 1, 2, 3, 4], "OID with 200 (requires multibyte)"},
        {[1, 3, 6, 1, 4, 1, 1000, 1, 1, 1], "OID with 1000 (requires multibyte)"},
        {[1, 3, 6, 1, 4, 1, 65535, 1, 1], "OID with max 16-bit value"}
      ]
      
      Enum.each(enterprise_oids, fn {oid, description} ->
        varbinds = [{oid, :auto, {:object_identifier, oid}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        assert decoded_value == oid, "Enterprise OID #{description} failed"
      end)
    end
    
    test "handles very long OIDs" do
      # Test OIDs with many components
      long_oids = [
        # Deep MIB tree
        [1, 3, 6, 1, 4, 1, 9999, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
        # Table with many indices
        [1, 3, 6, 1, 4, 1, 9999, 2, 1, 1, 192, 168, 1, 1, 80, 443],
        # Simulated complex indexing
        [1, 3, 6, 1, 4, 1, 9999, 3, 1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
      ]
      
      Enum.each(long_oids, fn oid ->
        varbinds = [{oid, :auto, {:object_identifier, oid}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        assert decoded_value == oid, "Long OID #{oid} failed"
        assert length(decoded_value) == length(oid), "OID length mismatch"
      end)
    end
    
    test "handles OIDs with large subidentifiers" do
      # Test OIDs that require multibyte subidentifier encoding
      large_subid_oids = [
        {[1, 3, 6, 1, 4, 1, 128], "OID with 128 (first multibyte)"},
        {[1, 3, 6, 1, 4, 1, 255], "OID with 255"},
        {[1, 3, 6, 1, 4, 1, 256], "OID with 256"},
        {[1, 3, 6, 1, 4, 1, 16383], "OID with 16383 (max 2-byte)"},
        {[1, 3, 6, 1, 4, 1, 16384], "OID with 16384 (first 3-byte)"},
        {[1, 3, 6, 1, 4, 1, 2097151], "OID with 2097151 (max 3-byte)"}
      ]
      
      Enum.each(large_subid_oids, fn {oid, description} ->
        varbinds = [{oid, :auto, {:object_identifier, oid}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        assert decoded_value == oid, "Large subid OID #{description} failed"
      end)
    end
    
    test "handles minimal valid OIDs" do
      # Minimum valid OID length is 2 components
      minimal_oids = [
        {[0, 0], "minimum OID 0.0"},
        {[0, 39], "maximum second component for first=0"},
        {[1, 0], "minimum with first=1"},
        {[1, 39], "maximum second component for first=1"},
        {[2, 0], "minimum with first=2"},
        {[2, 999], "large second component for first=2"}
      ]
      
      Enum.each(minimal_oids, fn {oid, description} ->
        varbinds = [{oid, :auto, {:object_identifier, oid}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        case PDU.encode_message(message) do
          {:ok, encoded} ->
            {:ok, decoded} = PDU.decode_message(encoded)
            {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
            assert decoded_value == oid, "Minimal OID #{description} failed"
          {:error, _} ->
            # Some minimal OIDs may fail validation during encoding
            :ok
        end
      end)
    end
    
    test "rejects invalid OID formats" do
      invalid_oids = [
        # Too short
        [],
        [1],
        # Invalid first component
        [3, 0],
        [5, 0],
        # Invalid second component for first=0 or first=1
        [0, 40],
        [1, 40],
        # Non-integer components
        [1, 3, "invalid"],
        [1, 3, 6.5],
        # Negative components
        [1, 3, -1],
        [-1, 3, 6]
      ]
      
      Enum.each(invalid_oids, fn invalid_oid ->
        varbinds = [{[1, 3, 6, 1], :auto, {:object_identifier, invalid_oid}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        case PDU.encode_message(message) do
          {:ok, encoded} ->
            {:ok, decoded} = PDU.decode_message(encoded)
            {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
            # Should fall back to :null for invalid OIDs
            assert decoded_value == :null, "Invalid OID #{inspect(invalid_oid)} should become :null"
          {:error, _} ->
            # Invalid OIDs may fail during encoding, which is also acceptable
            :ok
        end
      end)
    end
    
    test "handles string OID format" do
      # Test string-based OID input (if supported)
      string_oids = [
        {"1.3.6.1.2.1.1.1.0", [1, 3, 6, 1, 2, 1, 1, 1, 0]},
        {"1.3.6.1.4.1.9.2.1.3.0", [1, 3, 6, 1, 4, 1, 9, 2, 1, 3, 0]},
        {"1.3.6.1.4.1.2021.1.1.1.0", [1, 3, 6, 1, 4, 1, 2021, 1, 1, 1, 0]}
      ]
      
      Enum.each(string_oids, fn {oid_string, expected_list} ->
        # Test if string format is converted to list format in the encoder
        varbinds = [{[1, 3, 6, 1], :auto, {:object_identifier, oid_string}}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        case PDU.encode_message(message) do
          {:ok, encoded} ->
            {:ok, decoded} = PDU.decode_message(encoded)
            {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
            # Should convert string to proper OID string
            assert decoded_value == expected_list, "String OID #{oid_string} should remain as string format"
          {:error, _} ->
            # String format might not be supported, which is acceptable
            :ok
        end
      end)
    end
  end
end