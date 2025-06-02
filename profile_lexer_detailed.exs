#!/usr/bin/env elixir

# Detailed profiling to understand why binary pattern matching isn't faster

System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

defmodule LexerProfiler do
  def profile_simple_operations do
    IO.puts("🔍 DETAILED LEXER PROFILING")
    IO.puts("=" <> String.duplicate("=", 50))
    
    # Test different types of content to see where performance issues are
    test_cases = [
      {"Simple identifiers", "test one two three four five"},
      {"Keywords", "BEGIN END MODULE OBJECT-TYPE STATUS"},
      {"Integers", "123 456 789 1024 2048 4096"},
      {"Symbols", "{ } ( ) [ ] , . ; | : ="},
      {"Mixed content", "TestMib DEFINITIONS ::= BEGIN testObject INTEGER END"}
    ]
    
    for {label, content} <- test_cases do
      IO.puts("\n--- #{label} ---")
      IO.puts("Content: #{content}")
      profile_content(content)
    end
  end
  
  def profile_content(content) do
    # Warm up
    for _i <- 1..10, do: SnmpLib.MIB.Lexer.tokenize(content)
    
    # Profile with many iterations for small content
    iterations = 10000
    
    times = for _i <- 1..iterations do
      start_time = System.monotonic_time(:microsecond)
      {:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)
      end_time = System.monotonic_time(:microsecond)
      {end_time - start_time, length(tokens)}
    end
    
    {durations, token_counts} = Enum.unzip(times)
    avg_duration = Enum.sum(durations) / length(durations)
    avg_tokens = Enum.sum(token_counts) / length(token_counts)
    min_duration = Enum.min(durations)
    
    tokens_per_sec = avg_tokens / avg_duration * 1_000_000
    chars_per_sec = byte_size(content) / avg_duration * 1_000_000
    
    IO.puts("  Bytes: #{byte_size(content)}")
    IO.puts("  Tokens: #{round(avg_tokens)}")
    IO.puts("  Avg time: #{Float.round(avg_duration, 3)}μs")
    IO.puts("  Min time: #{Float.round(min_duration, 3)}μs")
    IO.puts("  Rate: #{Float.round(tokens_per_sec / 1_000_000, 2)}M tokens/sec")
    IO.puts("  Throughput: #{Float.round(chars_per_sec / 1_000_000, 2)}M chars/sec")
    
    # Calculate efficiency metrics
    chars_per_token = byte_size(content) / avg_tokens
    time_per_char = avg_duration / byte_size(content)
    time_per_token = avg_duration / avg_tokens
    
    IO.puts("  Efficiency:")
    IO.puts("    #{Float.round(chars_per_token, 1)} chars/token")
    IO.puts("    #{Float.round(time_per_char, 3)}μs/char") 
    IO.puts("    #{Float.round(time_per_token, 3)}μs/token")
  end
  
  def compare_with_simple_baseline do
    IO.puts("\n🎯 BASELINE COMPARISON")
    IO.puts("=" <> String.duplicate("=", 50))
    
    # The original baseline was measured on specific content
    # Let's create similar simple test cases
    
    baseline_cases = [
      # Original simple test was around 5.2M tokens/sec with ~25 tokens
      {"Original baseline equivalent", 
       """
       TestMib DEFINITIONS ::= BEGIN
         testObject OBJECT-TYPE
           SYNTAX INTEGER (1..2)
           MAX-ACCESS read-only
           STATUS current
           DESCRIPTION "Test object"
           ::= { test 1 }
       END
       """, 5_200_000}
    ]
    
    for {label, content, baseline_rate} <- baseline_cases do
      IO.puts("\n--- #{label} ---")
      
      # Quick performance test
      for _i <- 1..5, do: SnmpLib.MIB.Lexer.tokenize(content)
      
      times = for _i <- 1..1000 do
        start_time = System.monotonic_time(:microsecond)
        {:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)
        end_time = System.monotonic_time(:microsecond)
        {end_time - start_time, length(tokens)}
      end
      
      {durations, token_counts} = Enum.unzip(times)
      avg_duration = Enum.sum(durations) / length(durations)
      avg_tokens = Enum.sum(token_counts) / length(token_counts)
      
      current_rate = avg_tokens / avg_duration * 1_000_000
      improvement = current_rate / baseline_rate
      
      IO.puts("  Current: #{Float.round(current_rate / 1_000_000, 2)}M tokens/sec")
      IO.puts("  Baseline: #{Float.round(baseline_rate / 1_000_000, 2)}M tokens/sec") 
      IO.puts("  Ratio: #{Float.round(improvement, 2)}x")
      
      if improvement < 1.0 do
        IO.puts("  ⚠️  PERFORMANCE REGRESSION: #{Float.round((1-improvement)*100, 1)}% slower")
      elsif improvement > 2.0 do
        IO.puts("  🎉 EXCELLENT: #{Float.round((improvement-1)*100, 1)}% faster")
      elsif improvement > 1.2 do
        IO.puts("  ✅ GOOD: #{Float.round((improvement-1)*100, 1)}% faster")
      else
        IO.puts("  📈 MODEST: #{Float.round((improvement-1)*100, 1)}% faster")
      end
    end
  end
  
  def analyze_bottlenecks do
    IO.puts("\n🔬 BOTTLENECK ANALYSIS")
    IO.puts("=" <> String.duplicate("=", 50))
    
    # Test specific lexer operations that might be bottlenecks
    
    # 1. Pure whitespace handling
    whitespace_content = String.duplicate(" \t\n", 100)
    IO.puts("\nWhitespace handling:")
    profile_content(whitespace_content)
    
    # 2. Pure identifier tokenization
    identifier_content = String.duplicate("identifier ", 50)
    IO.puts("\nIdentifier tokenization:")
    profile_content(identifier_content)
    
    # 3. Integer parsing
    integer_content = Enum.join(1..100, " ")
    IO.puts("\nInteger parsing:")
    profile_content(integer_content)
    
    # 4. Symbol parsing
    symbol_content = String.duplicate("{ } ( ) ", 25)
    IO.puts("\nSymbol parsing:")
    profile_content(symbol_content)
    
    # 5. String handling
    string_content = Enum.map(1..20, fn i -> "\"string#{i}\"" end) |> Enum.join(" ")
    IO.puts("\nString parsing:")
    profile_content(string_content)
  end
end

LexerProfiler.profile_simple_operations()
LexerProfiler.compare_with_simple_baseline()
LexerProfiler.analyze_bottlenecks()

IO.puts("\n📊 PROFILING COMPLETE")
IO.puts("This will help identify where the binary pattern matching")
IO.puts("optimization isn't delivering expected performance gains.")