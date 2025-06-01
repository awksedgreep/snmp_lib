#!/usr/bin/env elixir

# Debug script to test parser step by step

alias SnmpLib.MIB.{Lexer, Parser}

# Test simple MIB with imports
mib_content = """
TEST-MIB DEFINITIONS ::= BEGIN
IMPORTS DisplayString FROM SNMPv2-TC;
END
"""

IO.puts("=== Testing MIB content ===")
IO.puts(mib_content)

IO.puts("\n=== Step 1: Tokenization ===")
case Lexer.tokenize(mib_content) do
  {:ok, tokens} ->
    IO.puts("Tokenization successful!")
    IO.puts("Token count: #{length(tokens)}")
    
    # Print tokens for debugging
    Enum.with_index(tokens, 1)
    |> Enum.each(fn {token, idx} ->
      IO.puts("  #{idx}. #{inspect(token)}")
    end)
    
    IO.puts("\n=== Step 2: Parsing ===")
    case Parser.parse_tokens(tokens) do
      {:ok, mib} ->
        IO.puts("Parsing successful!")
        IO.inspect(mib, pretty: true)
        
      {:error, errors} ->
        IO.puts("Parsing failed!")
        Enum.each(errors, fn error ->
          IO.puts("  Error: #{error.message}")
          IO.puts("    Type: #{error.type}")
          IO.puts("    Line: #{error.line || "unknown"}")
          IO.puts("    Column: #{error.column || "unknown"}")
        end)
        
      {:warning, mib, warnings} ->
        IO.puts("Parsing completed with warnings!")
        IO.inspect(mib, pretty: true)
        Enum.each(warnings, fn warning ->
          IO.puts("  Warning: #{warning.message}")
        end)
    end
    
  {:error, error} ->
    IO.puts("Tokenization failed!")
    IO.puts("Error: #{error.message}")
    IO.puts("Type: #{error.type}")
    IO.puts("Line: #{error.line || "unknown"}")
    IO.puts("Column: #{error.column || "unknown"}")
end

# Test even simpler case
IO.puts("\n\n=== Testing minimal MIB ===")
minimal_content = """
TEST-MIB DEFINITIONS ::= BEGIN
END
"""

IO.puts(minimal_content)

case Lexer.tokenize(minimal_content) do
  {:ok, tokens} ->
    IO.puts("Minimal tokenization successful!")
    Enum.with_index(tokens, 1)
    |> Enum.each(fn {token, idx} ->
      IO.puts("  #{idx}. #{inspect(token)}")
    end)
    
    case Parser.parse_tokens(tokens) do
      {:ok, mib} ->
        IO.puts("Minimal parsing successful!")
        IO.inspect(mib, pretty: true)
        
      {:error, errors} ->
        IO.puts("Minimal parsing failed!")
        Enum.each(errors, fn error ->
          IO.puts("  Error: #{error.message}")
          IO.puts("    Type: #{error.type}")
          IO.puts("    Line: #{error.line || "unknown"}")
          IO.puts("    Column: #{error.column || "unknown"}")
        end)
    end
    
  {:error, error} ->
    IO.puts("Minimal tokenization failed!")
    IO.puts("Error: #{error.message}")
end