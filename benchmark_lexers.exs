#!/usr/bin/env elixir

defmodule LexerBenchmark do
  @moduledoc """
  Comprehensive performance benchmark comparing different lexer implementations:
  1. Custom lexer (original implementation)
  2. Basic Erlang port (1:1 charlist port)
  3. Optimized binary port (performance optimized version)
  """

  def run() do
    IO.puts("🚀 SNMP MIB Lexer Performance Benchmark")
    IO.puts("=" |> String.duplicate(50))
    
    # Load test content
    test_files = [
      {"Small MIB", load_test_mib()},
      {"DOCS-CABLE-DEVICE-MIB", load_file("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")},
      {"DOCS-QOS-MIB", load_file("test/fixtures/mibs/docsis/DOCS-QOS-MIB")},
      {"Large Synthetic", generate_large_mib()}
    ]
    
    lexer_versions = [
      {"Custom Lexer", "lib/snmp_lib/mib/lexer_custom.ex.bak", &test_custom_lexer/1},
      {"Basic Port", "lib/snmp_lib/mib/lexer_port_basic.ex.bak", &test_basic_port/1},
      {"Current Lexer", "lib/snmp_lib/mib/lexer.ex", &test_current_lexer/1}
    ]
    
    IO.puts("📊 Testing #{length(test_files)} test cases with #{length(lexer_versions)} lexer versions")
    IO.puts("")
    
    # Run benchmarks for each test file
    for {file_name, content} <- test_files do
      IO.puts("📄 Testing: #{file_name} (#{byte_size(content)} bytes)")
      IO.puts("-" |> String.duplicate(40))
      
      results = []
      
      for {lexer_name, lexer_file, test_func} <- lexer_versions do
        result = benchmark_lexer(lexer_name, lexer_file, test_func, content)
        results = [result | results]
        print_result(result)
      end
      
      # Print comparison
      print_comparison(results)
      IO.puts("")
    end
  end
  
  defp benchmark_lexer(name, lexer_file, test_func, content) do
    # Load the lexer module
    Code.compile_file(lexer_file)
    
    # Warmup runs
    for _i <- 1..3, do: test_func.(content)
    
    # Benchmark runs
    times = for _i <- 1..10 do
      start_time = System.monotonic_time(:microsecond)
      case test_func.(content) do
        {:ok, tokens} ->
          end_time = System.monotonic_time(:microsecond)
          {end_time - start_time, length(tokens)}
        {:error, _reason} ->
          end_time = System.monotonic_time(:microsecond)
          {end_time - start_time, 0}
      end
    end
    
    {durations, token_counts} = Enum.unzip(times)
    avg_duration = Enum.sum(durations) / length(durations)
    avg_tokens = Enum.sum(token_counts) / length(token_counts)
    
    tokens_per_sec = if avg_duration > 0, do: avg_tokens / avg_duration * 1_000_000, else: 0
    bytes_per_sec = if avg_duration > 0, do: byte_size(content) / avg_duration * 1_000_000, else: 0
    
    %{
      name: name,
      avg_duration_us: Float.round(avg_duration, 1),
      avg_tokens: Float.round(avg_tokens),
      tokens_per_sec: Float.round(tokens_per_sec),
      bytes_per_sec: Float.round(bytes_per_sec),
      file_size: byte_size(content)
    }
  end
  
  defp test_custom_lexer(content) do
    # The custom lexer had a different module structure
    # We'll need to adapt based on the actual implementation
    try do
      SnmpLib.MIB.Lexer.tokenize(content)
    rescue
      _ -> {:error, "module_error"}
    end
  end
  
  defp test_basic_port(content) do
    try do
      SnmpLib.MIB.Lexer.tokenize(content)
    rescue
      _ -> {:error, "module_error"}
    end
  end
  
  defp test_current_lexer(content) do
    try do
      SnmpLib.MIB.Lexer.tokenize(content)
    rescue
      _ -> {:error, "module_error"}
    end
  end
  
  defp print_result(result) do
    IO.puts("  #{result.name}:")
    IO.puts("    Time: #{result.avg_duration_us}μs")
    IO.puts("    Tokens: #{result.avg_tokens}")
    IO.puts("    Rate: #{format_number(result.tokens_per_sec)} tokens/sec")
    IO.puts("    Throughput: #{format_throughput(result.bytes_per_sec)}")
  end
  
  defp print_comparison(results) do
    # Sort by performance (fastest first)
    sorted = Enum.sort_by(results, & &1.avg_duration_us)
    baseline = List.first(sorted)
    
    IO.puts("  📈 Performance Comparison:")
    for result <- sorted do
      if result == baseline do
        IO.puts("    #{result.name}: Baseline (fastest)")
      else
        speedup = result.avg_duration_us / baseline.avg_duration_us
        IO.puts("    #{result.name}: #{Float.round(speedup, 2)}x slower")
      end
    end
  end
  
  defp format_number(num) when num >= 1_000_000 do
    "#{Float.round(num / 1_000_000, 1)}M"
  end
  
  defp format_number(num) when num >= 1_000 do
    "#{Float.round(num / 1_000, 1)}K"
  end
  
  defp format_number(num) do
    "#{Float.round(num)}"
  end
  
  defp format_throughput(bytes_per_sec) do
    mb_per_sec = bytes_per_sec / 1_024 / 1_024
    "#{Float.round(mb_per_sec, 2)} MB/s"
  end
  
  defp load_test_mib() do
    """
    TestMib DEFINITIONS ::= BEGIN
      IMPORTS
        MODULE-IDENTITY, OBJECT-TYPE, Integer32, Counter32
        FROM SNMPv2-SMI;
      
      testObject OBJECT-TYPE
        SYNTAX INTEGER { active(1), inactive(2) }
        MAX-ACCESS read-only
        STATUS current
        DESCRIPTION "Test object for benchmarking"
        ::= { test 1 }
        
      testTable OBJECT-TYPE
        SYNTAX SEQUENCE OF TestEntry
        MAX-ACCESS not-accessible
        STATUS current
        DESCRIPTION "Test table"
        ::= { test 2 }
        
      testEntry OBJECT-TYPE
        SYNTAX TestEntry
        MAX-ACCESS not-accessible
        STATUS current
        DESCRIPTION "Test entry"
        INDEX { testIndex }
        ::= { testTable 1 }
        
      TestEntry ::= SEQUENCE {
        testIndex Integer32,
        testValue Counter32
      }
    END
    """
  end
  
  defp load_file(path) do
    case File.read(path) do
      {:ok, content} -> content
      {:error, _} -> 
        IO.puts("⚠️  Could not load #{path}, using fallback")
        load_test_mib()
    end
  end
  
  defp generate_large_mib() do
    # Generate a synthetic large MIB for stress testing
    header = """
    LargeMib DEFINITIONS ::= BEGIN
      IMPORTS
        MODULE-IDENTITY, OBJECT-TYPE, Integer32, Counter32, Counter64
        FROM SNMPv2-SMI
        DisplayString, RowStatus
        FROM SNMPv2-TC;
    """
    
    # Generate many object definitions
    objects = for i <- 1..1000 do
      """
        testObject#{i} OBJECT-TYPE
          SYNTAX Counter#{if rem(i, 2) == 0, do: "32", else: "64"}
          MAX-ACCESS read-only
          STATUS current
          DESCRIPTION "Generated test object #{i} for performance testing"
          ::= { testOid #{i} }
      """
    end
    
    footer = "END\n"
    
    header <> Enum.join(objects, "\n") <> footer
  end
end

# Run the benchmark
LexerBenchmark.run()