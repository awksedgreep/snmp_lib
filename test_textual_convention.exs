#!/usr/bin/env elixir

# Test TEXTUAL-CONVENTION with INTEGER enumeration

simple_tc = """
TEST-MIB DEFINITIONS ::= BEGIN

MyType ::= TEXTUAL-CONVENTION
    STATUS      current
    DESCRIPTION "Test"
    SYNTAX      INTEGER {
                    item1(1),
                    item2(2)
                }

END
"""

simple_integer = """
TEST-MIB DEFINITIONS ::= BEGIN

testObject OBJECT-TYPE
    SYNTAX      INTEGER {
                    item1(1),
                    item2(2)
                }
    MAX-ACCESS  read-only
    STATUS      current
    DESCRIPTION "Test"
    ::= { 1 2 3 }

END
"""

IO.puts("Testing simple INTEGER enumeration in OBJECT-TYPE:")
case SnmpLib.MIB.Parser.parse(simple_integer) do
  {:ok, _} -> IO.puts("✓ SUCCESS")
  {:error, e} -> IO.puts("✗ FAILED: #{inspect(e)}")
end

IO.puts("\nTesting TEXTUAL-CONVENTION with INTEGER enumeration:")
case SnmpLib.MIB.Parser.parse(simple_tc) do
  {:ok, _} -> IO.puts("✓ SUCCESS")
  {:error, e} -> IO.puts("✗ FAILED: #{inspect(e)}")
end