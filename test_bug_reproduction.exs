#!/usr/bin/env elixir

# Bug reproduction test for varbind encoding/decoding issues

Mix.install([{:snmp_lib, path: "."}])

defmodule BugReproduction do
  def test_object_identifier_string_bug do
    IO.puts("=== Testing Object Identifier String Bug ===")
    
    # Test case 1: Object identifier with string value (BUG)
    varbind = {[1, 3, 6, 1, 2, 1, 1, 2, 0], :object_identifier, "SNMPv2-SMI::enterprises.4491.2.4.1"}
    
    pdu = %{
      type: :get_response,
      request_id: 12345,
      varbinds: [varbind],
      error_status: 0,
      error_index: 0
    }
    
    # Build and encode message
    message = SnmpLib.PDU.build_message(pdu, "public", :v2c)
    {:ok, encoded} = SnmpLib.PDU.encode_message(message)
    
    # Decode message
    {:ok, decoded} = SnmpLib.PDU.decode_message(encoded)
    
    IO.puts("Original varbind: #{inspect(pdu.varbinds)}")
    IO.puts("Decoded varbind:  #{inspect(decoded.pdu.varbinds)}")
    
    # Check if they match
    original_varbind = hd(pdu.varbinds)
    decoded_varbind = hd(decoded.pdu.varbinds)
    
    if original_varbind == decoded_varbind do
      IO.puts("✅ PASS: Varbinds match")
    else
      IO.puts("❌ FAIL: Varbinds don't match")
      IO.puts("  Expected type: #{elem(original_varbind, 1)}")
      IO.puts("  Actual type:   #{elem(decoded_varbind, 1)}")
      IO.puts("  Expected value: #{inspect(elem(original_varbind, 2))}")
      IO.puts("  Actual value:   #{inspect(elem(decoded_varbind, 2))}")
    end
    
    IO.puts("")
  end
  
  def test_object_identifier_list_working do
    IO.puts("=== Testing Object Identifier List (Working) ===")
    
    # Test case 2: Object identifier with OID list (WORKING)
    varbind = {[1, 3, 6, 1, 2, 1, 1, 2, 0], :object_identifier, [1, 3, 6, 1, 4, 1, 4491, 2, 4, 1]}
    
    pdu = %{
      type: :get_response,
      request_id: 12345,
      varbinds: [varbind],
      error_status: 0,
      error_index: 0
    }
    
    # Build and encode message
    message = SnmpLib.PDU.build_message(pdu, "public", :v2c)
    {:ok, encoded} = SnmpLib.PDU.encode_message(message)
    
    # Decode message
    {:ok, decoded} = SnmpLib.PDU.decode_message(encoded)
    
    IO.puts("Original varbind: #{inspect(pdu.varbinds)}")
    IO.puts("Decoded varbind:  #{inspect(decoded.pdu.varbinds)}")
    
    # Check if they match
    original_varbind = hd(pdu.varbinds)
    decoded_varbind = hd(decoded.pdu.varbinds)
    
    if original_varbind == decoded_varbind do
      IO.puts("✅ PASS: Varbinds match")
    else
      IO.puts("❌ FAIL: Varbinds don't match")
    end
    
    IO.puts("")
  end
  
  def test_end_of_mib_view_bug do
    IO.puts("=== Testing End of MIB View Bug ===")
    
    # Test case 3: End of MIB view with tuple value (BUG)
    varbind = {[1, 3, 6, 1, 2, 1, 99, 99, 0], :end_of_mib_view, {:end_of_mib_view, nil}}
    
    pdu = %{
      type: :get_response,
      request_id: 12345,
      varbinds: [varbind],
      error_status: 0,
      error_index: 0
    }
    
    # Build and encode message
    message = SnmpLib.PDU.build_message(pdu, "public", :v2c)
    {:ok, encoded} = SnmpLib.PDU.encode_message(message)
    
    # Decode message
    {:ok, decoded} = SnmpLib.PDU.decode_message(encoded)
    
    IO.puts("Original varbind: #{inspect(pdu.varbinds)}")
    IO.puts("Decoded varbind:  #{inspect(decoded.pdu.varbinds)}")
    
    # Check if they match
    original_varbind = hd(pdu.varbinds)
    decoded_varbind = hd(decoded.pdu.varbinds)
    
    if original_varbind == decoded_varbind do
      IO.puts("✅ PASS: Varbinds match")
    else
      IO.puts("❌ FAIL: Varbinds don't match")
      IO.puts("  Expected value: #{inspect(elem(original_varbind, 2))}")
      IO.puts("  Actual value:   #{inspect(elem(decoded_varbind, 2))}")
    end
    
    IO.puts("")
  end
  
  def test_end_of_mib_view_working do
    IO.puts("=== Testing End of MIB View (Working) ===")
    
    # Test case 4: End of MIB view with nil value (WORKING)
    varbind = {[1, 3, 6, 1, 2, 1, 99, 99, 0], :end_of_mib_view, nil}
    
    pdu = %{
      type: :get_response,
      request_id: 12345,
      varbinds: [varbind],
      error_status: 0,
      error_index: 0
    }
    
    # Build and encode message
    message = SnmpLib.PDU.build_message(pdu, "public", :v2c)
    {:ok, encoded} = SnmpLib.PDU.encode_message(message)
    
    # Decode message
    {:ok, decoded} = SnmpLib.PDU.decode_message(encoded)
    
    IO.puts("Original varbind: #{inspect(pdu.varbinds)}")
    IO.puts("Decoded varbind:  #{inspect(decoded.pdu.varbinds)}")
    
    # Check if they match
    original_varbind = hd(pdu.varbinds)
    decoded_varbind = hd(decoded.pdu.varbinds)
    
    if original_varbind == decoded_varbind do
      IO.puts("✅ PASS: Varbinds match")
    else
      IO.puts("❌ FAIL: Varbinds don't match")
    end
    
    IO.puts("")
  end
  
  def run_all_tests do
    test_object_identifier_string_bug()
    test_object_identifier_list_working()
    test_end_of_mib_view_bug()
    test_end_of_mib_view_working()
  end
end

BugReproduction.run_all_tests()
