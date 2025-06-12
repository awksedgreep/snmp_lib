#!/usr/bin/env elixir

# Debug script to test Manager.get/3 return format
Mix.install([{:snmp_lib, path: "."}])

# Test with an invalid host to see the exact return format
result = SnmpLib.Manager.get("invalid.host.test", [1, 3, 6, 1, 2, 1, 1, 1, 0], timeout: 100)
IO.puts("Result: #{inspect(result)}")
IO.puts("Result type: #{inspect(elem(result, 0))}")

case result do
  {:ok, {type, value}} ->
    IO.puts("✅ Correct 2-tuple format: type=#{inspect(type)}, value=#{inspect(value)}")
  {:ok, {oid, type, value}} ->
    IO.puts("❌ Wrong 3-tuple format: oid=#{inspect(oid)}, type=#{inspect(type)}, value=#{inspect(value)}")
  {:error, reason} ->
    IO.puts("Expected error: #{inspect(reason)}")
  other ->
    IO.puts("Unexpected format: #{inspect(other)}")
end
