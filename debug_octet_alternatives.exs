#!/usr/bin/env elixir

# Debug OCTET STRING with complex SIZE alternatives

# Change to the project directory and load the compiled modules
System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

test_cases = [
  "OCTET STRING (SIZE (20))",
  "OCTET STRING (SIZE (0..1400))",
  "OCTET STRING (SIZE (74|106|140|204|270))",
  "OCTET STRING (SIZE (0|74|106|140|204|270))",
  "OCTET STRING (SIZE (1..32))"
]

test_cases |> Enum.with_index(1) |> Enum.each(fn {syntax, index} ->
  test_content = """
  TEST-MIB DEFINITIONS ::= BEGIN

  testObject#{index} OBJECT-TYPE
      SYNTAX      #{syntax}
      MAX-ACCESS  read-only
      STATUS      current
      DESCRIPTION "Test object #{index}"
      ::= { test #{index} }

  END
  """

  IO.puts("=== Testing case #{index}: #{syntax} ===")

  case SnmpLib.MIB.LexerErlangPort.tokenize(test_content) do
    {:ok, tokens} ->
      IO.puts("✓ Tokenization successful: #{length(tokens)} tokens")
      
      case SnmpLib.MIB.Parser.parse_tokens(tokens) do
        {:ok, mib} ->
          IO.puts("✓ Parsing successful!")
          IO.puts("MIB name: #{mib.name}, Definitions: #{length(mib.definitions)}")
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
  
  IO.puts("")
end)