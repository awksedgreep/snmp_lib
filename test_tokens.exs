#!/usr/bin/env elixir

defmodule TestTokens do
  def run do
    IO.puts("🧪 Testing token format from 1:1 tokenizer...")
    
    simple_text = ~c"TEST-MIB DEFINITIONS ::= BEGIN \"some string\" END"
    
    case SnmpLib.MIB.SnmpTokenizer.tokenize(simple_text, &SnmpLib.MIB.SnmpTokenizer.null_get_line/0) do
      {:ok, tokens} ->
        IO.puts("✅ Tokenized successfully")
        IO.puts("📋 Tokens:")
        Enum.each(tokens, fn token ->
          IO.puts("   #{inspect(token)}")
        end)
        
        # Test val() function equivalent
        string_tokens = Enum.filter(tokens, fn 
          {token_type, _, _} when token_type == :string -> true
          _ -> false
        end)
        
        if string_tokens != [] do
          IO.puts("\n🔍 String token analysis:")
          Enum.each(string_tokens, fn token ->
            IO.puts("   Token: #{inspect(token)}")
            IO.puts("   element(3, token): #{inspect(:erlang.element(3, token))}")
          end)
        end
        
      {:error, reason} ->
        IO.puts("❌ Tokenization failed: #{inspect(reason)}")
    end
  end
end

TestTokens.run()