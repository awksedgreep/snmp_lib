#!/usr/bin/env elixir

# Debug OCTET STRING (SIZE (20)) parsing issue

# Change to the project directory and load the compiled modules
System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

test_content = """
TEST-MIB DEFINITIONS ::= BEGIN

testObject OBJECT-TYPE
    SYNTAX      OCTET STRING (SIZE (20))
    MAX-ACCESS  read-only
    STATUS      current
    DESCRIPTION "Test object"
    ::= { test 1 }

END
"""

IO.puts("=== Testing OCTET STRING (SIZE (20)) parsing ===")

case SnmpLib.MIB.LexerErlangPort.tokenize(test_content) do
  {:ok, tokens} ->
    IO.puts("✓ Tokenization successful: #{length(tokens)} tokens")
    
    # Find the OCTET STRING part
    octet_start = Enum.find_index(tokens, fn
      {:keyword, :octet, _} -> true
      _ -> false
    end)
    
    if octet_start do
      IO.puts("Found OCTET at index #{octet_start}")
      relevant_tokens = Enum.slice(tokens, octet_start, 15)
      IO.puts("Relevant tokens:")
      Enum.with_index(relevant_tokens, octet_start) |> Enum.each(fn {token, idx} ->
        IO.puts("  #{idx}: #{inspect(token)}")
      end)
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