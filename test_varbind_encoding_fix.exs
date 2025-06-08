#!/usr/bin/env elixir

# Load the Mix project
Mix.install([{:snmp_lib, path: "."}])

# Test script to verify the varbind encoding/decoding fix

alias SnmpLib.PDU

IO.puts("Testing SnmpLib Varbind Encoding/Decoding Fix")
IO.puts("=" |> String.duplicate(50))

# Test 1: String values (octet_string)
IO.puts("\n1. Testing string values with :octet_string type:")
response_pdu = %{
  type: :get_response,
  request_id: 12345,
  varbinds: [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :octet_string, "Test String"}],
  error_status: 0,
  error_index: 0
}

message = PDU.build_message(response_pdu, "public", :v1)
{:ok, encoded} = PDU.encode_message(message)
{:ok, decoded} = PDU.decode_message(encoded)

IO.puts("Original varbind: #{inspect(response_pdu.varbinds)}")
IO.puts("Decoded varbind:  #{inspect(decoded.pdu.varbinds)}")
IO.puts("Match: #{decoded.pdu.varbinds == response_pdu.varbinds}")

# Test 2: Integer values
IO.puts("\n2. Testing integer values:")
response_pdu2 = %{
  type: :get_response,
  request_id: 12346,
  varbinds: [{[1, 3, 6, 1, 2, 1, 1, 3, 0], :integer, 42}],
  error_status: 0,
  error_index: 0
}

message2 = PDU.build_message(response_pdu2, "public", :v2c)
{:ok, encoded2} = PDU.encode_message(message2)
{:ok, decoded2} = PDU.decode_message(encoded2)

IO.puts("Original varbind: #{inspect(response_pdu2.varbinds)}")
IO.puts("Decoded varbind:  #{inspect(decoded2.pdu.varbinds)}")
IO.puts("Match: #{decoded2.pdu.varbinds == response_pdu2.varbinds}")

# Test 3: Counter32 values
IO.puts("\n3. Testing counter32 values:")
response_pdu3 = %{
  type: :get_response,
  request_id: 12347,
  varbinds: [{[1, 3, 6, 1, 2, 1, 2, 2, 1, 10, 1], :counter32, 999}],
  error_status: 0,
  error_index: 0
}

message3 = PDU.build_message(response_pdu3, "public", :v1)
{:ok, encoded3} = PDU.encode_message(message3)
{:ok, decoded3} = PDU.decode_message(encoded3)

IO.puts("Original varbind: #{inspect(response_pdu3.varbinds)}")
IO.puts("Decoded varbind:  #{inspect(decoded3.pdu.varbinds)}")
IO.puts("Match: #{decoded3.pdu.varbinds == response_pdu3.varbinds}")

# Test 4: Timeticks values
IO.puts("\n4. Testing timeticks values:")
response_pdu4 = %{
  type: :get_response,
  request_id: 12348,
  varbinds: [{[1, 3, 6, 1, 2, 1, 1, 3, 0], :timeticks, 123456}],
  error_status: 0,
  error_index: 0
}

message4 = PDU.build_message(response_pdu4, "public", :v2c)
{:ok, encoded4} = PDU.encode_message(message4)
{:ok, decoded4} = PDU.decode_message(encoded4)

IO.puts("Original varbind: #{inspect(response_pdu4.varbinds)}")
IO.puts("Decoded varbind:  #{inspect(decoded4.pdu.varbinds)}")
IO.puts("Match: #{decoded4.pdu.varbinds == response_pdu4.varbinds}")

# Test 5: Multiple varbinds with different types
IO.puts("\n5. Testing multiple varbinds with different types:")
response_pdu5 = %{
  type: :get_response,
  request_id: 12349,
  varbinds: [
    {[1, 3, 6, 1, 2, 1, 1, 1, 0], :octet_string, "Linux server"},
    {[1, 3, 6, 1, 2, 1, 1, 3, 0], :timeticks, 86400},
    {[1, 3, 6, 1, 2, 1, 2, 2, 1, 10, 1], :counter32, 1000},
    {[1, 3, 6, 1, 2, 1, 1, 5, 0], :octet_string, "test.example.com"}
  ],
  error_status: 0,
  error_index: 0
}

message5 = PDU.build_message(response_pdu5, "public", :v1)
{:ok, encoded5} = PDU.encode_message(message5)
{:ok, decoded5} = PDU.decode_message(encoded5)

IO.puts("Original varbinds:")
for vb <- response_pdu5.varbinds do
  IO.puts("  #{inspect(vb)}")
end

IO.puts("Decoded varbinds:")
for vb <- decoded5.pdu.varbinds do
  IO.puts("  #{inspect(vb)}")
end

IO.puts("Match: #{decoded5.pdu.varbinds == response_pdu5.varbinds}")

# Test 6: Null values
IO.puts("\n6. Testing null values:")
response_pdu6 = %{
  type: :get_response,
  request_id: 12350,
  varbinds: [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :null, :null}],
  error_status: 0,
  error_index: 0
}

message6 = PDU.build_message(response_pdu6, "public", :v2c)
{:ok, encoded6} = PDU.encode_message(message6)
{:ok, decoded6} = PDU.decode_message(encoded6)

IO.puts("Original varbind: #{inspect(response_pdu6.varbinds)}")
IO.puts("Decoded varbind:  #{inspect(decoded6.pdu.varbinds)}")
IO.puts("Match: #{decoded6.pdu.varbinds == response_pdu6.varbinds}")

# Summary
IO.puts("\n" <> ("=" |> String.duplicate(50)))
IO.puts("Summary: All varbind types should now properly encode/decode with 3-tuple format")
IO.puts("The type information is preserved through the encode/decode cycle")
