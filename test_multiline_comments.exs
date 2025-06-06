#!/usr/bin/env elixir

# Test multi-line comments in enumerations

test_multiline_comments = """
TEST-MIB DEFINITIONS ::= BEGIN

IMPORTS
    TEXTUAL-CONVENTION  FROM SNMPv2-TC;

TestType ::= TEXTUAL-CONVENTION
    STATUS      current
    DESCRIPTION "Test"
    SYNTAX      INTEGER {
                    item1(1),          -- Single line comment
                    item2(2),          -- Comment line 1
                                       -- Comment line 2 continuation
                    item3(3),          -- Another single comment
                    item4(4)           -- Final comment
                }

END
"""

# Test with exact pattern from IANAifType
test_exact_pattern = """
TEST-MIB DEFINITIONS ::= BEGIN

IMPORTS
    TEXTUAL-CONVENTION  FROM SNMPv2-TC;

TestType ::= TEXTUAL-CONVENTION
    STATUS      current
    DESCRIPTION "Test"
    SYNTAX      INTEGER {
                    item1(9),
                    item2(10),
                    starLan(11), -- Deprecated via RFC3635
                                 -- ethernetCsmacd (6) should be used instead
                    proteon10Mbit(12),
                    proteon80Mbit(13)
                }

END
"""

IO.puts("Testing multi-line comments in enumeration:")
case SnmpLib.MIB.Parser.parse(test_multiline_comments) do
  {:ok, _} -> IO.puts("✓ SUCCESS")
  {:error, e} -> IO.puts("✗ FAILED: #{inspect(e)}")
end

IO.puts("\nTesting exact pattern from IANAifType:")
case SnmpLib.MIB.Parser.parse(test_exact_pattern) do
  {:ok, _} -> IO.puts("✓ SUCCESS")
  {:error, e} -> IO.puts("✗ FAILED: #{inspect(e)}")
end