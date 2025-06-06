#!/usr/bin/env elixir

# Test simple BITS construct to see if the issue is really with large numbers

simple_mib = """
TEST-MIB DEFINITIONS ::= BEGIN

testObject OBJECT-TYPE
    SYNTAX      BITS {
                    d1(0),   d2(1),   d3(2),   d4(3),   d5(4),
                    d6(5),   d7(6),   d8(7),   d9(8),   d10(9),
                    d209(209),
                    d225(225)
                }
    MAX-ACCESS  read-create
    STATUS      current
    DESCRIPTION "Test"
    ::= { 1 2 3 }

END
"""

IO.puts("Testing simple BITS with large numbers...")

case SnmpLib.MIB.Parser.parse(simple_mib) do
  {:ok, result} ->
    IO.puts("✓ SUCCESS: Simple BITS with large numbers parsed correctly")
    IO.puts("Result: #{inspect(result, limit: :infinity)}")
  {:error, error} ->
    IO.puts("✗ FAILED: #{inspect(error)}")
end

# Test Counter type definition issue from RFC1155-SMI
counter_mib = """
TEST-COUNTER-MIB DEFINITIONS ::= BEGIN

Counter ::=
    [APPLICATION 1]
        IMPLICIT INTEGER (0..4294967295)

END
"""

IO.puts("\nTesting Counter type definition...")

case SnmpLib.MIB.Parser.parse(counter_mib) do
  {:ok, result} ->
    IO.puts("✓ SUCCESS: Counter type definition parsed correctly")
  {:error, error} ->
    IO.puts("✗ FAILED: #{inspect(error)}")
end