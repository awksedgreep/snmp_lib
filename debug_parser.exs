#!/usr/bin/env elixir

# Test the parser with problematic numbers
Mix.install([])

# Add the lib directory to the code path
Code.append_path("lib")
Code.require_file("lib/snmp_lib/mib/snmp_tokenizer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")

defmodule ParserTest do
  def test_bits_with_number(num_str) do
    IO.puts("Testing BITS with number: #{num_str}")
    
    # Simple MIB with BITS syntax
    mib_content = """
    TEST-MIB DEFINITIONS ::= BEGIN
    testObject OBJECT-TYPE
        SYNTAX      BITS {
                        test(#{num_str})
                    }
        MAX-ACCESS  read-only
        STATUS      current
        DESCRIPTION "Test object"
        ::= { test 1 }
    END
    """
    
    # Tokenize the content
    chars = String.to_charlist(mib_content)
    case SnmpLib.MIB.SnmpTokenizer.tokenize(chars, &SnmpLib.MIB.SnmpTokenizer.null_get_line/0) do
      {:ok, tokens} ->
        IO.puts("  Tokenization successful: #{length(tokens)} tokens")
        
        # Initialize parser
        case SnmpLib.MIB.Parser.init_parser() do
          {:ok, parser_module} ->
            IO.puts("  Parser module: #{parser_module}")
            
            # Load the compiled module
            :code.add_path('_build/dev/lib/snmp_lib/ebin')
            
            # Try to parse
            case parser_module.parse(tokens) do
              {:ok, result} ->
                IO.puts("  Parse successful: #{inspect(result)}")
              {:error, {line, _module, message}} ->
                IO.puts("  Parse error at line #{line}: #{message}")
              {:error, reason} ->
                IO.puts("  Parse error: #{inspect(reason)}")
            end
            
          {:error, reason} ->
            IO.puts("  Parser init failed: #{inspect(reason)}")
        end
        
      {:error, reason} ->
        IO.puts("  Tokenization failed: #{inspect(reason)}")
    end
    
    IO.puts("")
  end
  
  def run do
    IO.puts("=== Parser Test for Problematic Numbers ===")
    test_bits_with_number("209")
    test_bits_with_number("225") 
    test_bits_with_number("57699")
    
    # Test some working numbers for comparison
    test_bits_with_number("100")
    test_bits_with_number("0")
  end
end

ParserTest.run()