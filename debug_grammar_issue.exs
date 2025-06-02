#!/usr/bin/env elixir

defmodule DebugGrammarIssue do
  def run do
    IO.puts("🔍 Debugging grammar issue with MODULE-COMPLIANCE...")
    
    # Test with the simplest possible MODULE-COMPLIANCE
    simple_mib = """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    testCompliance MODULE-COMPLIANCE
        STATUS current
        DESCRIPTION "Test"
        ::= { test 1 }
        
    END
    """
    
    IO.puts("📄 Testing simple MODULE-COMPLIANCE...")
    
    case SnmpLib.MIB.ActualParser.tokenize(simple_mib) do
      {:ok, tokens} ->
        IO.puts("✅ Tokenization successful! #{length(tokens)} tokens")
        
        IO.puts("\n🔍 All tokens:")
        tokens
        |> Enum.with_index()
        |> Enum.each(fn {token, idx} ->
          IO.puts("  #{idx}: #{inspect(token)}")
        end)
        
        # Try to parse with the grammar
        IO.puts("\n🧪 Attempting parse...")
        case :mib_grammar_elixir.parse(tokens) do
          {:ok, result} ->
            IO.puts("✅ Parse successful!")
            IO.inspect(result, pretty: true)
            
          {:error, {line, module, message}} ->
            IO.puts("❌ Parse failed at line #{line}")
            IO.puts("   Module: #{module}")
            IO.puts("   Message: #{inspect(message)}")
            
            # Find the problematic token
            if line <= length(tokens) do
              problematic_token = Enum.at(tokens, line - 1)
              IO.puts("   Problem token: #{inspect(problematic_token)}")
            end
        end
        
      {:error, reason} ->
        IO.puts("❌ Tokenization failed: #{inspect(reason)}")
    end
  end
end

DebugGrammarIssue.run()