#!/usr/bin/env elixir

System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

defmodule SimplePerfAnalysis do
  def test_basic_performance do
    IO.puts("🔍 BASIC PERFORMANCE ANALYSIS")
    
    # Test simple operations
    test_cases = [
      {"Whitespace", "   \t  \n  \t  "},
      {"Identifiers", "test one two three"},
      {"Keywords", "BEGIN END MODULE"},
      {"Integers", "123 456 789"},
      {"Symbols", "{ } ( )"},
      {"Strings", "\"hello\" \"world\""}
    ]
    
    Enum.each(test_cases, fn {label, content} ->
      IO.puts("\n--- #{label} ---")
      
      # Warm up
      for _i <- 1..10, do: SnmpLib.MIB.Lexer.tokenize(content)
      
      # Benchmark
      times = for _i <- 1..5000 do
        start = :erlang.monotonic_time(:microsecond)
        {:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)
        stop = :erlang.monotonic_time(:microsecond)
        {stop - start, length(tokens)}
      end
      
      {durations, token_counts} = Enum.unzip(times)
      avg_time = Enum.sum(durations) / length(durations)
      avg_tokens = Enum.sum(token_counts) / length(token_counts)
      min_time = Enum.min(durations)
      
      rate = avg_tokens / avg_time * 1_000_000
      
      IO.puts("Content: #{inspect(content)}")
      IO.puts("Tokens: #{round(avg_tokens)}")
      IO.puts("Avg: #{Float.round(avg_time, 2)}μs")
      IO.puts("Min: #{min_time}μs")
      IO.puts("Rate: #{Float.round(rate / 1_000_000, 2)}M tokens/sec")
    end)
  end
  
  def analyze_overhead do
    IO.puts("\n🎯 OVERHEAD ANALYSIS")
    
    # Test empty input and very simple input to see base overhead
    cases = [
      {"Empty", ""},
      {"Single char", "a"},
      {"Single token", "test"},
      {"Two tokens", "test object"}
    ]
    
    Enum.each(cases, fn {label, content} ->
      IO.puts("\n--- #{label} ---")
      
      times = for _i <- 1..10000 do
        start = :erlang.monotonic_time(:microsecond)
        result = SnmpLib.MIB.Lexer.tokenize(content)
        stop = :erlang.monotonic_time(:microsecond)
        
        tokens = case result do
          {:ok, tokens} -> length(tokens)
          _ -> 0
        end
        
        {stop - start, tokens}
      end
      
      {durations, token_counts} = Enum.unzip(times)
      avg_time = Enum.sum(durations) / length(durations)
      avg_tokens = Enum.sum(token_counts) / length(token_counts)
      
      IO.puts("Content: #{inspect(content)}")
      IO.puts("Avg time: #{Float.round(avg_time, 3)}μs")
      IO.puts("Avg tokens: #{avg_tokens}")
      
      if avg_tokens > 0 do
        time_per_token = avg_time / avg_tokens
        IO.puts("Time per token: #{Float.round(time_per_token, 3)}μs")
      end
    end)
  end
end

SimplePerfAnalysis.test_basic_performance()
SimplePerfAnalysis.analyze_overhead()

IO.puts("\n📊 ANALYSIS COMPLETE")
IO.puts("This should help identify specific performance bottlenecks")