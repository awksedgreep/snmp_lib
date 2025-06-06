#!/usr/bin/env elixir

# Simple test for the 209 issue

simple_100 = """
TEST-MIB DEFINITIONS ::= BEGIN

testObject OBJECT-TYPE
    SYNTAX      BITS {
                    test(100)
                }
    MAX-ACCESS  read-create
    STATUS      current
    DESCRIPTION "Test"
    ::= { 1 2 3 }

END
"""

simple_200 = """
TEST-MIB DEFINITIONS ::= BEGIN

testObject OBJECT-TYPE
    SYNTAX      BITS {
                    test(200)
                }
    MAX-ACCESS  read-create
    STATUS      current
    DESCRIPTION "Test"
    ::= { 1 2 3 }

END
"""

simple_209 = """
TEST-MIB DEFINITIONS ::= BEGIN

testObject OBJECT-TYPE
    SYNTAX      BITS {
                    test(209)
                }
    MAX-ACCESS  read-create
    STATUS      current
    DESCRIPTION "Test"
    ::= { 1 2 3 }

END
"""

IO.puts("Testing BITS with value 100:")
case SnmpLib.MIB.Parser.parse(simple_100) do
  {:ok, _} -> IO.puts("✓ SUCCESS")
  {:error, e} -> IO.puts("✗ FAILED: #{inspect(e)}")
end

IO.puts("\nTesting BITS with value 200:")
case SnmpLib.MIB.Parser.parse(simple_200) do
  {:ok, _} -> IO.puts("✓ SUCCESS")
  {:error, e} -> IO.puts("✗ FAILED: #{inspect(e)}")
end

IO.puts("\nTesting BITS with value 209:")
case SnmpLib.MIB.Parser.parse(simple_209) do
  {:ok, _} -> IO.puts("✓ SUCCESS")
  {:error, e} -> IO.puts("✗ FAILED: #{inspect(e)}")
end