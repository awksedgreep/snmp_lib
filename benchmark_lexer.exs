#!/usr/bin/env elixir

# Benchmark the current lexer performance

System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

defmodule LexerBenchmark do
  def benchmark_file(file_path, label) do
    case File.read(file_path) do
      {:ok, content} ->
        IO.puts("\n=== #{label} ===")
        IO.puts("File: #{Path.basename(file_path)}")
        IO.puts("Size: #{byte_size(content)} bytes")
        
        # Warm up
        SnmpLib.MIB.Lexer.tokenize(content)
        
        # Benchmark multiple runs
        times = for _i <- 1..10 do
          start_time = System.monotonic_time(:microsecond)
          {:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)
          end_time = System.monotonic_time(:microsecond)
          {end_time - start_time, length(tokens)}
        end
        
        {durations, token_counts} = Enum.unzip(times)
        avg_duration = Enum.sum(durations) / length(durations)
        avg_tokens = Enum.sum(token_counts) / length(token_counts)
        min_duration = Enum.min(durations)
        max_duration = Enum.max(durations)
        
        IO.puts("Avg tokens: #{round(avg_tokens)}")
        IO.puts("Avg time: #{round(avg_duration)}μs")
        IO.puts("Min time: #{round(min_duration)}μs") 
        IO.puts("Max time: #{round(max_duration)}μs")
        IO.puts("Rate: #{round(avg_tokens / avg_duration * 1_000_000)} tokens/sec")
        IO.puts("Throughput: #{Float.round(byte_size(content) / avg_duration, 2)} bytes/μs")
        
        %{
          file: Path.basename(file_path),
          size: byte_size(content),
          tokens: round(avg_tokens),
          avg_time: avg_duration,
          min_time: min_duration,
          max_time: max_duration,
          tokens_per_sec: avg_tokens / avg_duration * 1_000_000,
          bytes_per_us: byte_size(content) / avg_duration
        }
        
      {:error, reason} ->
        IO.puts("❌ Failed to read #{file_path}: #{reason}")
        nil
    end
  end
  
  def simple_test() do
    test_input = """
    TestMib DEFINITIONS ::= BEGIN
      testObject OBJECT-TYPE
        SYNTAX INTEGER { active(1), inactive(2) }
        MAX-ACCESS read-only
        STATUS current
        DESCRIPTION "Test object"
        ::= { test 1 }
    END
    """
    
    IO.puts("=== Simple Test ===")
    IO.puts("Input: #{byte_size(test_input)} bytes")
    
    # Warm up
    SnmpLib.MIB.Lexer.tokenize(test_input)
    
    # Benchmark
    times = for _i <- 1..1000 do
      start_time = System.monotonic_time(:microsecond)
      {:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(test_input)
      end_time = System.monotonic_time(:microsecond)
      {end_time - start_time, length(tokens)}
    end
    
    {durations, token_counts} = Enum.unzip(times)
    avg_duration = Enum.sum(durations) / length(durations)
    avg_tokens = Enum.sum(token_counts) / length(token_counts)
    
    IO.puts("Avg tokens: #{round(avg_tokens)}")
    IO.puts("Avg time: #{Float.round(avg_duration, 2)}μs")
    IO.puts("Rate: #{round(avg_tokens / avg_duration * 1_000_000)} tokens/sec")
    
    %{
      type: :simple,
      size: byte_size(test_input),
      tokens: round(avg_tokens),
      avg_time: avg_duration,
      tokens_per_sec: avg_tokens / avg_duration * 1_000_000
    }
  end
end

IO.puts("🚀 CURRENT LEXER PERFORMANCE BENCHMARK")

# Simple test
simple_result = LexerBenchmark.simple_test()

# Test with various MIB files
test_files = [
  "test/fixtures/mibs/working/SNMPv2-SMI.mib",
  "test/fixtures/mibs/working/IF-MIB.mib", 
  "test/fixtures/mibs/working/HOST-RESOURCES-MIB.mib",
  "test/fixtures/mibs/working/CISCO-VTP-MIB.mib",
  "test/fixtures/mibs/docsis/DOCS-IF31-MIB"
]

results = []

for file_path <- test_files do
  if File.exists?(file_path) do
    result = LexerBenchmark.benchmark_file(file_path, "MIB File Test")
    if result, do: results = [result | results]
  else
    IO.puts("⚠️  File not found: #{file_path}")
  end
end

results = [simple_result | results]

IO.puts("\n📊 PERFORMANCE SUMMARY")
IO.puts("=" <> String.duplicate("=", 60))

results
|> Enum.each(fn result ->
  case result do
    %{type: :simple} ->
      IO.puts("Simple Test: #{round(result.tokens_per_sec)} tokens/sec")
    _ ->
      IO.puts("#{result.file}: #{round(result.tokens_per_sec)} tokens/sec (#{result.tokens} tokens, #{round(result.avg_time)}μs)")
  end
end)

total_tokens = results |> Enum.map(&Map.get(&1, :tokens)) |> Enum.sum()
total_time = results |> Enum.map(&Map.get(&1, :avg_time)) |> Enum.sum()
overall_rate = total_tokens / total_time * 1_000_000

IO.puts("\nOverall Rate: #{round(overall_rate)} tokens/sec")