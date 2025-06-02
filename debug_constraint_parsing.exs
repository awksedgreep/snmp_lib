#!/usr/bin/env elixir

# Debug constraint parsing specifically

# Change to the project directory and load the compiled modules
System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

# Test just the constraint: "Unsigned32 (0..179 | 255)"
test_content = """
DOCS-IF3-MIB DEFINITIONS ::= BEGIN

docsIf3BondingGrpCfgDsidReseqWarnThrshld OBJECT-TYPE
     SYNTAX      Unsigned32 (0..179 | 255)
     ::= { test 1 }

END
"""

IO.puts("=== Testing Constraint Parsing: Unsigned32 (0..179 | 255) ===")

case SnmpLib.MIB.LexerErlangPort.tokenize(test_content) do
  {:ok, tokens} ->
    IO.puts("✓ Tokenization successful: #{length(tokens)} tokens")
    
    # Find the constraint tokens
    constraint_start = Enum.find_index(tokens, fn 
      {:keyword, :unsigned32, _} -> true
      _ -> false
    end)
    
    if constraint_start do
      constraint_tokens = Enum.slice(tokens, constraint_start, 10)
      IO.puts("Constraint tokens: #{inspect(constraint_tokens)}")
    end
    
    case SnmpLib.MIB.Parser.parse_tokens(tokens) do
      {:ok, mib} ->
        IO.puts("✓ Parsing successful!")
        IO.puts("MIB name: #{mib.name}")
        IO.puts("Definitions: #{length(mib.definitions)}")
      {:error, errors} when is_list(errors) ->
        IO.puts("✗ Parsing failed with #{length(errors)} errors:")
        Enum.each(errors, fn error ->
          IO.puts("  - #{inspect(error)}")
        end)
      {:error, error} ->
        IO.puts("✗ Parsing failed:")
        IO.puts("  #{inspect(error)}")
    end
  {:error, reason} ->
    IO.puts("✗ Tokenization failed: #{reason}")
end