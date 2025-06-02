# Test all DOCSIS MIBs with the grammar-based parser - using mix run
alias SnmpLib.MIB.{Parser, Lexer}

defmodule ComprehensiveDocsisTest do
  @docsis_dir "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/docsis"

  def run_test do
    IO.puts("=" |> String.duplicate(80))
    IO.puts("🔬 COMPREHENSIVE DOCSIS MIB TEST - PORTED PARSER")
    IO.puts("=" |> String.duplicate(80))
    IO.puts("Testing every MIB in #{@docsis_dir}")
    IO.puts("")

    # Get all MIB files
    mib_files = case File.ls(@docsis_dir) do
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

    total_count = length(mib_files)
    IO.puts("📊 Found #{total_count} MIB files")
    IO.puts("")

    # Test each MIB
    results = Enum.map(mib_files, &test_single_mib/1)
    
    # Print summary
    print_final_summary(results, total_count)
    
    results
  end

  defp test_single_mib(filename) do
    file_path = Path.join(@docsis_dir, filename)
    
    IO.puts("🔍 Testing #{filename}...")
    
    start_time = System.monotonic_time(:microsecond)
    
    result = case File.read(file_path) do
      {:ok, content} ->
        try do
          case Parser.parse(content) do
            {:ok, mib} ->
              def_count = length(mib.definitions)
              import_count = length(mib.imports)
              IO.puts("  ✅ Success: #{def_count} definitions, #{import_count} imports")
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
    
    end_time = System.monotonic_time(:microsecond)
    duration = (end_time - start_time) / 1000 # Convert to milliseconds
    
    {filename, result, duration}
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

  defp print_final_summary(results, total_count) do
    IO.puts("")
    IO.puts("=" |> String.duplicate(80))
    IO.puts("📈 FINAL COMPREHENSIVE RESULTS")
    IO.puts("=" |> String.duplicate(80))
    
    successes = Enum.count(results, fn {_, result, _} -> 
      case result do
        {:success, _, _} -> true
        _ -> false
      end
    end)
    
    parse_errors = Enum.count(results, fn {_, result, _} -> 
      case result do
        {:parse_error, _} -> true
        _ -> false
      end
    end)
    
    exceptions = Enum.count(results, fn {_, result, _} -> 
      case result do
        {:exception, _} -> true
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
    
    # Calculate totals for successful parses
    {total_definitions, total_imports} = results
    |> Enum.reduce({0, 0}, fn {_, result, _}, {defs_acc, imports_acc} ->
      case result do
        {:success, def_count, import_count} -> {defs_acc + def_count, imports_acc + import_count}
        _ -> {defs_acc, imports_acc}
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
    IO.puts("   💥 Exceptions: #{exceptions}")
    IO.puts("   📁 File errors: #{file_errors}")
    IO.puts("")
    IO.puts("📈 Success Metrics:")
    IO.puts("   Total definitions parsed: #{total_definitions}")
    IO.puts("   Total imports processed: #{total_imports}")
    IO.puts("   Average parse time: #{avg_duration}ms")
    IO.puts("")
    
    # Show successful MIBs
    if successes > 0 do
      IO.puts("🎉 SUCCESSFULLY PARSED MIBs:")
      results
      |> Enum.filter(fn {_, result, _} -> 
        case result do
          {:success, _, _} -> true
          _ -> false
        end
      end)
      |> Enum.each(fn {filename, {:success, defs, imports}, duration} ->
        IO.puts("   ✅ #{filename}: #{defs} definitions, #{imports} imports (#{Float.round(duration, 1)}ms)")
      end)
      IO.puts("")
    end
    
    # Show failed MIBs (first 5)
    failures = results
    |> Enum.filter(fn {_, result, _} -> 
      case result do
        {:success, _, _} -> false
        _ -> true
      end
    end)
    
    if length(failures) > 0 do
      IO.puts("❌ FAILED MIBs (showing first 5):")
      failures
      |> Enum.take(5)
      |> Enum.each(fn {filename, result, duration} ->
        case result do
          {:parse_error, msg} ->
            IO.puts("   ❌ #{filename}: #{String.slice(msg, 0, 50)}... (#{Float.round(duration, 1)}ms)")
          {:exception, msg} ->
            IO.puts("   💥 #{filename}: #{String.slice(msg, 0, 50)}... (#{Float.round(duration, 1)}ms)")
          {:file_error, reason} ->
            IO.puts("   📁 #{filename}: #{inspect(reason)} (#{Float.round(duration, 1)}ms)")
        end
      end)
      
      if length(failures) > 5 do
        IO.puts("   ... and #{length(failures) - 5} more failures")
      end
      IO.puts("")
    end
    
    # Final assessment
    IO.puts("🎯 DOCSIS COMPATIBILITY ASSESSMENT:")
    cond do
      success_rate >= 90 ->
        IO.puts("🌟 EXCELLENT: #{success_rate}% success - Ported parser handles DOCSIS MIBs very well!")
      success_rate >= 75 ->
        IO.puts("👍 GOOD: #{success_rate}% success - Strong DOCSIS support with minor issues")
      success_rate >= 50 ->
        IO.puts("⚠️  MODERATE: #{success_rate}% success - Decent DOCSIS support, some work needed")
      success_rate >= 25 ->
        IO.puts("❌ POOR: #{success_rate}% success - Limited DOCSIS support")
      true ->
        IO.puts("🚨 CRITICAL: #{success_rate}% success - Major DOCSIS compatibility issues")
    end
    
    IO.puts("=" |> String.duplicate(80))
  end
end

# Run the comprehensive test
ComprehensiveDocsisTest.run_test()