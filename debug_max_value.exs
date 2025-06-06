#!/usr/bin/env elixir

Mix.install([{:snmp_lib, path: "."}])

alias SnmpLib.PDU

IO.puts("Testing maximum Counter32/Gauge32 value: 4294967295")

# Test the maximum value
max_value = 4294967295

IO.puts("Max value: #{max_value}")
IO.puts("Max value hex: #{Integer.to_string(max_value, 16)}")
IO.puts("Max value binary: #{inspect(:binary.encode_unsigned(max_value, :big))}")

# Test Counter32 with max value
pdu = PDU.build_response(1, 0, 0, [{[1,3,6,1,2,1,2,2,1,10,1], :counter32, max_value}])
msg = PDU.build_message(pdu, "public", :v1)
{:ok, encoded} = PDU.encode_message(msg)
hex = Base.encode16(encoded)

IO.puts("Encoded: #{hex}")

# Check if it contains NULL
if String.contains?(hex, "0500") do
  IO.puts("❌ Contains NULL encoding!")
else
  IO.puts("✅ Proper encoding")
end

# Test a smaller value for comparison
smaller_value = 1000000
pdu2 = PDU.build_response(1, 0, 0, [{[1,3,6,1,2,1,2,2,1,10,1], :counter32, smaller_value}])
msg2 = PDU.build_message(pdu2, "public", :v1)
{:ok, encoded2} = PDU.encode_message(msg2)
hex2 = Base.encode16(encoded2)

IO.puts("Smaller value (#{smaller_value}): #{hex2}")
