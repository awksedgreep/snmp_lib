#!/usr/bin/env elixir

# Debug script to isolate the "Expected OID element, but found integer" error
# that's affecting DOCSIS MIBs

alias SnmpLib.MIB.{Lexer, Parser}

# Try to isolate the minimal case that reproduces the OID parsing error
simple_oid_test = """
TEST-MIB DEFINITIONS ::= BEGIN

IMPORTS
    OBJECT-TYPE
        FROM SNMPv2-SMI;

testObject OBJECT-TYPE
    SYNTAX      INTEGER
    ACCESS      read-only
    STATUS      current
    DESCRIPTION "Test object"
    ::= { 1 2 3 }

END
"""

# Test with a more realistic DOCSIS-like structure
realistic_oid_test = """
DOCS-CABLE-DEVICE-MIB DEFINITIONS ::= BEGIN

IMPORTS
    OBJECT-TYPE
        FROM SNMPv2-SMI
    enterprises
        FROM SNMPv2-SMI;

cableLabs OBJECT IDENTIFIER ::= { enterprises 4491 }
docsDevMIB OBJECT IDENTIFIER ::= { cableLabs 2 }
docsDevMIBObjects OBJECT IDENTIFIER ::= { docsDevMIB 1 }

docsDevBase OBJECT IDENTIFIER ::= { docsDevMIBObjects 1 }

docsDevRole OBJECT-TYPE
    SYNTAX      INTEGER
    ACCESS      read-only  
    STATUS      current
    DESCRIPTION "Cable device role"
    ::= { docsDevBase 1 }

END
"""

IO.puts("🔍 Testing simple OID structure...")

case Lexer.tokenize(simple_oid_test) do
  {:ok, tokens} ->
    IO.puts("✅ Simple OID tokenized successfully, #{length(tokens)} tokens")
    
    case Parser.parse_tokens(tokens) do
      {:ok, ast} ->
        IO.puts("✅ Simple OID parsed successfully!")
        IO.inspect(ast.definitions, label: "Definitions")
      {:error, errors} ->
        IO.puts("❌ Simple OID parsing failed: #{length(errors)} errors")
        Enum.each(errors, fn error ->
          IO.puts("     Error: #{SnmpLib.MIB.Error.format(error)}")
        end)
    end
  {:error, error} ->
    IO.puts("❌ Simple OID tokenization failed: #{inspect(error)}")
end

IO.puts("\n🔍 Testing realistic DOCSIS-like OID structure...")

case Lexer.tokenize(realistic_oid_test) do
  {:ok, tokens} ->
    IO.puts("✅ Realistic OID tokenized successfully, #{length(tokens)} tokens")
    
    # Show some tokens around potential problem areas
    IO.puts("\n📋 Sample tokens:")
    tokens
    |> Enum.with_index()
    |> Enum.take(30)
    |> Enum.each(fn {{type, value, pos}, idx} ->
      IO.puts("  #{idx}: #{type} = #{inspect(value)} (pos: #{inspect(pos)})")
    end)
    
    case Parser.parse_tokens(tokens) do
      {:ok, ast} ->
        IO.puts("✅ Realistic OID parsed successfully!")
        IO.inspect(ast.definitions, label: "Definitions")
      {:error, errors} ->
        IO.puts("❌ Realistic OID parsing failed: #{length(errors)} errors")
        Enum.each(errors, fn error ->
          IO.puts("     Error: #{SnmpLib.MIB.Error.format(error)}")
        end)
    end
  {:error, error} ->
    IO.puts("❌ Realistic OID tokenization failed: #{inspect(error)}")
end