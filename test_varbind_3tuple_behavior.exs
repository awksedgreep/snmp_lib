#!/usr/bin/env elixir

# Load the Mix project
Mix.install([{:snmp_lib, path: "."}])

# Test script to document and verify the 3-tuple varbind behavior

alias SnmpLib.PDU

IO.puts """
Testing 3-Tuple Varbind Behavior
==================================================
This test demonstrates the standardized 3-tuple varbind format:
{oid, type, value}

Where:
- oid: The object identifier as a list of integers
- type: An atom representing the SNMP type (:octet_string, :integer, :counter32, etc.)
- value: The actual value (not wrapped in a tuple)
==================================================
"""

# Test 1: Encoding with explicit types
IO.puts "\n1. Encoding with explicit types (recommended):"
explicit_varbinds = [
  {[1, 3, 6, 1, 2, 1, 1, 1, 0], :octet_string, "Test String"},
  {[1, 3, 6, 1, 2, 1, 1, 3, 0], :timeticks, 123456},
  {[1, 3, 6, 1, 2, 1, 2, 2, 1, 10, 1], :counter32, 999},
  {[1, 3, 6, 1, 2, 1, 2, 2, 1, 16, 1], :counter64, 9876543210}
]

pdu = PDU.build_response(1, 0, 0, explicit_varbinds)
message = PDU.build_message(pdu, "public", :v2c)
{:ok, encoded} = PDU.encode_message(message)
{:ok, decoded} = PDU.decode_message(encoded)

IO.puts "Original varbinds:"
for vb <- explicit_varbinds, do: IO.puts "  #{inspect(vb)}"
IO.puts "Decoded varbinds:"
for vb <- decoded.pdu.varbinds, do: IO.puts "  #{inspect(vb)}"
IO.puts "Match: #{explicit_varbinds == decoded.pdu.varbinds}"

# Test 2: Encoding with :auto type and tuple values (backward compatibility)
IO.puts "\n2. Encoding with :auto type and tuple values:"
auto_tuple_varbinds = [
  {[1, 3, 6, 1, 2, 1, 1, 1, 0], :auto, "Test String"},
  {[1, 3, 6, 1, 2, 1, 1, 3, 0], :auto, {:timeticks, 123456}},
  {[1, 3, 6, 1, 2, 1, 2, 2, 1, 10, 1], :auto, {:counter32, 999}},
  {[1, 3, 6, 1, 2, 1, 2, 2, 1, 16, 1], :auto, {:counter64, 9876543210}}
]

pdu2 = PDU.build_response(2, 0, 0, auto_tuple_varbinds)
message2 = PDU.build_message(pdu2, "public", :v2c)
{:ok, encoded2} = PDU.encode_message(message2)
{:ok, decoded2} = PDU.decode_message(encoded2)

IO.puts "Original varbinds:"
for vb <- auto_tuple_varbinds, do: IO.puts "  #{inspect(vb)}"
IO.puts "Decoded varbinds (standardized to 3-tuple):"
for vb <- decoded2.pdu.varbinds, do: IO.puts "  #{inspect(vb)}"

# Test 3: Show the standardized format
IO.puts "\n3. Standardized 3-tuple format after decoding:"
expected_format = [
  {[1, 3, 6, 1, 2, 1, 1, 1, 0], :octet_string, "Test String"},
  {[1, 3, 6, 1, 2, 1, 1, 3, 0], :timeticks, 123456},
  {[1, 3, 6, 1, 2, 1, 2, 2, 1, 10, 1], :counter32, 999},
  {[1, 3, 6, 1, 2, 1, 2, 2, 1, 16, 1], :counter64, 9876543210}
]

IO.puts "Expected standardized format:"
for vb <- expected_format, do: IO.puts "  #{inspect(vb)}"
IO.puts "Actual decoded format:"
for vb <- decoded2.pdu.varbinds, do: IO.puts "  #{inspect(vb)}"
IO.puts "Match: #{expected_format == decoded2.pdu.varbinds}"

# Test 4: SNMPv2c exceptions
IO.puts "\n4. SNMPv2c exception values:"
exception_varbinds = [
  {[1, 3, 6, 1, 2, 1, 1, 1, 0], :no_such_object, nil},
  {[1, 3, 6, 1, 2, 1, 1, 2, 0], :no_such_instance, nil},
  {[1, 3, 6, 1, 2, 1, 1, 3, 0], :end_of_mib_view, nil}
]

pdu3 = PDU.build_response(3, 0, 0, exception_varbinds)
message3 = PDU.build_message(pdu3, "public", :v2c)
{:ok, encoded3} = PDU.encode_message(message3)
{:ok, decoded3} = PDU.decode_message(encoded3)

IO.puts "Original exception varbinds:"
for vb <- exception_varbinds, do: IO.puts "  #{inspect(vb)}"
IO.puts "Decoded exception varbinds:"
for vb <- decoded3.pdu.varbinds, do: IO.puts "  #{inspect(vb)}"
IO.puts "Match: #{exception_varbinds == decoded3.pdu.varbinds}"

IO.puts """

==================================================
Summary:
- All varbinds are standardized to 3-tuple format: {oid, type, value}
- The type is always an atom (:octet_string, :integer, :counter32, etc.)
- The value is the actual value, not wrapped in a tuple
- This format is consistent for both encoding and decoding
- :auto type with tuple values is supported for backward compatibility
==================================================
"""
