#!/usr/bin/env elixir

# Test the tokenizer with the problematic numbers
Mix.install([])
Code.require_file("lib/snmp_lib/mib/snmp_tokenizer.ex")

defmodule TokenizerTest do
  def test_number(num_str) do
    IO.puts("Testing number: #{num_str}")
    
    # Test just the number
    chars = String.to_charlist(num_str)
    case SnmpLib.MIB.SnmpTokenizer.tokenize(chars, &SnmpLib.MIB.SnmpTokenizer.null_get_line/0) do
      {:ok, tokens} ->
        IO.puts("  Tokens: #{inspect(tokens)}")
      {:error, reason} ->
        IO.puts("  Error: #{inspect(reason)}")
    end
    
    # Test number in BITS context
    bits_context = "BITS { test(#{num_str}) }"
    chars = String.to_charlist(bits_context)
    case SnmpLib.MIB.SnmpTokenizer.tokenize(chars, &SnmpLib.MIB.SnmpTokenizer.null_get_line/0) do
      {:ok, tokens} ->
        IO.puts("  BITS context tokens: #{inspect(tokens)}")
      {:error, reason} ->
        IO.puts("  BITS context error: #{inspect(reason)}")
    end
    
    IO.puts("")
  end
  
  def run do
    IO.puts("=== Tokenizer Test for Problematic Numbers ===")
    test_number("209")
    test_number("225") 
    test_number("57699")
    
    # Test some working numbers for comparison
    test_number("100")
    test_number("200")
  end
end

TokenizerTest.run()