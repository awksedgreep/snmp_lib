#!/usr/bin/env elixir

# Test the parser with the actual problematic MIB content
Mix.install([])

# Add the lib directory to the code path
Code.append_path("lib")
Code.require_file("lib/snmp_lib/mib/snmp_tokenizer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")

defmodule ActualMibTest do
  def test_actual_mib_file(filename, around_line) do
    IO.puts("Testing actual MIB file: #{filename} around line #{around_line}")
    
    # Read the actual file
    full_path = "test/fixtures/mibs/working/#{filename}"
    case File.read(full_path) do
      {:ok, content} ->
        # Tokenize the content
        chars = String.to_charlist(content)
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
                    IO.puts("  Parse successful!")
                  {:error, {line, _module, message}} ->
                    IO.puts("  Parse error at line #{line}: #{message}")
                    
                    # Find the token around the error line and show some context
                    error_tokens = try do
                      tokens
                      |> Enum.with_index()
                      |> Enum.filter(fn {{_type, token_line, _value}, _index} -> 
                        abs(token_line - line) <= 3
                      end)
                      |> Enum.take(10)
                    rescue
                      _ -> []
                    end
                    
                    IO.puts("  Tokens around error:")
                    Enum.each(error_tokens, fn token_with_index ->
                      try do
                        {{type, token_line, value}, index} = token_with_index
                        IO.puts("    #{index}: Line #{token_line}: {#{type}, #{inspect(value)}}")
                      rescue
                        _ ->
                          IO.puts("    #{inspect(token_with_index)}")
                      end
                    end)
                    
                  {:error, reason} ->
                    IO.puts("  Parse error: #{inspect(reason)}")
                end
                
              {:error, reason} ->
                IO.puts("  Parser init failed: #{inspect(reason)}")
            end
            
          {:error, reason} ->
            IO.puts("  Tokenization failed: #{inspect(reason)}")
        end
        
      {:error, reason} ->
        IO.puts("  File read failed: #{inspect(reason)}")
    end
    
    IO.puts("")
  end
  
  def run do
    IO.puts("=== Actual MIB File Test ===")
    test_actual_mib_file("IANAifType-MIB.mib", 329)
    test_actual_mib_file("DISMAN-SCHEDULE-MIB.mib", 296) 
    test_actual_mib_file("IANA-ADDRESS-FAMILY-NUMBERS-MIB.mib", 130)
  end
end

ActualMibTest.run()