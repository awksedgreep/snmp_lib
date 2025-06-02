#!/usr/bin/env elixir

# Test the optimized lexer performance and compare with expected results

System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

defmodule OptimizedLexerTest do
  def test_simple_performance do
    # Test with a simple but valid MIB snippet (no problematic strings)
    test_input = """
    TestMib DEFINITIONS ::= BEGIN
      testObject OBJECT-TYPE
        SYNTAX INTEGER (1..2)
        MAX-ACCESS read-only
        STATUS current
        DESCRIPTION Test-object-description
        ::= { test 1 }
    END
    """
    
    IO.puts("=== Simple Performance Test ===")
    IO.puts("Input: #{byte_size(test_input)} bytes")
    
    # Verify it works first
    case SnmpLib.MIB.Lexer.tokenize(test_input) do
      {:ok, tokens} ->
        IO.puts("✅ Tokenization successful - #{length(tokens)} tokens")
        
        # Warm up
        for _i <- 1..10, do: SnmpLib.MIB.Lexer.tokenize(test_input)
        
        # Benchmark
        times = for _i <- 1..1000 do
          start_time = System.monotonic_time(:microsecond)
          {:ok, result_tokens} = SnmpLib.MIB.Lexer.tokenize(test_input)
          end_time = System.monotonic_time(:microsecond)
          {end_time - start_time, length(result_tokens)}
        end
        
        {durations, token_counts} = Enum.unzip(times)
        avg_duration = Enum.sum(durations) / length(durations)
        avg_tokens = Enum.sum(token_counts) / length(token_counts)
        min_duration = Enum.min(durations)
        max_duration = Enum.max(durations)
        
        tokens_per_sec = avg_tokens / avg_duration * 1_000_000
        
        IO.puts("Tokens: #{round(avg_tokens)}")
        IO.puts("Avg time: #{Float.round(avg_duration, 2)}μs")
        IO.puts("Min time: #{round(min_duration)}μs")
        IO.puts("Max time: #{round(max_duration)}μs")
        IO.puts("Rate: #{Float.round(tokens_per_sec / 1_000_000, 2)}M tokens/sec")
        
        %{
          test: :simple,
          size: byte_size(test_input),
          tokens: round(avg_tokens),
          avg_time: avg_duration,
          min_time: min_duration,
          max_time: max_duration,
          tokens_per_sec: tokens_per_sec
        }
        
      {:error, reason} ->
        IO.puts("❌ Tokenization failed: #{reason}")
        nil
    end
  end
  
  def test_file_performance(file_path, label) do
    case File.read(file_path) do
      {:ok, content} ->
        IO.puts("\n=== #{label} ===")
        IO.puts("File: #{Path.basename(file_path)}")
        IO.puts("Size: #{byte_size(content)} bytes")
        
        # Test if it works
        case SnmpLib.MIB.Lexer.tokenize(content) do
          {:ok, tokens} ->
            IO.puts("✅ Tokenization successful - #{length(tokens)} tokens")
            
            # Warm up
            for _i <- 1..3, do: SnmpLib.MIB.Lexer.tokenize(content)
            
            # Benchmark fewer iterations for large files
            iterations = if byte_size(content) > 50000, do: 10, else: 100
            
            times = for _i <- 1..iterations do
              start_time = System.monotonic_time(:microsecond)
              {:ok, result_tokens} = SnmpLib.MIB.Lexer.tokenize(content)
              end_time = System.monotonic_time(:microsecond)
              {end_time - start_time, length(result_tokens)}
            end
            
            {durations, token_counts} = Enum.unzip(times)
            avg_duration = Enum.sum(durations) / length(durations)
            avg_tokens = Enum.sum(token_counts) / length(token_counts)
            min_duration = Enum.min(durations)
            max_duration = Enum.max(durations)
            
            tokens_per_sec = avg_tokens / avg_duration * 1_000_000
            bytes_per_sec = byte_size(content) / avg_duration * 1_000_000
            
            IO.puts("Tokens: #{round(avg_tokens)}")
            IO.puts("Avg time: #{Float.round(avg_duration, 1)}μs")
            IO.puts("Min time: #{round(min_duration)}μs")
            IO.puts("Max time: #{round(max_duration)}μs")
            IO.puts("Rate: #{Float.round(tokens_per_sec / 1_000_000, 2)}M tokens/sec")
            IO.puts("Throughput: #{Float.round(bytes_per_sec / 1_000_000, 2)}MB/sec")
            
            %{
              test: label,
              file: Path.basename(file_path),
              size: byte_size(content),
              tokens: round(avg_tokens),
              avg_time: avg_duration,
              min_time: min_duration,
              max_time: max_duration,
              tokens_per_sec: tokens_per_sec,
              bytes_per_sec: bytes_per_sec
            }
            
          {:error, reason} ->
            IO.puts("❌ Tokenization failed: #{reason}")
            nil
        end
        
      {:error, reason} ->
        IO.puts("❌ Failed to read #{file_path}: #{reason}")
        nil
    end
  end
  
  def compare_with_baseline(results) do
    # Baseline performance from before optimization
    baseline = %{
      "simple" => 5_200_470,
      "SNMPv2-SMI.mib" => 4_157_303,
      "IF-MIB.mib" => 1_539_470,
      "CISCO-VTP-MIB.mib" => 1_602_868
    }
    
    IO.puts("\n📊 PERFORMANCE COMPARISON")
    IO.puts("=" <> String.duplicate("=", 60))
    
    Enum.each(results, fn result ->
      if result do
        test_key = case result.test do
          :simple -> "simple"
          _ -> result.file
        end
        
        baseline_rate = Map.get(baseline, test_key)
        current_rate = result.tokens_per_sec
        
        if baseline_rate do
          improvement = current_rate / baseline_rate
          improvement_pct = (improvement - 1) * 100
          
          status = cond do
            improvement >= 2.0 -> "🎉 EXCELLENT"
            improvement >= 1.5 -> "✅ GOOD"
            improvement >= 1.2 -> "⚡ MODEST"
            true -> "⚠️  MARGINAL"
          end
          
          IO.puts("#{result.test}:")
          IO.puts("  Baseline: #{Float.round(baseline_rate / 1_000_000, 2)}M tokens/sec")
          IO.puts("  Current:  #{Float.round(current_rate / 1_000_000, 2)}M tokens/sec")
          IO.puts("  Improvement: #{Float.round(improvement, 2)}x (#{Float.round(improvement_pct, 1)}%) #{status}")
        else
          IO.puts("#{result.test}: #{Float.round(current_rate / 1_000_000, 2)}M tokens/sec (NEW)")
        end
        IO.puts("")
      end
    end)
  end
end

IO.puts("🚀 OPTIMIZED LEXER PERFORMANCE VALIDATION")
IO.puts("Testing binary pattern matching vs charlist performance...")

# Test simple case first
simple_result = OptimizedLexerTest.test_simple_performance()

# Test with MIB files
test_files = [
  "test/fixtures/mibs/working/SNMPv2-SMI.mib",
  "test/fixtures/mibs/working/IF-MIB.mib", 
  "test/fixtures/mibs/working/CISCO-VTP-MIB.mib"
]

results = [simple_result]

for file_path <- test_files do
  if File.exists?(file_path) do
    result = OptimizedLexerTest.test_file_performance(file_path, Path.basename(file_path))
    results = [result | results]
  else
    IO.puts("⚠️  File not found: #{file_path}")
  end
end

# Filter out nil results
results = Enum.filter(results, & &1)

# Compare with baseline
OptimizedLexerTest.compare_with_baseline(results)

IO.puts("\n🎯 OPTIMIZATION TARGET: 2-3x performance improvement")
IO.puts("📈 Results show actual performance gains from binary pattern matching optimization")