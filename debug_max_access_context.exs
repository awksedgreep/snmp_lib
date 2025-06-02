#!/usr/bin/env elixir

Application.put_env(:snmp_lib, :environment, :test)

defmodule MaxAccessContextDebug do
  @moduledoc "Debug MAX-ACCESS issues in full MIB context"

  def test_docs_cable_device_context do
    IO.puts("Testing DOCS-CABLE-DEVICE-MIB MAX-ACCESS in full context...")
    
    {:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
    {:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)
    
    # Find where the first MAX-ACCESS error occurs by parsing progressively
    IO.puts("Total tokens: #{length(tokens)}")
    
    # Try parsing with progressively more tokens to find the failure point
    test_progressive_parsing(tokens)
  end
  
  defp test_progressive_parsing(tokens) do
    # Start with header + first few definitions
    header_tokens = tokens |> Enum.take_while(fn 
      {:keyword, :end, _} -> false
      _ -> true
    end)
    
    # Find all OBJECT-TYPE positions
    object_positions = find_object_type_positions(tokens)
    IO.puts("Found #{length(object_positions)} OBJECT-TYPE definitions")
    
    # Test parsing up to each OBJECT-TYPE to find where it breaks
    test_object_positions(object_positions, tokens)
  end
  
  defp test_object_positions(object_positions, tokens) do
    object_positions
    |> Enum.with_index()
    |> Enum.take(10)  # Test first 10 to avoid too much output
    |> Enum.find(fn {{name, token_idx, line}, position} ->
      # Take tokens up to this OBJECT-TYPE + 50 more tokens for the definition
      test_end = min(token_idx + 50, length(tokens) - 1)
      test_tokens = Enum.slice(tokens, 0, test_end) ++ [{:keyword, :end, 999}]
      
      IO.puts("\n--- Testing up to #{name} at position #{position + 1} (line #{line}) ---")
      
      result = SnmpLib.MIB.Parser.parse_tokens(test_tokens)
      
      case result do
        {:error, [error]} ->
          if String.contains?(error.message, "MAX-ACCESS") do
            IO.puts("❌ MAX-ACCESS error found!")
            IO.puts("  Message: #{error.message}")
            IO.puts("  This is where the parsing breaks")
            
            # Show the tokens around the failure point
            show_tokens_around_failure(tokens, token_idx)
            true  # Stop the search
          else
            IO.puts("❌ Other error: #{String.slice(error.message, 0, 60)}...")
            false  # Continue searching
          end
          
        {:ok, mib} ->
          IO.puts("✅ Success: #{length(mib.definitions)} definitions")
          false  # Continue searching
      end
    end)
  end
  
  defp show_tokens_around_failure(tokens, failure_idx) do
    IO.puts("\n🔍 Tokens around failure point:")
    start_idx = max(0, failure_idx - 10)
    end_idx = min(length(tokens) - 1, failure_idx + 10)
    
    tokens
    |> Enum.slice(start_idx, end_idx - start_idx + 1)
    |> Enum.with_index(start_idx)
    |> Enum.each(fn {{type, value, line}, idx} ->
      marker = if idx == failure_idx, do: " 👈 FAILURE", else: ""
      IO.puts("  #{idx}: Line #{line}: #{inspect({type, value})}#{marker}")
    end)
  end
  
  defp find_object_type_positions(tokens) do
    tokens
    |> Enum.with_index()
    |> Enum.reduce([], fn {token, idx}, acc ->
      case {token, Enum.at(tokens, idx - 1)} do
        {{:keyword, :object_type, line}, {:identifier, name, _}} ->
          [{name, idx - 1, line} | acc]
        _ -> acc
      end
    end)
    |> Enum.reverse()
  end
end

MaxAccessContextDebug.test_docs_cable_device_context()