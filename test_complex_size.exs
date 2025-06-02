#!/usr/bin/env elixir

alias SnmpLib.MIB.{Lexer, ParserPort}

# Test very complex SIZE constraints to ensure robustness
complex_size_mib = """
TEST-MIB DEFINITIONS ::= BEGIN

testObject1 OBJECT-TYPE
    SYNTAX       OCTET STRING (SIZE (0 | 36..260))
    MAX-ACCESS   read-only
    STATUS       current
    DESCRIPTION  "Simple SIZE with single value and range"
    ::= { 1 2 3 }

testObject2 OBJECT-TYPE
    SYNTAX       OCTET STRING (SIZE (1..64 | 128 | 256..512))
    MAX-ACCESS   read-only
    STATUS       current
    DESCRIPTION  "Complex SIZE with range, single value, and another range"
    ::= { 1 2 4 }

testObject3 OBJECT-TYPE
    SYNTAX       OCTET STRING (SIZE (8 | 16 | 32 | 64))
    MAX-ACCESS   read-only
    STATUS       current
    DESCRIPTION  "Multiple single values"
    ::= { 1 2 5 }

testObject4 OBJECT-TYPE
    SYNTAX       OCTET STRING (SIZE (1..255))
    MAX-ACCESS   read-only
    STATUS       current
    DESCRIPTION  "Simple range"
    ::= { 1 2 6 }

testObject5 OBJECT-TYPE
    SYNTAX       OCTET STRING (SIZE (64))
    MAX-ACCESS   read-only
    STATUS       current
    DESCRIPTION  "Single value"
    ::= { 1 2 7 }

END
"""

IO.puts("🔍 Testing complex SIZE constraints...")

case Lexer.tokenize(complex_size_mib) do
  {:ok, tokens} ->
    IO.puts("✅ Complex MIB tokenized successfully, #{length(tokens)} tokens")
    
    case ParserPort.parse_tokens(tokens) do
      {:ok, mib} ->
        IO.puts("✅ Complex MIB parsed successfully!")
        IO.puts("Parsed #{length(mib.definitions)} definitions:")
        
        Enum.each(mib.definitions, fn def ->
          IO.puts("  - #{def.name}: #{inspect(def.syntax)}")
        end)
        
      {:error, errors} ->
        IO.puts("❌ Complex MIB parsing failed:")
        Enum.each(errors, fn error ->
          IO.puts("     #{error.message}")
        end)
    end
    
  {:error, error} ->
    IO.puts("❌ Complex MIB lexing failed: #{inspect(error)}")
end