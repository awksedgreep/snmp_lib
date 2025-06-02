#!/usr/bin/env elixir

defmodule TestTokenization do
  def run do
    simple_mib = """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    testObject OBJECT IDENTIFIER ::= { test 1 }
    
    END
    """
    
    IO.puts("🔍 Testing tokenization...")
    
    # First test our tokenizer
    case SnmpLib.MIB.Lexer.tokenize(simple_mib) do
      {:ok, tokens} ->
        IO.puts("✅ Our tokenizer produced tokens:")
        Enum.with_index(tokens, 1) |> Enum.each(fn {token, index} ->
          IO.puts("   #{index}. #{inspect(token)}")
        end)
        
        # Now test the conversion
        IO.puts("\n🔄 Converting tokens for grammar...")
        case SnmpLib.MIB.ActualParser.tokenize(simple_mib) do
          {:ok, converted_tokens} ->
            IO.puts("✅ Converted tokens:")
            Enum.with_index(converted_tokens, 1) |> Enum.each(fn {token, index} ->
              IO.puts("   #{index}. #{inspect(token)}")
            end)
            
            # Now test actual parsing
            IO.puts("\n🧪 Testing actual parsing...")
            case SnmpLib.MIB.ActualParser.parse(simple_mib) do
              {:ok, result} ->
                IO.puts("✅ Parsing succeeded: #{inspect(result)}")
              {:error, reason} ->
                IO.puts("❌ Parsing failed: #{inspect(reason)}")
            end
          
          {:error, reason} ->
            IO.puts("❌ Token conversion failed: #{inspect(reason)}")
        end
        
      {:error, reason} ->
        IO.puts("❌ Initial tokenization failed: #{inspect(reason)}")
    end
  end
end

TestTokenization.run()