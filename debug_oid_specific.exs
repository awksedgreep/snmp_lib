#!/usr/bin/env elixir

# Isolate the specific OID parsing issue
alias SnmpLib.MIB.{Lexer, Parser}

# Test the exact pattern that's failing
test_oid = """
TEST-MIB DEFINITIONS ::= BEGIN

cableLabs OBJECT IDENTIFIER ::= { enterprises 4491 }

END
"""

IO.puts("🔍 Testing specific OID pattern that's failing...")

case Lexer.tokenize(test_oid) do
  {:ok, tokens} ->
    IO.puts("✅ Tokenized successfully, #{length(tokens)} tokens")
    
    # Find the problematic tokens
    IO.puts("\n📋 All tokens:")
    tokens
    |> Enum.with_index()
    |> Enum.each(fn {{type, value, pos}, idx} ->
      IO.puts("  #{idx}: #{type} = #{inspect(value)} (pos: #{inspect(pos)})")
    end)
    
    # Look specifically for the pattern: identifier "enterprises" followed by integer 4491
    IO.puts("\n🎯 Looking for pattern: identifier 'enterprises' + integer 4491...")
    
    token_pairs = Enum.chunk_every(tokens, 2, 1, :discard)
    
    Enum.each(token_pairs, fn [t1, t2] ->
      case {t1, t2} do
        {{:identifier, "enterprises", _}, {:integer, 4491, _}} ->
          IO.puts("✅ Found the pattern!")
          IO.puts("   Token 1: #{inspect(t1)}")
          IO.puts("   Token 2: #{inspect(t2)}")
        _ ->
          :ok
      end
    end)
    
    case Parser.parse_tokens(tokens) do
      {:ok, ast} ->
        IO.puts("✅ Parsed successfully!")
        IO.inspect(ast.definitions, label: "Definitions")
      {:error, errors} ->
        IO.puts("❌ Parsing failed: #{length(errors)} errors")
        Enum.each(errors, fn error ->
          IO.puts("     Error: #{SnmpLib.MIB.Error.format(error)}")
        end)
    end
  {:error, error} ->
    IO.puts("❌ Tokenization failed: #{inspect(error)}")
end