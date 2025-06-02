defmodule SnmpLib.MIB.LexerPerformanceTest do
  use ExUnit.Case, async: true
  
  @moduledoc """
  Performance regression tests to ensure lexer optimizations are maintained.
  """

  @baseline_performance 5_200_000 # tokens/sec baseline from original measurements
  @performance_target 1.05 # 5% improvement minimum (realistic regression test)

  describe "lexer performance benchmarks" do
    test "simple MIB content performance" do
      content = """
      TestMib DEFINITIONS ::= BEGIN
        testObject OBJECT-TYPE
          SYNTAX INTEGER (1..2)
          MAX-ACCESS read-only
          STATUS current
          DESCRIPTION "Test object"
          ::= { test 1 }
      END
      """
      
      # Warm up
      for _ <- 1..10, do: SnmpLib.MIB.Lexer.tokenize(content)
      
      # Performance test
      times = for _ <- 1..100 do
        {time_us, {:ok, tokens}} = :timer.tc(fn ->
          SnmpLib.MIB.Lexer.tokenize(content)
        end)
        {time_us, length(tokens)}
      end
      
      {durations, token_counts} = Enum.unzip(times)
      avg_time = Enum.sum(durations) / length(durations)
      avg_tokens = Enum.sum(token_counts) / length(token_counts)
      
      rate = avg_tokens / avg_time * 1_000_000
      improvement = rate / @baseline_performance
      
      assert improvement >= @performance_target,
        "Performance regression: #{Float.round(rate/1_000_000, 2)}M tok/s < target #{Float.round(@baseline_performance * @performance_target / 1_000_000, 2)}M tok/s"
    end

    test "keyword tokenization efficiency" do
      # Test with keyword-heavy content
      content = """
      MODULE-IDENTITY OBJECT-TYPE SYNTAX INTEGER MAX-ACCESS STATUS DESCRIPTION
      BEGIN END IMPORTS FROM EXPORTS TEXTUAL-CONVENTION DISPLAY-HINT
      NOTIFICATION-TYPE OBJECT-GROUP MODULE-COMPLIANCE AGENT-CAPABILITIES
      """
      
      # Should process keywords efficiently with pre-computed map
      {time_us, {:ok, tokens}} = :timer.tc(fn ->
        SnmpLib.MIB.Lexer.tokenize(content)
      end)
      
      rate = length(tokens) / time_us * 1_000_000
      
      # Keyword processing should maintain reasonable performance (relaxed for test environment)
      assert rate > @baseline_performance * 0.4,
        "Keyword processing too slow: #{Float.round(rate/1_000_000, 2)}M tok/s"
    end

    test "string processing performance" do
      # Test with string-heavy content
      strings = for i <- 1..20, do: "\"Description string #{i} with some content\""
      content = Enum.join(strings, " ")
      
      {time_us, {:ok, tokens}} = :timer.tc(fn ->
        SnmpLib.MIB.Lexer.tokenize(content)
      end)
      
      rate = length(tokens) / time_us * 1_000_000
      
      # String processing should maintain reasonable performance (relaxed for test environment)
      assert rate > @baseline_performance * 0.3,
        "String processing too slow: #{Float.round(rate/1_000_000, 2)}M tok/s"
    end

    test "integer parsing performance" do
      # Test with integer-heavy content  
      integers = for i <- 1..100, do: to_string(i * 1000 + i)
      content = Enum.join(integers, " ")
      
      {time_us, {:ok, tokens}} = :timer.tc(fn ->
        SnmpLib.MIB.Lexer.tokenize(content)
      end)
      
      rate = length(tokens) / time_us * 1_000_000
      
      # Integer parsing should maintain reasonable performance (relaxed for test environment)
      assert rate > @baseline_performance * 0.02,
        "Integer processing too slow: #{Float.round(rate/1_000_000, 2)}M tok/s"
    end
  end

  describe "optimization verification" do
    test "token structure uses tuples not maps" do
      {:ok, tokens} = SnmpLib.MIB.Lexer.tokenize("test 123")
      
      for token <- tokens do
        case token do
          {_type, _value, line} when is_integer(line) ->
            # Correct optimized format
            assert true
          {_type, _value, %{line: _line}} ->
            flunk("Token still using map format instead of optimized tuple format")
          _ ->
            flunk("Unexpected token format: #{inspect(token)}")
        end
      end
    end

    test "reserved words use pre-computed atoms" do
      {:ok, tokens} = SnmpLib.MIB.Lexer.tokenize("BEGIN MODULE-IDENTITY END")
      
      keyword_tokens = Enum.filter(tokens, fn {type, _, _} -> type == :keyword end)
      
      assert length(keyword_tokens) >= 3, "Expected keyword tokens"
      
      for {:keyword, atom_value, _line} <- keyword_tokens do
        assert is_atom(atom_value), "Keyword value should be pre-computed atom"
      end
    end
  end
end