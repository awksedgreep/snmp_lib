#!/usr/bin/env elixir

# Test different theories about enumeration parsing issues

# Test 1: Comments in enumerations
with_comments = """
TEST-MIB DEFINITIONS ::= BEGIN

IMPORTS
    TEXTUAL-CONVENTION  FROM SNMPv2-TC;

TestType ::= TEXTUAL-CONVENTION
    STATUS      current
    DESCRIPTION "Test"
    SYNTAX      INTEGER {
                    item1(1),   -- comment here
                    item2(2),   -- another comment
                    item3(3)    -- final comment
                }

END
"""

# Test 2: No comments in enumerations
without_comments = """
TEST-MIB DEFINITIONS ::= BEGIN

IMPORTS
    TEXTUAL-CONVENTION  FROM SNMPv2-TC;

TestType ::= TEXTUAL-CONVENTION
    STATUS      current
    DESCRIPTION "Test"
    SYNTAX      INTEGER {
                    item1(1),
                    item2(2),
                    item3(3)
                }

END
"""

# Test 3: Longer enumeration without comments
long_no_comments = """
TEST-MIB DEFINITIONS ::= BEGIN

IMPORTS
    TEXTUAL-CONVENTION  FROM SNMPv2-TC;

TestType ::= TEXTUAL-CONVENTION
    STATUS      current
    DESCRIPTION "Test"
    SYNTAX      INTEGER {
                    item1(1),
                    item2(2),
                    item3(3),
                    item4(4),
                    item5(5),
                    item6(6),
                    item7(7),
                    item8(8),
                    item9(9),
                    item10(10),
                    item11(11),
                    item12(12),
                    item13(13),
                    item14(14),
                    item15(15),
                    item16(16),
                    item17(17),
                    item18(18),
                    item19(19)
                }

END
"""

IO.puts("Test 1: With comments in enumeration")
case SnmpLib.MIB.Parser.parse(with_comments) do
  {:ok, _} -> IO.puts("✓ SUCCESS")
  {:error, e} -> IO.puts("✗ FAILED: #{inspect(e)}")
end

IO.puts("\nTest 2: Without comments in enumeration")
case SnmpLib.MIB.Parser.parse(without_comments) do
  {:ok, _} -> IO.puts("✓ SUCCESS")
  {:error, e} -> IO.puts("✗ FAILED: #{inspect(e)}")
end

IO.puts("\nTest 3: Long enumeration without comments")
case SnmpLib.MIB.Parser.parse(long_no_comments) do
  {:ok, _} -> IO.puts("✓ SUCCESS")
  {:error, e} -> IO.puts("✗ FAILED: #{inspect(e)}")
end