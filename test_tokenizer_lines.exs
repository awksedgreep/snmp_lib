#!/usr/bin/env elixir

# Test if the issue is with tokenizer line reporting

content = """
Line 1
Line 2  
Line 3
rpr (225),
Line 5
"""

IO.puts("Testing tokenizer line reporting...")
IO.puts("Content:")
IO.puts(content)

case SnmpLib.MIB.Parser.tokenize(content) do
  {:ok, tokens} ->
    IO.puts("\nTokens:")
    Enum.each(tokens, fn token ->
      case token do
        {:integer, line, 225} ->
          IO.puts(">>> Found 225 at line #{line}")
        {type, line, value} ->
          IO.puts("  #{type} at line #{line}: #{inspect(value)}")
        other ->
          IO.puts("  #{inspect(other)}")
      end
    end)
  {:error, error} ->
    IO.puts("Tokenization failed: #{inspect(error)}")
end