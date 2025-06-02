#!/usr/bin/env elixir

Application.put_env(:snmp_lib, :environment, :test)

defmodule ObjectTypeAccessDebug do
  @moduledoc "Debug which OBJECT-TYPE is missing MAX-ACCESS"

  def test_progressive_parsing do
    IO.puts("Testing DOCS-IF-MIB progressive parsing to find OBJECT-TYPE issue...")
    
    {:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-IF-MIB")
    {:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)
    
    # Find all OBJECT-TYPE definitions
    object_types = find_object_type_positions(tokens)
    IO.puts("Found #{length(object_types)} OBJECT-TYPE definitions")
    
    # Test parsing up to each OBJECT-TYPE
    Enum.each(object_types, fn {name, idx, line} ->
      # Parse up to this definition + extra tokens for the definition itself
      test_tokens = Enum.slice(tokens, 0, idx + 100)
      test_tokens = test_tokens ++ [{:keyword, :end, 999}]
      
      result = SnmpLib.MIB.Parser.parse_tokens(test_tokens)
      
      case result do
        {:error, [error]} -> 
          if String.contains?(error.message, "MAX-ACCESS") do
            IO.puts("❌ FAILED at #{name} (line #{line}): #{error.message}")
            
            # Show context around this OBJECT-TYPE
            IO.puts("\\nTokens around #{name}:")
            start_idx = max(0, idx - 5)
            end_idx = min(length(tokens) - 1, idx + 30)
            
            tokens
            |> Enum.slice(start_idx..end_idx) 
            |> Enum.with_index(start_idx)
            |> Enum.each(fn {t, i} ->
              marker = if i == idx, do: " <-- #{name}", else: ""
              IO.puts("  #{i}: #{inspect(t)}#{marker}")
            end)
            
            # Stop on first MAX-ACCESS error
            exit(:normal)
          else
            IO.puts("❌ FAILED at #{name} (line #{line}) - different error: #{error.message}")
          end
        {:ok, mib} -> 
          IO.puts("✅ OK parsing up to #{name} - #{length(mib.definitions)} definitions")
      end
    end)
  end
  
  defp find_object_type_positions(tokens) do
    tokens
    |> Enum.with_index()
    |> Enum.reduce([], fn {token, idx}, acc ->
      case {token, Enum.at(tokens, idx - 1)} do
        {{:keyword, :object_type, line}, {:identifier, name, _}} ->
          [{name, idx, line} | acc]
        _ -> acc
      end
    end)
    |> Enum.reverse()
  end
end

ObjectTypeAccessDebug.test_progressive_parsing()