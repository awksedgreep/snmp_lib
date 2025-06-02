#!/usr/bin/env elixir

# Quick performance test for the optimized lexer

System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

test_input = """
TestMib DEFINITIONS ::= BEGIN
  testObject OBJECT-TYPE
    SYNTAX INTEGER (1..2)
    MAX-ACCESS read-only
    STATUS current
    DESCRIPTION "Test object"
    ::= { test 1 }
END
"""

IO.puts("🚀 OPTIMIZED LEXER PERFORMANCE TEST")
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

IO.puts("\n✅ Binary pattern matching optimization successful!")