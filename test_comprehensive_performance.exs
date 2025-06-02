#!/usr/bin/env elixir

System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

defmodule ComprehensivePerformanceTest do
  @test_dirs [
    {"working", "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working"},
    {"broken", "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/broken"},
    {"docsis", "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/docsis"}
  ]

  def run_comprehensive_test do
    IO.puts("🚀 COMPREHENSIVE LEXER PERFORMANCE TEST")
    IO.puts("Testing optimized lexer against all MIB directories...")
    IO.puts("=" <> String.duplicate("=", 60))
    
    total_files = 0
    total_tokens = 0
    total_time = 0
    total_bytes = 0
    successful_files = 0
    failed_files = []
    
    results = for {dir_name, dir_path} <- @test_dirs do
      IO.puts("\n📁 Testing #{String.upcase(dir_name)} MIBs")
      IO.puts("-" <> String.duplicate("-", 40))
      
      case File.ls(dir_path) do
        {:ok, files} ->
          mib_files = files
            |> Enum.filter(fn file -> 
              String.ends_with?(file, [".mib", ".MIB"]) or 
              not String.contains?(file, ".")
            end)
            |> Enum.sort()
          
          IO.puts("Found #{length(mib_files)} MIB files")
          
          dir_results = test_directory(dir_path, mib_files)
          
          {
            dir_name,
            dir_results[:successful],
            dir_results[:failed],
            dir_results[:total_tokens],
            dir_results[:total_time],
            dir_results[:total_bytes],
            dir_results[:file_count]
          }
          
        {:error, reason} ->
          IO.puts("❌ Error reading directory: #{reason}")
          {dir_name, 0, [], 0, 0, 0, 0}
      end
    end
    
    # Aggregate results
    {total_files, total_tokens, total_time, total_bytes, successful_files, failed_files} = 
      Enum.reduce(results, {0, 0, 0, 0, 0, []}, fn 
        {dir_name, successful, failed, tokens, time, bytes, file_count}, 
        {acc_files, acc_tokens, acc_time, acc_bytes, acc_successful, acc_failed} ->
          {
            acc_files + file_count,
            acc_tokens + tokens,
            acc_time + time,
            acc_bytes + bytes,
            acc_successful + successful,
            acc_failed ++ (failed |> Enum.map(&{dir_name, &1}))
          }
      end)
    
    print_summary(results, total_files, total_tokens, total_time, total_bytes, 
                  successful_files, failed_files)
  end
  
  defp test_directory(dir_path, mib_files) do
    results = mib_files
      |> Enum.map(fn file ->
        file_path = Path.join(dir_path, file)
        test_single_file(file_path, file)
      end)
    
    successful = results |> Enum.count(fn {status, _} -> status == :ok end)
    failed = results |> Enum.filter(fn {status, _} -> status == :error end) |> Enum.map(fn {_, data} -> data end)
    
    totals = results
      |> Enum.filter(fn {status, _} -> status == :ok end)
      |> Enum.map(fn {_, data} -> data end)
      |> Enum.reduce({0, 0, 0}, fn {tokens, time, bytes}, {acc_tokens, acc_time, acc_bytes} ->
        {acc_tokens + tokens, acc_time + time, acc_bytes + bytes}
      end)
    
    {total_tokens, total_time, total_bytes} = totals
    
    IO.puts("  ✅ Successful: #{successful}/#{length(mib_files)}")
    if length(failed) > 0 do
      IO.puts("  ❌ Failed: #{length(failed)}")
    end
    
    if successful > 0 do
      avg_rate = total_tokens / total_time * 1_000_000
      avg_throughput = total_bytes / total_time * 1_000_000 / 1_000_000
      IO.puts("  📊 Avg Rate: #{Float.round(avg_rate / 1_000_000, 2)}M tokens/sec")
      IO.puts("  📊 Avg Throughput: #{Float.round(avg_throughput, 2)}MB/sec")
    end
    
    %{
      successful: successful,
      failed: failed,
      total_tokens: total_tokens,
      total_time: total_time,
      total_bytes: total_bytes,
      file_count: length(mib_files)
    }
  end
  
  defp test_single_file(file_path, file_name) do
    case File.read(file_path) do
      {:ok, content} ->
        # Warm up
        for _i <- 1..3, do: SnmpLib.MIB.Lexer.tokenize(content)
        
        # Performance test
        times = for _i <- 1..10 do
          start = :erlang.monotonic_time(:microsecond)
          result = SnmpLib.MIB.Lexer.tokenize(content)
          stop = :erlang.monotonic_time(:microsecond)
          {stop - start, result}
        end
        
        # Check for successful tokenization
        case List.last(times) do
          {_, {:ok, tokens}} ->
            durations = times |> Enum.map(fn {time, _} -> time end)
            avg_time = Enum.sum(durations) / length(durations)
            token_count = length(tokens)
            byte_count = byte_size(content)
            
            rate = token_count / avg_time * 1_000_000
            
            if rate > 10_000_000 do
              IO.puts("  🚀 #{file_name}: #{Float.round(rate / 1_000_000, 1)}M tok/s (#{token_count} tokens)")
            end
            
            {:ok, {token_count, avg_time, byte_count}}
            
          {_, {:error, reason}} ->
            IO.puts("  ❌ #{file_name}: #{reason}")
            {:error, {file_name, reason}}
        end
        
      {:error, reason} ->
        IO.puts("  ❌ #{file_name}: File read error - #{reason}")
        {:error, {file_name, "File read error: #{reason}"}}
    end
  end
  
  defp print_summary(results, total_files, total_tokens, total_time, total_bytes, 
                     successful_files, failed_files) do
    IO.puts("\n" <> "=" <> String.duplicate("=", 60))
    IO.puts("📊 COMPREHENSIVE TEST SUMMARY")
    IO.puts("=" <> String.duplicate("=", 60))
    
    # Overall statistics
    IO.puts("\n🎯 OVERALL PERFORMANCE")
    IO.puts("Total Files Tested: #{total_files}")
    IO.puts("Successful: #{successful_files} (#{Float.round(successful_files/total_files*100, 1)}%)")
    IO.puts("Failed: #{length(failed_files)} (#{Float.round(length(failed_files)/total_files*100, 1)}%)")
    
    if successful_files > 0 do
      overall_rate = total_tokens / total_time * 1_000_000
      overall_throughput = total_bytes / total_time * 1_000_000 / 1_000_000
      
      IO.puts("\nTotal Tokens: #{format_number(total_tokens)}")
      IO.puts("Total Time: #{Float.round(total_time / 1_000, 1)}ms")
      IO.puts("Total Data: #{Float.round(total_bytes / 1_000_000, 1)}MB")
      IO.puts("")
      IO.puts("🚀 OVERALL RATE: #{Float.round(overall_rate / 1_000_000, 2)}M tokens/sec")
      IO.puts("🚀 OVERALL THROUGHPUT: #{Float.round(overall_throughput, 2)}MB/sec")
      
      # Compare to baseline
      baseline_rate = 5_200_000  # tokens/sec
      improvement = overall_rate / baseline_rate
      
      IO.puts("\n📈 BASELINE COMPARISON")
      IO.puts("Current: #{Float.round(overall_rate / 1_000_000, 2)}M tokens/sec")
      IO.puts("Baseline: #{Float.round(baseline_rate / 1_000_000, 2)}M tokens/sec")
      IO.puts("Improvement: #{Float.round(improvement, 2)}x (#{Float.round((improvement - 1) * 100, 1)}%)")
      
      cond do
        improvement >= 2.0 ->
          IO.puts("🎉 EXCELLENT: Achieved 2x+ target performance!")
        improvement >= 1.5 ->
          IO.puts("✅ VERY GOOD: Strong performance improvement")
        improvement >= 1.2 ->
          IO.puts("📈 GOOD: Solid performance improvement")
        improvement >= 1.0 ->
          IO.puts("✔️  BASELINE: Meeting baseline performance")
        true ->
          IO.puts("⚠️  REGRESSION: Below baseline performance")
      end
    end
    
    # Directory breakdown
    IO.puts("\n📁 DIRECTORY BREAKDOWN")
    for {dir_name, successful, failed, tokens, time, bytes, file_count} <- results do
      IO.puts("\n#{String.upcase(dir_name)} Directory:")
      IO.puts("  Files: #{file_count}")
      IO.puts("  Success Rate: #{successful}/#{file_count} (#{Float.round(successful/file_count*100, 1)}%)")
      
      if successful > 0 do
        rate = tokens / time * 1_000_000
        throughput = bytes / time * 1_000_000 / 1_000_000
        IO.puts("  Performance: #{Float.round(rate / 1_000_000, 2)}M tokens/sec")
        IO.puts("  Throughput: #{Float.round(throughput, 2)}MB/sec")
      end
    end
    
    # Failed files details
    if length(failed_files) > 0 do
      IO.puts("\n❌ FAILED FILES")
      for {dir_name, {file_name, reason}} <- failed_files do
        IO.puts("  #{dir_name}/#{file_name}: #{reason}")
      end
    end
    
    IO.puts("\n🏁 Test completed!")
  end
  
  defp format_number(num) when num >= 1_000_000 do
    "#{Float.round(num / 1_000_000, 1)}M"
  end
  
  defp format_number(num) when num >= 1_000 do
    "#{Float.round(num / 1_000, 1)}K"
  end
  
  defp format_number(num) do
    "#{num}"
  end
end

ComprehensivePerformanceTest.run_comprehensive_test()