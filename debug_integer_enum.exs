#!/usr/bin/env elixir

# Test the parser with INTEGER enumeration containing large numbers
Mix.install([])

# Add the lib directory to the code path
Code.append_path("lib")
Code.require_file("lib/snmp_lib/mib/snmp_tokenizer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")

defmodule IntegerEnumTest do
  def test_integer_enum_with_number(num_str) do
    IO.puts("Testing INTEGER enum with number: #{num_str}")
    
    # Simple MIB with INTEGER enumeration syntax (much shorter)
    mib_content = """
    TEST-MIB DEFINITIONS ::= BEGIN
    TestType ::= TEXTUAL-CONVENTION
        STATUS      current
        DESCRIPTION "Test type"
        SYNTAX  INTEGER {
                    test1(100),
                    test2(200),
                    test3(#{num_str})
                }
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
            :code.add_path(~c"_build/dev/lib/snmp_lib/ebin")
            
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
  
  def test_long_integer_enum() do
    IO.puts("Testing longer INTEGER enum with problematic number")
    
    # Longer enumeration similar to the actual MIB
    mib_content = """
    TEST-MIB DEFINITIONS ::= BEGIN
    TestType ::= TEXTUAL-CONVENTION
        STATUS      current
        DESCRIPTION "Test type"
        SYNTAX  INTEGER {
                    other(1),
                    regular1822(2),
                    hdh1822(3),
                    ddnX25(4),
                    rfc877x25(5),
                    ethernetCsmacd(6),
                    iso88023Csmacd(7),
                    iso88024TokenBus(8),
                    iso88025TokenRing(9),
                    iso88026Man(10),
                    starLan(11),
                    proteon10Mbit(12),
                    proteon80Mbit(13),
                    hyperchannel(14),
                    fddi(15),
                    lapb(16),
                    bridge(209)
                }
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
            :code.add_path(~c"_build/dev/lib/snmp_lib/ebin")
            
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
    IO.puts("=== INTEGER Enumeration Test for Problematic Numbers ===")
    test_integer_enum_with_number("209")
    test_integer_enum_with_number("225") 
    test_integer_enum_with_number("57699")
    test_long_integer_enum()
  end
end

IntegerEnumTest.run()