#!/usr/bin/env elixir

# Comprehensive test of all DOCSIS MIBs with the ported parser
alias SnmpLib.MIB.{Parser, Error}

defmodule ComprehensiveDocsisTest do
  @docsis_dir "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/docsis"

  def run_complete_test do
    IO.puts(String.duplicate("=", 80))
    IO.puts("🔬 COMPREHENSIVE DOCSIS MIB TEST WITH PORTED PARSER")
    IO.puts(String.duplicate("=", 80))
    IO.puts("Testing every MIB in #{@docsis_dir}")
    IO.puts("")

    # Get all MIB files
    mib_files = get_all_mib_files()
    total_count = length(mib_files)
    
    IO.puts("📊 Found #{total_count} MIB files")
    IO.puts("")

    # Test each MIB
    results = Enum.map(mib_files, &test_single_mib/1)
    
    # Summary statistics
    print_summary(results, total_count)
    
    results
  end

  defp get_all_mib_files do
    case File.ls(@docsis_dir) do
      {:ok, files} ->
        files
        |> Enum.filter(fn file -> 
          path = Path.join(@docsis_dir, file)
          File.regular?(path) && not String.ends_with?(file, ".bin")
        end)
        |> Enum.sort()
      {:error, reason} ->
        IO.puts("❌ Could not read DOCSIS directory: #{inspect(reason)}")
        []
    end
  end

  defp test_single_mib(filename) do
    file_path = Path.join(@docsis_dir, filename)
    
    IO.puts("🔍 Testing #{filename}...")
    
    start_time = System.monotonic_time(:microsecond)
    
    result = case File.read(file_path) do
      {:ok, content} ->
        test_mib_content(filename, content)
      {:error, reason} ->
        IO.puts("  ❌ File read error: #{inspect(reason)}")
        {:file_error, reason}
    end
    
    end_time = System.monotonic_time(:microsecond)
    duration = (end_time - start_time) / 1000 # Convert to milliseconds
    
    case result do
      {:success, token_count, def_count} ->
        IO.puts("  ✅ Success: #{token_count} tokens → #{def_count} definitions (#{Float.round(duration, 1)}ms)")
      {:tokenize_error, _} ->
        IO.puts("  ❌ Tokenization failed (#{Float.round(duration, 1)}ms)")
      {:parse_error, _} ->
        IO.puts("  ❌ Parsing failed (#{Float.round(duration, 1)}ms)")
      {:file_error, _} ->
        IO.puts("  ❌ File error (#{Float.round(duration, 1)}ms)")
    end
    
    {filename, result, duration}
  end

  defp test_mib_content(filename, content) do
    # First try tokenization
    case Parser.parse(content) do
      {:ok, mib} ->
        {:success, count_tokens(content), length(mib.definitions)}
        
      {:error, errors} when is_list(errors) ->
        first_error = List.first(errors)
        error_msg = format_error_safely(first_error)
        IO.puts("    Error: #{error_msg}")
        {:parse_error, error_msg}
        
      {:error, error} ->
        error_msg = format_error_safely(error)
        IO.puts("    Error: #{error_msg}")
        {:parse_error, error_msg}
    end
  rescue
    exception ->
      error_msg = "Exception: #{Exception.message(exception)}"
      IO.puts("    Exception: #{error_msg}")
      {:parse_error, error_msg}
  end

  defp count_tokens(content) do
    case SnmpLib.MIB.Lexer.tokenize(content) do
      {:ok, tokens} -> length(tokens)
      {:error, _} -> 0
    end
  end

  defp format_error_safely(error) do
    cond do
      is_binary(error) ->
        String.slice(error, 0, 100)
      is_map(error) && Map.has_key?(error, :message) ->
        String.slice(error.message, 0, 100)
      true ->
        error |> inspect() |> String.slice(0, 100)
    end
  end

  defp print_summary(results, total_count) do
    IO.puts("")
    IO.puts(String.duplicate("=", 80))
    IO.puts("📈 FINAL RESULTS SUMMARY")
    IO.puts(String.duplicate("=", 80))
    
    successes = Enum.count(results, fn {_, result, _} -> 
      case result do
        {:success, _, _} -> true
        _ -> false
      end
    end)
    
    tokenize_errors = Enum.count(results, fn {_, result, _} -> 
      case result do
        {:tokenize_error, _} -> true
        _ -> false
      end
    end)
    
    parse_errors = Enum.count(results, fn {_, result, _} -> 
      case result do
        {:parse_error, _} -> true
        _ -> false
      end
    end)
    
    file_errors = Enum.count(results, fn {_, result, _} -> 
      case result do
        {:file_error, _} -> true
        _ -> false
      end
    end)
    
    success_rate = (successes / total_count * 100) |> Float.round(1)
    
    # Calculate total definitions and tokens for successful parses
    {total_tokens, total_definitions} = results
    |> Enum.reduce({0, 0}, fn {_, result, _}, {tokens_acc, defs_acc} ->
      case result do
        {:success, token_count, def_count} -> {tokens_acc + token_count, defs_acc + def_count}
        _ -> {tokens_acc, defs_acc}
      end
    end)
    
    avg_duration = results
    |> Enum.map(fn {_, _, duration} -> duration end)
    |> Enum.sum()
    |> Kernel./(total_count)
    |> Float.round(1)
    
    IO.puts("📊 Overall Statistics:")
    IO.puts("   Total MIBs tested: #{total_count}")
    IO.puts("   ✅ Successful parses: #{successes} (#{success_rate}%)")
    IO.puts("   ❌ Parse errors: #{parse_errors}")
    IO.puts("   ❌ Tokenization errors: #{tokenize_errors}")
    IO.puts("   ❌ File errors: #{file_errors}")
    IO.puts("")
    IO.puts("📈 Success Metrics:")
    IO.puts("   Total tokens processed: #{total_tokens}")
    IO.puts("   Total definitions created: #{total_definitions}")
    IO.puts("   Average parse time: #{avg_duration}ms")
    IO.puts("")
    
    if successes > 0 do
      IO.puts("🎉 SUCCESSFULLY PARSED MIBs:")
      results
      |> Enum.filter(fn {_, result, _} -> 
        case result do
          {:success, _, _} -> true
          _ -> false
        end
      end)
      |> Enum.each(fn {filename, {:success, tokens, defs}, duration} ->
        IO.puts("   ✅ #{filename}: #{tokens} tokens → #{defs} definitions (#{Float.round(duration, 1)}ms)")
      end)
      IO.puts("")
    end
    
    if parse_errors > 0 || tokenize_errors > 0 do
      IO.puts("❌ FAILED MIBs:")
      results
      |> Enum.filter(fn {_, result, _} -> 
        case result do
          {:success, _, _} -> false
          {:file_error, _} -> false
          _ -> true
        end
      end)
      |> Enum.take(10) # Show first 10 failures
      |> Enum.each(fn {filename, result, duration} ->
        case result do
          {:parse_error, msg} ->
            IO.puts("   ❌ #{filename}: Parse error - #{String.slice(msg, 0, 60)}... (#{Float.round(duration, 1)}ms)")
          {:tokenize_error, msg} ->
            IO.puts("   ❌ #{filename}: Tokenize error - #{String.slice(msg, 0, 60)}... (#{Float.round(duration, 1)}ms)")
        end
      end)
      
      if (parse_errors + tokenize_errors) > 10 do
        IO.puts("   ... and #{(parse_errors + tokenize_errors) - 10} more failures")
      end
    end
    
    IO.puts("")
    cond do
      success_rate >= 90 ->
        IO.puts("🌟 EXCELLENT: #{success_rate}% success rate - DOCSIS MIB support is working very well!")
      success_rate >= 70 ->
        IO.puts("🎯 GOOD: #{success_rate}% success rate - Strong DOCSIS MIB support with some edge cases")
      success_rate >= 50 ->
        IO.puts("⚠️  MODERATE: #{success_rate}% success rate - Partial DOCSIS MIB support, needs improvement")
      success_rate >= 25 ->
        IO.puts("❌ POOR: #{success_rate}% success rate - Limited DOCSIS MIB support")
      true ->
        IO.puts("💥 CRITICAL: #{success_rate}% success rate - DOCSIS MIB support needs major work")
    end
    
    IO.puts(String.duplicate("=", 80))
  end
end

# Run the comprehensive test
ComprehensiveDocsisTest.run_complete_test()