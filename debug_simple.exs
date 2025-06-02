#!/usr/bin/env elixir

# Debug simple integer constraint parsing

test_content = "
TEST-MIB DEFINITIONS ::= BEGIN

testObject OBJECT-TYPE
    SYNTAX      Integer32(0 | 2..32)
    MAX-ACCESS  read-create
    STATUS      current
    DESCRIPTION \"Test object\"
    ::= { test 1 }

END
"

IO.puts("=== Testing simple Integer32 constraint ===")

case SnmpLib.MIB.LexerErlangPort.tokenize(test_content) do
  {:ok, tokens} ->
    IO.puts("✓ Tokenization successful: #{length(tokens)} tokens")
    
    # Show tokens around Integer32
    integer32_index = Enum.find_index(tokens, fn
      {:keyword, :integer32, _} -> true
      _ -> false
    end)
    
    if integer32_index do
      IO.puts("Found Integer32 at index #{integer32_index}")
      relevant_tokens = Enum.slice(tokens, (integer32_index-2)..(integer32_index+10))
      IO.puts("Relevant tokens:")
      Enum.with_index(relevant_tokens, integer32_index-2) |> Enum.each(fn {token, idx} ->
        IO.puts("  #{idx}: #{inspect(token)}")
      end)
    else
      IO.puts("Integer32 not found, showing all tokens:")
      Enum.with_index(tokens) |> Enum.each(fn {token, idx} ->
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