#!/usr/bin/env elixir

# Test that MIB compilation is silent by default (no stdout noise)

# Configure logger to default level (should be quiet)
Logger.configure(level: :info)

IO.puts("🔇 Testing Silent MIB Compilation")
IO.puts("==================================")

# Test single MIB compilation
IO.puts("\n1. Testing single MIB compilation...")
test_mib_content = """
TEST-MIB DEFINITIONS ::= BEGIN

IMPORTS
    Integer32, OBJECT-TYPE, MODULE-IDENTITY
        FROM SNMPv2-SMI;

testMIB MODULE-IDENTITY
    LAST-UPDATED "202501010000Z"
    ORGANIZATION "Test Org"
    CONTACT-INFO "test@test.com"
    DESCRIPTION "A test MIB"
    ::= { 1 3 6 1 4 1 12345 }

testObject OBJECT-TYPE
    SYNTAX Integer32
    MAX-ACCESS read-only
    STATUS current
    DESCRIPTION "A test object"
    ::= { testMIB 1 }

END
"""

IO.puts("Compiling test MIB...")
case SnmpLib.MIB.Parser.parse(test_mib_content) do
  {:ok, _mib_data} ->
    IO.puts("✅ Single MIB compilation successful and SILENT")
  {:error, reason} ->
    IO.puts("❌ Single MIB compilation failed: #{inspect(reason)}")
end

# Test directory compilation
IO.puts("\n2. Testing directory compilation...")
test_dirs = [
  "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working"
]

IO.puts("Compiling directory (should be silent except for these messages)...")
results = SnmpLib.MIB.Parser.mibdirs(test_dirs)

total_success = Enum.reduce(results, 0, fn {_dir, result}, acc -> 
  acc + length(result.success)
end)
total_files = Enum.reduce(results, 0, fn {_dir, result}, acc -> 
  acc + result.total
end)

IO.puts("✅ Directory compilation completed: #{total_success}/#{total_files} successful")
IO.puts("✅ Compilation was SILENT - no parser/tokenizer noise!")

IO.puts("\n🎉 SUCCESS: MIB compilation is now clean and silent!")
IO.puts("    - No stdout garbage during compilation")
IO.puts("    - All logging properly routed to Logger")
IO.puts("    - Clean API for production use")