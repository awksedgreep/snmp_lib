#!/usr/bin/env elixir

# Test script to reproduce the Counter32 and Gauge32 encoding bug

Mix.install([{:snmp_lib, path: "."}])

alias SnmpLib.PDU

IO.puts("Testing Counter32 and Gauge32 encoding bug...")
IO.puts("=" <> String.duplicate("=", 50))

# Test Counter32 encoding
IO.puts("\n1. Testing Counter32 with tuple format:")
pdu1 = PDU.build_response(1, 0, 0, [{[1,3,6,1,2,1,2,2,1,10,1], :auto, {:counter32, 1000000}}])
msg1 = PDU.build_message(pdu1, "public", :v1)
{:ok, enc1} = PDU.encode_message(msg1)
IO.puts("Counter32 (tuple): #{Base.encode16(enc1)}")

# Test Counter32 with atom type (this should be the bug)
IO.puts("\n2. Testing Counter32 with atom type:")
pdu2 = PDU.build_response(1, 0, 0, [{[1,3,6,1,2,1,2,2,1,10,1], :counter32, 1000000}])
msg2 = PDU.build_message(pdu2, "public", :v1)
{:ok, enc2} = PDU.encode_message(msg2)
IO.puts("Counter32 (atom): #{Base.encode16(enc2)}")

# Test Gauge32 with tuple format
IO.puts("\n3. Testing Gauge32 with tuple format:")
pdu3 = PDU.build_response(1, 0, 0, [{[1,3,6,1,2,1,2,2,1,10,1], :auto, {:gauge32, 1000000}}])
msg3 = PDU.build_message(pdu3, "public", :v1)
{:ok, enc3} = PDU.encode_message(msg3)
IO.puts("Gauge32 (tuple): #{Base.encode16(enc3)}")

# Test Gauge32 with atom type (this should be the bug)
IO.puts("\n4. Testing Gauge32 with atom type:")
pdu4 = PDU.build_response(1, 0, 0, [{[1,3,6,1,2,1,2,2,1,10,1], :gauge32, 1000000}])
msg4 = PDU.build_message(pdu4, "public", :v1)
{:ok, enc4} = PDU.encode_message(msg4)
IO.puts("Gauge32 (atom): #{Base.encode16(enc4)}")

# Test Integer encoding (works correctly)
IO.puts("\n5. Testing Integer (should work):")
pdu5 = PDU.build_response(1, 0, 0, [{[1,3,6,1,2,1,2,2,1,10,1], :integer, 1000000}])
msg5 = PDU.build_message(pdu5, "public", :v1)
{:ok, enc5} = PDU.encode_message(msg5)
IO.puts("Integer: #{Base.encode16(enc5)}")

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("Analysis:")
IO.puts("- Counter32/Gauge32 with tuple format should work correctly")
IO.puts("- Counter32/Gauge32 with atom type should encode as NULL (bug)")
IO.puts("- Integer should work correctly")
IO.puts("- Look for '0500' (NULL encoding) vs proper integer encoding")
