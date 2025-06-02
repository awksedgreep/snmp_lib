#!/usr/bin/env elixir

# Debug script for DOCSIS MIB parsing

{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
{:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)

IO.puts("Tokenization successful - #{length(tokens)} tokens")
IO.puts("First 10 tokens:")
tokens |> Enum.take(10) |> Enum.each(&IO.inspect/1)

result = SnmpLib.MIB.Parser.parse_tokens(tokens)

case result do
  {:error, [error]} -> 
    IO.puts("Error occurred:")
    IO.puts("  Type: #{error.type}")
    IO.puts("  Message: #{inspect(error.message)}")
    IO.puts("  Line: #{error.line}")
  {:ok, mib} -> 
    IO.puts("Success! MIB name: #{mib.name}")
end