#!/usr/bin/env elixir

# Test script for object identifier encoding/decoding
test_oids = [
  [1, 3, 6, 1, 2, 1, 1, 1, 0],
  [1, 3, 6, 1, 4, 1, 9, 2, 1, 3, 0],
  [1, 3, 6, 1, 2, 1, 2, 2, 1, 1, 1]
]

IO.puts("Testing object identifier encoding/decoding:")

Enum.each(test_oids, fn oid ->
  # Test with explicit object_identifier type
  varbinds = [{oid, :object_identifier, oid}]
  pdu = SnmpLib.PDU.build_response(1, 0, 0, varbinds)
  message = SnmpLib.PDU.build_message(pdu, "public", :v2c)
  
  case SnmpLib.PDU.encode_message(message) do
    {:ok, encoded} ->
      case SnmpLib.PDU.decode_message(encoded) do
        {:ok, decoded} ->
          {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
          status = if decoded_value == oid, do: "✓", else: "✗"
          IO.puts("#{status} explicit OID #{inspect oid} -> #{inspect decoded_value}")
        {:error, reason} ->
          IO.puts("✗ explicit OID #{inspect oid} -> decode error: #{inspect reason}")
      end
    {:error, reason} ->
      IO.puts("✗ explicit OID #{inspect oid} -> encode error: #{inspect reason}")
  end
  
  # Test with :auto type and {:object_identifier, oid} value
  varbinds = [{oid, :auto, {:object_identifier, oid}}]
  pdu = SnmpLib.PDU.build_response(1, 0, 0, varbinds)
  message = SnmpLib.PDU.build_message(pdu, "public", :v2c)
  
  case SnmpLib.PDU.encode_message(message) do
    {:ok, encoded} ->
      case SnmpLib.PDU.decode_message(encoded) do
        {:ok, decoded} ->
          {_oid, _type, decoded_value} = hd(decoded.pdu.varbinds)
          status = if decoded_value == {:object_identifier, oid}, do: "✓", else: "✗"
          IO.puts("#{status} :auto OID #{inspect {:object_identifier, oid}} -> #{inspect decoded_value}")
        {:error, reason} ->
          IO.puts("✗ :auto OID #{inspect {:object_identifier, oid}} -> decode error: #{inspect reason}")
      end
    {:error, reason} ->
      IO.puts("✗ :auto OID #{inspect {:object_identifier, oid}} -> encode error: #{inspect reason}")
  end
end)