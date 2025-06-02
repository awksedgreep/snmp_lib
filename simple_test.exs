#!/usr/bin/env elixir

# Simple test to check module availability
Mix.install([])

# Load the application
Application.ensure_all_started(:snmp_lib)

# Try accessing the parser
try do
  case SnmpLib.MIB.Parser.parse("") do
    {:ok, result} -> IO.puts("✅ Parser available and working - empty result: #{inspect(result)}")
    {:error, errors} -> IO.puts("✅ Parser available - error as expected for empty input: #{inspect(errors)}")
  end
rescue
  e -> IO.puts("❌ Parser not available: #{Exception.message(e)}")
end

# Also test one simple MIB
test_mib = """
CLAB-DEF-MIB DEFINITIONS ::= BEGIN

IMPORTS
    enterprises
        FROM SNMPv2-SMI;

cableLabs  OBJECT IDENTIFIER ::= { enterprises 4491 }

END
"""

IO.puts("\n🔍 Testing simple MIB...")

try do
  case SnmpLib.MIB.Parser.parse(test_mib) do
    {:ok, mib} -> 
      IO.puts("✅ SUCCESS: Parsed simple MIB")
      IO.puts("   Name: #{mib.name}")
      IO.puts("   Imports: #{length(mib.imports)}")
      IO.puts("   Definitions: #{length(mib.definitions)}")
    {:error, errors} when is_list(errors) ->
      first_error = List.first(errors)
      IO.puts("❌ Parse error: #{inspect(first_error)}")
    {:error, error} ->
      IO.puts("❌ Parse error: #{inspect(error)}")
  end
rescue
  e -> IO.puts("❌ Exception: #{Exception.message(e)}")
end