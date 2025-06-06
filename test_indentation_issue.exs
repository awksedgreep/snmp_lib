#!/usr/bin/env elixir

# Test if excessive indentation in comments causes issues

test_normal_indent = """
TEST-MIB DEFINITIONS ::= BEGIN

IMPORTS
    TEXTUAL-CONVENTION  FROM SNMPv2-TC;

TestType ::= TEXTUAL-CONVENTION
    STATUS      current
    DESCRIPTION "Test"
    SYNTAX      INTEGER {
                    basicISDN(20),     -- no longer used
                                       -- see also RFC2127
                    primaryISDN(21),   -- no longer used
                                       -- see also RFC2127
                    item3(22)
                }

END
"""

test_excessive_indent = """
TEST-MIB DEFINITIONS ::= BEGIN

IMPORTS
    TEXTUAL-CONVENTION  FROM SNMPv2-TC;

TestType ::= TEXTUAL-CONVENTION
    STATUS      current
    DESCRIPTION "Test"
    SYNTAX      INTEGER {
                    basicISDN(20),              -- no longer used
                                               -- see also RFC2127
                    primaryISDN(21),            -- no longer used
                                               -- see also RFC2127
                    item3(22)
                }

END
"""

# Test with exact spacing from the file
test_exact_spacing = """
TEST-MIB DEFINITIONS ::= BEGIN

IMPORTS
    TEXTUAL-CONVENTION  FROM SNMPv2-TC;

TestType ::= TEXTUAL-CONVENTION
    STATUS      current
    DESCRIPTION "Test"
    SYNTAX      INTEGER {
                   basicISDN(20),              -- no longer used
                                               -- see also RFC2127
                   primaryISDN(21),            -- no longer used
                                               -- see also RFC2127
                   propPointToPointSerial(22), -- proprietary serial
                   ppp(23),
                   softwareLoopback(24),
                   eon(25),            -- CLNP over IP 
                   ethernet3Mbit(26),
                   nsip(27)           -- XNS over IP
                }

END
"""

IO.puts("Testing normal indentation:")
case SnmpLib.MIB.Parser.parse(test_normal_indent) do
  {:ok, _} -> IO.puts("✓ SUCCESS")
  {:error, e} -> IO.puts("✗ FAILED: #{inspect(e)}")
end

IO.puts("\nTesting excessive indentation:")
case SnmpLib.MIB.Parser.parse(test_excessive_indent) do
  {:ok, _} -> IO.puts("✓ SUCCESS")
  {:error, e} -> IO.puts("✗ FAILED: #{inspect(e)}")
end

IO.puts("\nTesting exact spacing from file:")
case SnmpLib.MIB.Parser.parse(test_exact_spacing) do
  {:ok, _} -> IO.puts("✓ SUCCESS")
  {:error, e} -> IO.puts("✗ FAILED: #{inspect(e)}")
end