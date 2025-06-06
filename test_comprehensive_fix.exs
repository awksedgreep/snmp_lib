#!/usr/bin/env elixir

# Comprehensive test to verify the Counter32/Gauge32 fix and other SNMP types

Mix.install([{:snmp_lib, path: "."}])

alias SnmpLib.PDU

IO.puts("Comprehensive SNMP Type Encoding Test")
IO.puts("=" <> String.duplicate("=", 40))

test_cases = [
  {:counter32, 1000000, "Counter32"},
  {:gauge32, 1000000, "Gauge32"}, 
  {:timeticks, 1000000, "TimeTicks"},
  {:counter64, 1000000, "Counter64"},
  {:integer, 1000000, "Integer"},
  {:string, "test", "String"}
]

Enum.each(test_cases, fn {type, value, name} ->
  IO.puts("\nTesting #{name} (#{type}):")
  
  try do
    pdu = PDU.build_response(1, 0, 0, [{[1,3,6,1,2,1,2,2,1,10,1], type, value}])
    msg = PDU.build_message(pdu, "public", :v1)
    {:ok, encoded} = PDU.encode_message(msg)
    hex = Base.encode16(encoded)
    
    # Extract the value encoding (last few bytes)
    value_encoding = String.slice(hex, -10, 10)
    IO.puts("  Encoded: #{hex}")
    IO.puts("  Value part: #{value_encoding}")
    
    # Check if it's NULL encoding (0500)
    if String.contains?(value_encoding, "0500") do
      IO.puts("  ❌ ERROR: NULL encoding detected!")
    else
      IO.puts("  ✅ SUCCESS: Proper encoding")
    end
  rescue
    e -> IO.puts("  ❌ ERROR: #{inspect(e)}")
  end
end)

IO.puts("\n" <> String.duplicate("=", 50))
IO.puts("Expected ASN.1 tags:")
IO.puts("- Counter32: 0x41")
IO.puts("- Gauge32: 0x42") 
IO.puts("- TimeTicks: 0x43")
IO.puts("- Counter64: 0x46")
IO.puts("- Integer: 0x02")
IO.puts("- String: 0x04")
IO.puts("- NULL (bug): 0x05")
