#!/usr/bin/env elixir

defmodule CorrectedBenchmark do
  @moduledoc """
  Honest performance comparison of working lexer implementations.
  """

  def run() do
    IO.puts("🔍 CORRECTED SNMP MIB Lexer Performance Analysis")
    IO.puts("=" |> String.duplicate(55))
    
    # Test data
    test_files = [
      {"DOCS-CABLE-DEVICE-MIB", load_file("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")},
      {"DOCS-QOS-MIB", load_file("test/fixtures/mibs/docsis/DOCS-QOS-MIB")}
    ]
    
    IO.puts("Testing ONLY the working lexer implementations:")
    IO.puts("1. Basic Port (Erlang port using charlists)")  
    IO.puts("2. Current Lexer (Updated port with symbol handling)")
    IO.puts("")
    
    for {file_name, content} <- test_files do
      IO.puts("📄 #{file_name} (#{format_size(byte_size(content))})")
      IO.puts("-" |> String.duplicate(50))
      
      # Test Basic Port
      basic_result = benchmark_basic_port(content)
      IO.puts("Basic Port:")
      IO.puts("  Time: #{basic_result.avg_duration_us}μs")
      IO.puts("  Tokens: #{basic_result.avg_tokens}")
      IO.puts("  Rate: #{format_number(basic_result.tokens_per_sec)} tokens/sec")
      IO.puts("  Throughput: #{format_throughput(basic_result.bytes_per_sec)}")
      
      # Test Current Lexer  
      current_result = benchmark_current_lexer(content)
      IO.puts("Current Lexer:")
      IO.puts("  Time: #{current_result.avg_duration_us}μs")
      IO.puts("  Tokens: #{current_result.avg_tokens}")
      IO.puts("  Rate: #{format_number(current_result.tokens_per_sec)} tokens/sec")
      IO.puts("  Throughput: #{format_throughput(current_result.bytes_per_sec)}")
      
      # Performance comparison
      if basic_result.avg_duration_us > 0 and current_result.avg_duration_us > 0 do
        if current_result.avg_duration_us < basic_result.avg_duration_us do
          improvement = basic_result.avg_duration_us / current_result.avg_duration_us
          IO.puts("✅ Current Lexer is #{Float.round(improvement, 2)}x FASTER")
        else
          regression = current_result.avg_duration_us / basic_result.avg_duration_us  
          IO.puts("❌ Current Lexer is #{Float.round(regression, 2)}x SLOWER")
        end
      end
      
      IO.puts("")
    end
    
    IO.puts("📊 HONEST CONCLUSION:")
    IO.puts("Without proper before/after benchmarking, any performance claims are invalid.")
    IO.puts("This benchmark shows the actual performance difference between implementations.")
  end
  
  defp benchmark_basic_port(content) do
    # Load basic port module
    Code.compile_file("lib/snmp_lib/mib/lexer_port_basic.ex.bak")
    
    # Warmup
    for _i <- 1..3, do: SnmpLib.MIB.Lexer.tokenize(content)
    
    # Benchmark
    times = for _i <- 1..10 do
      start_time = System.monotonic_time(:microsecond)
      result = SnmpLib.MIB.Lexer.tokenize(content)
      end_time = System.monotonic_time(:microsecond)
      
      case result do
        {:ok, tokens} -> {end_time - start_time, length(tokens)}
        {:error, _} -> {end_time - start_time, 0}
      end
    end
    
    calculate_stats(times, content)
  end
  
  defp benchmark_current_lexer(content) do
    # Load current lexer module
    Code.compile_file("lib/snmp_lib/mib/lexer.ex")
    
    # Warmup
    for _i <- 1..3, do: SnmpLib.MIB.Lexer.tokenize(content)
    
    # Benchmark  
    times = for _i <- 1..10 do
      start_time = System.monotonic_time(:microsecond)
      result = SnmpLib.MIB.Lexer.tokenize(content)
      end_time = System.monotonic_time(:microsecond)
      
      case result do
        {:ok, tokens} -> {end_time - start_time, length(tokens)}
        {:error, _} -> {end_time - start_time, 0}
      end
    end
    
    calculate_stats(times, content)
  end
  
  defp calculate_stats(times, content) do
    {durations, token_counts} = Enum.unzip(times)
    avg_duration = Enum.sum(durations) / length(durations)
    avg_tokens = Enum.sum(token_counts) / length(token_counts)
    
    tokens_per_sec = if avg_duration > 0, do: avg_tokens / avg_duration * 1_000_000, else: 0
    bytes_per_sec = if avg_duration > 0, do: byte_size(content) / avg_duration * 1_000_000, else: 0
    
    %{
      avg_duration_us: Float.round(avg_duration, 1),
      avg_tokens: Float.round(avg_tokens),
      tokens_per_sec: tokens_per_sec,
      bytes_per_sec: bytes_per_sec
    }
  end
  
  defp load_file(path) do
    case File.read(path) do
      {:ok, content} -> content
      {:error, _} -> 
        """
        TestMib DEFINITIONS ::= BEGIN
          testObject OBJECT-TYPE
            SYNTAX INTEGER
            ACCESS read-only  
            STATUS current
            DESCRIPTION "Fallback test"
            ::= { test 1 }
        END
        """
    end
  end
  
  defp format_size(bytes) when bytes >= 1024 * 1024 do
    "#{Float.round(bytes / 1024 / 1024, 1)}MB"
  end
  
  defp format_size(bytes) when bytes >= 1024 do
    "#{Float.round(bytes / 1024, 1)}KB"
  end
  
  defp format_size(bytes), do: "#{bytes}B"
  
  defp format_number(num) when num >= 1_000_000 do
    "#{Float.round(num / 1_000_000, 1)}M"
  end
  
  defp format_number(num) when num >= 1_000 do
    "#{Float.round(num / 1_000, 1)}K"
  end
  
  defp format_number(num), do: "#{Float.round(num)}"
  
  defp format_throughput(bytes_per_sec) do
    mb_per_sec = bytes_per_sec / 1_024 / 1_024
    "#{Float.round(mb_per_sec, 2)}MB/s"
  end
end

CorrectedBenchmark.run()