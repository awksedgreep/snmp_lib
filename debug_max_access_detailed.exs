#!/usr/bin/env elixir

Application.put_env(:snmp_lib, :environment, :test)

defmodule MaxAccessDetailedDebug do
  @moduledoc "Debug MAX-ACCESS parsing issue in detail"

  def test_docs_cable_device_mib do
    IO.puts("Testing DOCS-CABLE-DEVICE-MIB MAX-ACCESS parsing...")
    
    {:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
    {:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)
    
    # Find the first few OBJECT-TYPE definitions and their tokens
    object_types = find_object_type_positions(tokens)
    IO.puts("Found #{length(object_types)} OBJECT-TYPE definitions")
    
    # Test parsing the first OBJECT-TYPE that fails
    Enum.take(object_types, 3)
    |> Enum.each(fn {name, idx, line} ->
      IO.puts("\n--- Testing #{name} at line #{line} ---")
      
      # Create a mini-MIB with just the header and this one OBJECT-TYPE
      header_tokens = [
        {:identifier, "TEST-MIB", 1},
        {:keyword, :definitions, 1},
        {:symbol, :assign, 1},
        {:keyword, :begin, 1}
      ]
      
      # Extract tokens for this specific OBJECT-TYPE (look ahead ~100 tokens)
      object_start = idx
      object_end = min(length(tokens) - 1, idx + 100)
      
      # Find the actual end by looking for next OBJECT-TYPE or END
      actual_end = find_definition_end(tokens, object_start + 1)
      
      object_tokens = Enum.slice(tokens, object_start, actual_end - object_start)
      end_token = [{:keyword, :end, 999}]
      
      test_tokens = header_tokens ++ object_tokens ++ end_token
      
      # Show the tokens we're testing
      IO.puts("Testing tokens:")
      test_tokens
      |> Enum.with_index()
      |> Enum.take(20)
      |> Enum.each(fn {{type, value, line}, i} ->
        IO.puts("  #{i}: #{inspect({type, value, line})}")
      end)
      
      result = SnmpLib.MIB.Parser.parse_tokens(test_tokens)
      
      case result do
        {:error, [error]} ->
          if String.contains?(error.message, "MAX-ACCESS") do
            IO.puts("❌ MAX-ACCESS error: #{error.message}")
          else
            IO.puts("❌ Other error: #{error.message}")
          end
        {:ok, mib} ->
          IO.puts("✅ Success! Definitions: #{length(mib.definitions)}")
          if length(mib.definitions) > 0 do
            def = hd(mib.definitions)
            IO.puts("  - Type: #{def.__type__}")
            IO.puts("  - Has syntax: #{Map.has_key?(def, :syntax)}")
            IO.puts("  - Has max_access: #{Map.has_key?(def, :max_access)}")
            if Map.has_key?(def, :max_access) do
              IO.puts("  - Max access value: #{inspect(def.max_access)}")
            end
          end
      end
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
  
  defp find_definition_end(tokens, start_idx) do
    tokens
    |> Enum.drop(start_idx)
    |> Enum.with_index(start_idx)
    |> Enum.find_value(fn {{type, value, _line}, idx} ->
      case {type, value} do
        {:identifier, _} ->
          # Check if next token is OBJECT-TYPE, MODULE-IDENTITY, etc.
          case Enum.at(tokens, idx + 1) do
            {:keyword, keyword, _} when keyword in [:object_type, :module_identity, :textual_convention] ->
              idx
            _ -> nil
          end
        {:keyword, :end} -> idx
        _ -> nil
      end
    end) || length(tokens)
  end
end

MaxAccessDetailedDebug.test_docs_cable_device_mib()