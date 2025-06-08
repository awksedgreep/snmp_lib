defmodule SnmpLib.ObjectIdentifierStringTest do
  use ExUnit.Case, async: true
  
  alias SnmpLib.PDU
  
  describe "Object Identifier string encoding/decoding" do
    test "encodes and decodes string OIDs with :auto type" do
      string_oids = [
        {"1.3.6.1.2.1.1.1.0", "sysDescr.0"},
        {"1.3.6.1.2.1.1.2.0", "sysObjectID.0"},
        {"1.3.6.1.2.1.1.3.0", "sysUpTime.0"},
        {"1.3.6.1.4.1.9.2.1.3.0", "Cisco enterprise OID"},
        {"1.3.6.1.4.1.2021.1.1.1.0", "Net-SNMP enterprise OID"},
        {"1.3.6.1.2.1.2.2.1.1.1", "ifIndex.1"}
      ]
      
      Enum.each(string_oids, fn {oid_string, description} ->
        test_value = {:object_identifier, oid_string}
        
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, test_value}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        expected_list = String.split(oid_string, ".") |> Enum.map(&String.to_integer/1)
        
        assert decoded_value == expected_list, 
          "String OID #{description} failed: expected #{inspect(expected_list)}, got #{inspect(decoded_value)}"
      end)
    end
    
    test "encodes and decodes string OIDs with explicit :object_identifier type" do
      string_oids = [
        {"1.3.6.1.2.1.1.1.0", "sysDescr.0"},
        {"1.3.6.1.2.1.1.2.0", "sysObjectID.0"},
        {"1.3.6.1.4.1.9.2.1.3.0", "Cisco enterprise OID"},
        {"1.3.6.1.4.1.2021.1.1.1.0", "Net-SNMP enterprise OID"},
        {"1.3.6.1.2.1.2.2.1.1.1", "ifIndex.1"}
      ]
      
      Enum.each(string_oids, fn {oid_string, description} ->
        
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :object_identifier, oid_string}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, decoded_type, decoded_value} = hd(decoded.pdu.varbinds)
        expected_list = String.split(oid_string, ".") |> Enum.map(&String.to_integer/1)
        
        assert decoded_type == :object_identifier
        assert decoded_value == expected_list, 
          "Explicit string OID #{description} failed: expected #{inspect(expected_list)}, got #{inspect(decoded_value)}"
      end)
    end
    
    test "handles large enterprise numbers correctly" do
      # Test specific cases that require multibyte subidentifier encoding
      large_enterprise_oids = [
        {"1.3.6.1.4.1.2021", [1, 3, 6, 1, 4, 1, 2021]},
        {"1.3.6.1.4.1.311", [1, 3, 6, 1, 4, 1, 311]},
        {"1.3.6.1.4.1.1000", [1, 3, 6, 1, 4, 1, 1000]},
        {"1.3.6.1.4.1.65535", [1, 3, 6, 1, 4, 1, 65535]}
      ]
      
      Enum.each(large_enterprise_oids, fn {oid_string, _expected_list} ->
        test_value = {:object_identifier, oid_string}
        
        varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, test_value}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        expected_list = String.split(oid_string, ".") |> Enum.map(&String.to_integer/1)
        
        assert decoded_value == expected_list, 
          "Large enterprise OID #{oid_string} failed: expected #{inspect(expected_list)}, got #{inspect(decoded_value)}"
      end)
    end
    
    test "rejects invalid string OID formats" do
      invalid_oids = [
        "",
        "1",
        "not.an.oid",
        "1.3.6.-1",
        "1..3.6",
        "1.3.6.",
        ".1.3.6"
      ]
      
      Enum.each(invalid_oids, fn invalid_oid ->
        test_value = {:object_identifier, invalid_oid}
        varbinds = [{[1, 3, 6, 1], :auto, test_value}]
        pdu = PDU.build_response(1, 0, 0, varbinds)
        message = PDU.build_message(pdu, "public", :v2c)
        
        {:ok, encoded} = PDU.encode_message(message)
        {:ok, decoded} = PDU.decode_message(encoded)
        
        {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
        # Should fall back to :null for invalid OIDs
        assert decoded_value == :null, 
          "Invalid OID string #{inspect(invalid_oid)} should become :null, got #{inspect(decoded_value)}"
      end)
    end
    
    test "preserves OID semantics across multiple encode/decode cycles" do
      test_oids = [
        "1.3.6.1.2.1.1.1.0",
        "1.3.6.1.4.1.2021.1.1.1.0", 
        "1.3.6.1.4.1.9.2.1.3.0"
      ]
      
      Enum.each(test_oids, fn oid_string ->
        test_value = {:object_identifier, oid_string}
        
        # First cycle
        varbinds1 = [{[1, 3, 6, 1], :auto, test_value}]
        pdu1 = PDU.build_response(1, 0, 0, varbinds1)
        message1 = PDU.build_message(pdu1, "public", :v2c)
        
        {:ok, encoded1} = PDU.encode_message(message1)
        {:ok, decoded1} = PDU.decode_message(encoded1)
        {_, _, value1} = hd(decoded1.pdu.varbinds)
        
        # Second cycle using result from first
        varbinds2 = [{[1, 3, 6, 1], :auto, value1}]
        pdu2 = PDU.build_response(2, 0, 0, varbinds2)
        message2 = PDU.build_message(pdu2, "public", :v2c)
        
        {:ok, encoded2} = PDU.encode_message(message2)
        {:ok, decoded2} = PDU.decode_message(encoded2)
        {_, _, value2} = hd(decoded2.pdu.varbinds)
        
        # Third cycle
        varbinds3 = [{[1, 3, 6, 1], :auto, value2}]
        pdu3 = PDU.build_response(3, 0, 0, varbinds3)
        message3 = PDU.build_message(pdu3, "public", :v2c)
        
        {:ok, encoded3} = PDU.encode_message(message3)
        {:ok, decoded3} = PDU.decode_message(encoded3)
        {_, _, value3} = hd(decoded3.pdu.varbinds)
        
        expected_list = String.split(oid_string, ".") |> Enum.map(&String.to_integer/1)
        assert value1 == expected_list, "First cycle failed for #{oid_string}"
        assert value2 == expected_list, "Second cycle failed for #{oid_string}" 
        assert value3 == expected_list, "Third cycle failed for #{oid_string}"
        assert value1 == value2, "Values differ between cycle 1 and 2 for #{oid_string}"
        assert value2 == value3, "Values differ between cycle 2 and 3 for #{oid_string}"
      end)
    end
  end
end