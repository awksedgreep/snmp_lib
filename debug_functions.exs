#!/usr/bin/env elixir

# Direct function testing to isolate the issue

alias SnmpLib.MIB.{Lexer, Parser}

# Get the tokens for minimal MIB
minimal_content = """
TEST-MIB DEFINITIONS ::= BEGIN
END
"""

{:ok, tokens} = Lexer.tokenize(minimal_content)
IO.puts("Tokens: #{inspect(tokens)}")

# After header parsing we should have: [{:keyword, :end, %{line: 2, column: 1}}]
end_tokens = [{:keyword, :end, %{line: 2, column: 1}}]

# Test the definition parsing functions directly
IO.puts("\n=== Testing parse_imports_section ===")
# This should return {:ok, [], end_tokens, context} since first token is not :imports
context = %{errors: [], warnings: [], current_module: nil, imports: [], snmp_version: nil}

# Use :erlang.apply to call private function
try do
  result = :erlang.apply(Parser, :parse_imports_section, [end_tokens, context])
  IO.puts("parse_imports_section result: #{inspect(result)}")
rescue
  UndefinedFunctionError ->
    IO.puts("parse_imports_section is private - expected")
  error ->
    IO.puts("Error: #{inspect(error)}")
end

IO.puts("\n=== Testing parse_definitions_section ===")
# This should return {:ok, [], end_tokens, context} since first token is :end
try do
  result = :erlang.apply(Parser, :parse_definitions_section, [end_tokens, context])
  IO.puts("parse_definitions_section result: #{inspect(result)}")
rescue
  UndefinedFunctionError ->
    IO.puts("parse_definitions_section is private - expected")
  error ->
    IO.puts("Error: #{inspect(error)}")
end

IO.puts("\n=== Testing manual pattern matching ===")
# Let's manually test the pattern that should work
case end_tokens do
  [{:keyword, :end} | _] = tokens ->
    IO.puts("Pattern matches! tokens = #{inspect(tokens)}")
  _ ->
    IO.puts("Pattern does not match")
end

IO.puts("\n=== Full parser test ===")
case Parser.parse_tokens(tokens) do
  {:ok, mib} ->
    IO.puts("Success!")
    IO.inspect(mib, pretty: true, limit: :infinity)
    
  {:error, errors} ->
    IO.puts("Failed with errors:")
    Enum.each(errors, fn error ->
      IO.puts("  Error: #{error.message}")
      IO.puts("    Type: #{error.type}")
      IO.puts("    Line: #{error.line || "unknown"}")
      IO.puts("    Column: #{error.column || "unknown"}")
    end)
end