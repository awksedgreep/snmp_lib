#!/usr/bin/env elixir

# Test script for complex type encoding/decoding
varbinds = [{[1,3,6,1,2,1,1,1,0], :auto, {:counter32, 12345}}]
pdu = SnmpLib.PDU.build_response(1, 0, 0, varbinds)
message = SnmpLib.PDU.build_message(pdu, "public", :v2c)
{:ok, encoded} = SnmpLib.PDU.encode_message(message)
{:ok, decoded} = SnmpLib.PDU.decode_message(encoded)
{oid, type, value} = hd(decoded.pdu.varbinds)

IO.puts("Original: {#{inspect oid}, :auto, {:counter32, 12345}}")
IO.puts("Decoded:  {#{inspect oid}, #{inspect type}, #{inspect value}}")

# Test all complex types
test_types = [
  {:counter32, 12345},
  {:gauge32, 67890},
  {:timeticks, 123456},
  {:counter64, 9876543210},
  {:ip_address, <<192, 168, 1, 1>>},
  {:opaque, <<1, 2, 3, 4>>},
  {:no_such_object, nil},
  {:no_such_instance, nil},
  {:end_of_mib_view, nil}
]

IO.puts("\nTesting all complex types:")

Enum.each(test_types, fn original_value ->
  varbinds = [{[1,3,6,1,2,1,1,1,0], :auto, original_value}]
  pdu = SnmpLib.PDU.build_response(1, 0, 0, varbinds)
  message = SnmpLib.PDU.build_message(pdu, "public", :v2c)
  
  case SnmpLib.PDU.encode_message(message) do
    {:ok, encoded} ->
      case SnmpLib.PDU.decode_message(encoded) do
        {:ok, decoded} ->
          {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
          status = if decoded_value == original_value, do: "✓", else: "✗"
          IO.puts("#{status} #{inspect original_value} -> #{inspect decoded_value}")
        {:error, reason} ->
          IO.puts("✗ #{inspect original_value} -> decode error: #{inspect reason}")
      end
    {:error, reason} ->
      IO.puts("✗ #{inspect original_value} -> encode error: #{inspect reason}")
  end
end)