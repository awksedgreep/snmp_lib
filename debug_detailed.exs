#!/usr/bin/env elixir

# Detailed debug script to trace the parsing steps

alias SnmpLib.MIB.{Lexer, Parser}

# Test minimal MIB
minimal_content = """
TEST-MIB DEFINITIONS ::= BEGIN
END
"""

IO.puts("=== Testing minimal MIB ===")
IO.puts(minimal_content)

case Lexer.tokenize(minimal_content) do
  {:ok, tokens} ->
    IO.puts("Tokens:")
    Enum.with_index(tokens, 1)
    |> Enum.each(fn {token, idx} ->
      IO.puts("  #{idx}. #{inspect(token)}")
    end)
    
    # Let's manually trace the parsing steps
    IO.puts("\n=== Manual parsing trace ===")
    
    # Initialize context
    context = %{
      errors: [],
      warnings: [],
      current_module: nil,
      imports: [],
      snmp_version: nil
    }
    
    # Step 1: Parse header
    IO.puts("Step 1: Parsing header from tokens: #{inspect(tokens)}")
    
    # We expect: TEST-MIB DEFINITIONS ::= BEGIN
    [
      {:identifier, "TEST-MIB", _},
      {:keyword, :definitions, _},
      {:symbol, :assign, _},
      {:keyword, :begin, _}
      | rest_after_header
    ] = tokens
    
    IO.puts("After header, remaining tokens: #{inspect(rest_after_header)}")
    
    # Step 2: Parse imports (should be empty)
    IO.puts("Step 2: Parsing imports from: #{inspect(rest_after_header)}")
    # Since first token is not :imports, should return {:ok, [], tokens, context}
    
    # Step 3: Parse definitions (should find END and return empty list)
    IO.puts("Step 3: Parsing definitions from: #{inspect(rest_after_header)}")
    # Should match the first clause and return {:ok, [], rest_after_header, context}
    
    # Step 4: Expect END token
    IO.puts("Step 4: Expecting END token from: #{inspect(rest_after_header)}")
    # This should work since rest_after_header = [{:keyword, :end, ...}]
    
    IO.puts("\nLet's run the actual parser and see what happens...")
    
    case Parser.parse_tokens(tokens) do
      {:ok, mib} ->
        IO.puts("Success!")
        IO.inspect(mib, pretty: true)
        
      {:error, errors} ->
        IO.puts("Failed with errors:")
        Enum.each(errors, fn error ->
          IO.puts("  Error: #{error.message}")
          IO.puts("    Type: #{error.type}")
          IO.puts("    Line: #{error.line || "unknown"}")
          IO.puts("    Column: #{error.column || "unknown"}")
          IO.puts("    Context: #{inspect(error.context)}")
        end)
    end
    
  {:error, error} ->
    IO.puts("Tokenization failed!")
    IO.puts("Error: #{error.message}")
end