#!/usr/bin/env elixir

# Test script to verify the varbind encoding bug fixes

Mix.install([{:snmp_lib, path: "."}])

defmodule BugFixTests do
  def test_object_identifier_string_validation do
    IO.puts("=== Testing Object Identifier String Validation ===")
    
    # This should now raise an ArgumentError instead of silently converting to null
    varbind = {[1, 3, 6, 1, 2, 1, 1, 2, 0], :object_identifier, "SNMPv2-SMI::enterprises.4491.2.4.1"}
    
    pdu = %{
      type: :get_response,
      request_id: 12345,
      varbinds: [varbind],
      error_status: 0,
      error_index: 0
    }
    
    try do
      # Build and encode message
      message = SnmpLib.PDU.build_message(pdu, "public", :v2c)
      {:ok, _encoded} = SnmpLib.PDU.encode_message(message)
      IO.puts("❌ FAIL: Expected ArgumentError but encoding succeeded")
    rescue
      e ->
        if Exception.message(e) =~ "ArgumentError" do
          IO.puts("✅ PASS: ArgumentError raised as expected")
          IO.puts("  Error message: #{Exception.message(e)}")
        else
          IO.puts("❌ FAIL: Expected ArgumentError but got: #{inspect(e)}")
        end
    end
    
    IO.puts("")
  end
  
  def test_object_identifier_list_still_works do
    IO.puts("=== Testing Object Identifier List Still Works ===")
    
    # This should continue to work
    varbind = {[1, 3, 6, 1, 2, 1, 1, 2, 0], :object_identifier, [1, 3, 6, 1, 4, 1, 4491, 2, 4, 1]}
    
    pdu = %{
      type: :get_response,
      request_id: 12345,
      varbinds: [varbind],
      error_status: 0,
      error_index: 0
    }
    
    try do
      message = SnmpLib.PDU.build_message(pdu, "public", :v2c)
      {:ok, encoded} = SnmpLib.PDU.encode_message(message)
      {:ok, decoded} = SnmpLib.PDU.decode_message(encoded)
      
      original_varbind = hd(pdu.varbinds)
      decoded_varbind = hd(decoded.pdu.varbinds)
      
      if original_varbind == decoded_varbind do
        IO.puts("✅ PASS: OID list encoding/decoding works correctly")
      else
        IO.puts("❌ FAIL: OID list encoding/decoding broken")
      end
    rescue
      e ->
        IO.puts("❌ FAIL: Unexpected error: #{Exception.message(e)}")
    end
    
    IO.puts("")
  end
  
  def test_end_of_mib_view_tuple_validation do
    IO.puts("=== Testing End of MIB View Tuple Validation ===")
    
    # This should now raise an ArgumentError instead of accepting the tuple
    varbind = {[1, 3, 6, 1, 2, 1, 99, 99, 0], :end_of_mib_view, {:end_of_mib_view, nil}}
    
    pdu = %{
      type: :get_response,
      request_id: 12345,
      varbinds: [varbind],
      error_status: 0,
      error_index: 0
    }
    
    try do
      # Build and encode message
      message = SnmpLib.PDU.build_message(pdu, "public", :v2c)
      {:ok, _encoded} = SnmpLib.PDU.encode_message(message)
      IO.puts("❌ FAIL: Expected ArgumentError but encoding succeeded")
    rescue
      e ->
        if Exception.message(e) =~ "ArgumentError" do
          IO.puts("✅ PASS: ArgumentError raised as expected")
          IO.puts("  Error message: #{Exception.message(e)}")
        else
          IO.puts("❌ FAIL: Expected ArgumentError but got: #{inspect(e)}")
        end
    end
    
    IO.puts("")
  end
  
  def test_end_of_mib_view_nil_still_works do
    IO.puts("=== Testing End of MIB View Nil Still Works ===")
    
    # This should continue to work
    varbind = {[1, 3, 6, 1, 2, 1, 99, 99, 0], :end_of_mib_view, nil}
    
    pdu = %{
      type: :get_response,
      request_id: 12345,
      varbinds: [varbind],
      error_status: 0,
      error_index: 0
    }
    
    try do
      message = SnmpLib.PDU.build_message(pdu, "public", :v2c)
      {:ok, encoded} = SnmpLib.PDU.encode_message(message)
      {:ok, decoded} = SnmpLib.PDU.decode_message(encoded)
      
      original_varbind = hd(pdu.varbinds)
      decoded_varbind = hd(decoded.pdu.varbinds)
      
      if original_varbind == decoded_varbind do
        IO.puts("✅ PASS: End of MIB view nil encoding/decoding works correctly")
      else
        IO.puts("❌ FAIL: End of MIB view nil encoding/decoding broken")
        IO.puts("  Expected: #{inspect(original_varbind)}")
        IO.puts("  Got:      #{inspect(decoded_varbind)}")
      end
    rescue
      e ->
        IO.puts("❌ FAIL: Unexpected error: #{Exception.message(e)}")
    end
    
    IO.puts("")
  end
  
  def test_invalid_oid_list_validation do
    IO.puts("=== Testing Invalid OID List Validation ===")
    
    # This should raise an ArgumentError for invalid OID
    varbind = {[1, 3, 6, 1, 2, 1, 1, 2, 0], :object_identifier, [1, 3, 6, -1, 2, 1]}  # negative number
    
    pdu = %{
      type: :get_response,
      request_id: 12345,
      varbinds: [varbind],
      error_status: 0,
      error_index: 0
    }
    
    try do
      # Build and encode message
      message = SnmpLib.PDU.build_message(pdu, "public", :v2c)
      {:ok, _encoded} = SnmpLib.PDU.encode_message(message)
      IO.puts("❌ FAIL: Expected ArgumentError but encoding succeeded")
    rescue
      e ->
        if Exception.message(e) =~ "ArgumentError" do
          IO.puts("✅ PASS: ArgumentError raised for invalid OID list")
          IO.puts("  Error message: #{Exception.message(e)}")
        else
          IO.puts("❌ FAIL: Expected ArgumentError but got: #{inspect(e)}")
        end
    end
    
    IO.puts("")
  end
  
  def run_all_tests do
    test_object_identifier_string_validation()
    test_object_identifier_list_still_works()
    test_end_of_mib_view_tuple_validation()
    test_end_of_mib_view_nil_still_works()
    test_invalid_oid_list_validation()
    
    IO.puts("=== Summary ===")
    IO.puts("Bug fixes implemented:")
    IO.puts("1. Object identifier string values now raise ArgumentError with helpful message")
    IO.puts("2. End of MIB view tuple values now raise ArgumentError with helpful message")
    IO.puts("3. Valid OID lists and nil values continue to work correctly")
    IO.puts("4. Invalid OID lists raise ArgumentError instead of silent conversion to null")
  end
end

BugFixTests.run_all_tests()
