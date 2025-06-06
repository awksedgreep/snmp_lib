#!/usr/bin/env elixir

# Test MODULE-IDENTITY with many revisions followed by TEXTUAL-CONVENTION

test_mib = """
TEST-MIB DEFINITIONS ::= BEGIN

IMPORTS
    MODULE-IDENTITY     FROM SNMPv2-SMI
    TEXTUAL-CONVENTION  FROM SNMPv2-TC;

testMIB MODULE-IDENTITY
    LAST-UPDATED "202501010000Z"
    ORGANIZATION "Test"
    CONTACT-INFO "Test"
    DESCRIPTION "Test MIB"
    
    REVISION     "202401010000Z"
    DESCRIPTION  "Second revision"
    
    REVISION     "202301010000Z"
    DESCRIPTION  "First revision"
    ::= { 1 2 3 }

TestType ::= TEXTUAL-CONVENTION
    STATUS      current
    DESCRIPTION "Test type"
    SYNTAX      INTEGER {
                    item1(1),
                    item2(2)
                }

END
"""

IO.puts("Testing MODULE-IDENTITY with revisions followed by TEXTUAL-CONVENTION:")
case SnmpLib.MIB.Parser.parse(test_mib) do
  {:ok, result} -> 
    IO.puts("✓ SUCCESS")
    IO.puts("Definitions found: #{length(result.definitions)}")
  {:error, e} -> 
    IO.puts("✗ FAILED: #{inspect(e)}")
end