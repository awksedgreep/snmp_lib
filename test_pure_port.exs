#!/usr/bin/env elixir

# Test the PURE, UNMODIFIED parser port
alias SnmpLib.MIB.{Lexer}

# Load the original parser port directly
Code.require_file("lib/snmp_lib/mib/parser_port.ex")

defmodule PurePortTest do
  @docsis_dir "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/docsis"

  def test_original_port do
    IO.puts("=" |> String.duplicate(80))
    IO.puts("🔬 TESTING PURE ORIGINAL PARSER PORT")
    IO.puts("=" |> String.duplicate(80))
    IO.puts("Testing with SnmpLib.MIB.ParserPort (unmodified)")
    IO.puts("")

    # Test a few key DOCSIS MIBs with the original port
    test_mibs = [
      "CLAB-DEF-MIB",
      "DOCS-CABLE-DEVICE-MIB", 
      "DOCS-IF-MIB",
      "SNMPv2-SMI"
    ]

    results = Enum.map(test_mibs, &test_single_mib_with_port/1)
    
    successes = Enum.count(results, fn {_, result} -> 
      case result do
        {:success, _, _} -> true
        _ -> false
      end
    end)
    
    IO.puts("")
    IO.puts("📊 PURE PORT RESULTS:")
    IO.puts("  Tested: #{length(test_mibs)} key MIBs")
    IO.puts("  Successes: #{successes}")
    IO.puts("  Success rate: #{(successes / length(test_mibs) * 100) |> Float.round(1)}%")
    
    results
  end

  defp test_single_mib_with_port(filename) do
    file_path = Path.join(@docsis_dir, filename)
    
    IO.puts("🔍 Testing #{filename} with PURE port...")
    
    result = case File.read(file_path) do
      {:ok, content} ->
        try do
          case Lexer.tokenize(content) do
            {:ok, tokens} ->
              IO.puts("  ✅ Tokenization: #{length(tokens)} tokens")
              
              # Use the ORIGINAL parser port
              case SnmpLib.MIB.ParserPort.parse_tokens(tokens) do
                {:ok, mib} ->
                  def_count = length(mib.definitions)
                  import_count = length(mib.imports)
                  IO.puts("  ✅ SUCCESS: #{def_count} definitions, #{import_count} imports")
                  {:success, def_count, import_count}
                  
                {:error, errors} when is_list(errors) ->
                  first_error = List.first(errors)
                  error_msg = format_error_safely(first_error)
                  IO.puts("  ❌ Parse error: #{error_msg}")
                  {:parse_error, error_msg}
                  
                {:error, error} ->
                  error_msg = format_error_safely(error)
                  IO.puts("  ❌ Parse error: #{error_msg}")
                  {:parse_error, error_msg}
              end
              
            {:error, error} ->
              IO.puts("  ❌ Tokenization failed: #{inspect(error)}")
              {:tokenize_error, error}
          end
        rescue
          exception ->
            error_msg = "Exception: #{Exception.message(exception)}"
            IO.puts("  ❌ Exception: #{error_msg}")
            {:exception, error_msg}
        end
        
      {:error, reason} ->
        IO.puts("  ❌ File read error: #{inspect(reason)}")
        {:file_error, reason}
    end
    
    {filename, result}
  end

  defp format_error_safely(error) do
    cond do
      is_binary(error) ->
        String.slice(error, 0, 80)
      is_map(error) && Map.has_key?(error, :message) ->
        String.slice(error.message, 0, 80)
      true ->
        error |> inspect() |> String.slice(0, 80)
    end
  end
end

# Test the pure original port
PurePortTest.test_original_port()