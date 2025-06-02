#!/usr/bin/env elixir

System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

defmodule BottleneckInvestigation do
  def compare_simple_vs_complex do
    IO.puts("🔍 SIMPLE vs COMPLEX CONTENT ANALYSIS")
    IO.puts("=" <> String.duplicate("=", 50))
    
    # Simple content that shows good performance
    simple_content = "test one two three"
    
    # More complex but still short content
    medium_content = """
    TestMib DEFINITIONS ::= BEGIN
      testObject OBJECT-TYPE
    END
    """
    
    # Complex content similar to what we tested before
    complex_content = """
    TestMib DEFINITIONS ::= BEGIN
      testObject OBJECT-TYPE
        SYNTAX INTEGER (1..2)
        MAX-ACCESS read-only
        STATUS current
        DESCRIPTION "Test object"
        ::= { test 1 }
    END
    """
    
    contents = [
      {"Simple", simple_content},
      {"Medium", medium_content}, 
      {"Complex", complex_content}
    ]
    
    Enum.each(contents, fn {label, content} ->
      IO.puts("\n--- #{label} Content ---")
      
      # Get token breakdown
      {:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)
      token_types = tokens 
                   |> Enum.map(fn {type, _value, _pos} -> type end)
                   |> Enum.frequencies()
      
      IO.puts("Size: #{byte_size(content)} bytes")
      IO.puts("Tokens: #{length(tokens)}")
      IO.puts("Token types: #{inspect(token_types)}")
      
      # Performance test
      times = for _i <- 1..1000 do
        start = :erlang.monotonic_time(:microsecond)
        {:ok, _tokens} = SnmpLib.MIB.Lexer.tokenize(content)
        stop = :erlang.monotonic_time(:microsecond)
        stop - start
      end
      
      avg_time = Enum.sum(times) / length(times)
      min_time = Enum.min(times)
      rate = length(tokens) / avg_time * 1_000_000
      
      IO.puts("Avg time: #{Float.round(avg_time, 2)}μs")
      IO.puts("Min time: #{min_time}μs")
      IO.puts("Rate: #{Float.round(rate / 1_000_000, 2)}M tokens/sec")
      IO.puts("Bytes/sec: #{Float.round(byte_size(content) / avg_time * 1_000_000 / 1_000_000, 2)}MB/sec")
    end)
  end
  
  def profile_string_heavy_content do
    IO.puts("\n🔍 STRING-HEAVY CONTENT ANALYSIS")
    IO.puts("=" <> String.duplicate("=", 50))
    
    # Create content with many strings (which seemed slow in some tests)
    string_heavy = Enum.map(1..50, fn i -> 
      "DESCRIPTION \"This is description #{i} with some text\"" 
    end) |> Enum.join("\n")
    
    IO.puts("String-heavy content:")
    IO.puts("Size: #{byte_size(string_heavy)} bytes")
    
    {:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(string_heavy)
    IO.puts("Tokens: #{length(tokens)}")
    
    # Performance test
    times = for _i <- 1..100 do
      start = :erlang.monotonic_time(:microsecond)
      {:ok, _tokens} = SnmpLib.MIB.Lexer.tokenize(string_heavy)
      stop = :erlang.monotonic_time(:microsecond)
      stop - start
    end
    
    avg_time = Enum.sum(times) / length(times)
    rate = length(tokens) / avg_time * 1_000_000
    
    IO.puts("Avg time: #{Float.round(avg_time, 2)}μs")
    IO.puts("Rate: #{Float.round(rate / 1_000_000, 2)}M tokens/sec")
  end
  
  def test_actual_mib_snippet do
    IO.puts("\n🔍 ACTUAL MIB SNIPPET ANALYSIS")
    IO.puts("=" <> String.duplicate("=", 50))
    
    # Test with actual content from a real MIB to see what's different
    mib_snippet = """
    SNMPv2-SMI DEFINITIONS ::= BEGIN
    
    IMPORTS
        MODULE-IDENTITY, OBJECT-TYPE, NOTIFICATION-TYPE,
        TimeTicks, Counter32, snmpModules, mib-2
            FROM SNMPv2-SMI
        MODULE-COMPLIANCE, OBJECT-GROUP, NOTIFICATION-GROUP
            FROM SNMPv2-CONF
        TEXTUAL-CONVENTION, DisplayString
            FROM SNMPv2-TC;
    
    snmpMIB MODULE-IDENTITY
        LAST-UPDATED "9511090000Z"
        ORGANIZATION "IETF SNMPv2 Working Group"
        CONTACT-INFO
                "        Marshall T. Rose
    
                 Postal: Dover Beach Consulting, Inc.
                         420 Whisman Court
                         Mountain View, CA  94043-2186
                         US
    
                 Tel: +1 415 968 1052
    
                 E-mail: mrose@dbc.mtview.ca.us"
        DESCRIPTION
                "The MIB module for SNMP entities."
        REVISION      "9304010000Z"
        DESCRIPTION
                "The initial revision of this MIB module was published as
                RFC 1450."
        ::= { snmpModules 1 }
    END
    """
    
    IO.puts("MIB snippet:")
    IO.puts("Size: #{byte_size(mib_snippet)} bytes")
    
    {:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(mib_snippet)
    IO.puts("Tokens: #{length(tokens)}")
    
    # Performance test
    times = for _i <- 1..100 do
      start = :erlang.monotonic_time(:microsecond)
      {:ok, _tokens} = SnmpLib.MIB.Lexer.tokenize(mib_snippet)
      stop = :erlang.monotonic_time(:microsecond)
      stop - start
    end
    
    avg_time = Enum.sum(times) / length(times)
    rate = length(tokens) / avg_time * 1_000_000
    
    IO.puts("Avg time: #{Float.round(avg_time, 2)}μs")
    IO.puts("Rate: #{Float.round(rate / 1_000_000, 2)}M tokens/sec")
    
    # Compare with baseline expectation
    baseline_rate = 5_200_000  # tokens/sec from original baseline
    improvement = rate / baseline_rate
    
    IO.puts("\nComparison to baseline:")
    IO.puts("Current: #{Float.round(rate / 1_000_000, 2)}M tokens/sec")
    IO.puts("Baseline: #{Float.round(baseline_rate / 1_000_000, 2)}M tokens/sec")
    IO.puts("Ratio: #{Float.round(improvement, 2)}x")
    
    if improvement >= 2.0 do
      IO.puts("🎉 EXCELLENT: Achieved 2x+ improvement target!")
    elsif improvement >= 1.5 do
      IO.puts("✅ GOOD: Solid improvement")
    elsif improvement >= 1.2 do
      IO.puts("📈 MODEST: Some improvement")
    elsif improvement >= 0.8 do
      IO.puts("⚠️  MARGINAL: Close to baseline")
    else
      IO.puts("❌ REGRESSION: Slower than baseline")
    end
  end
end

BottleneckInvestigation.compare_simple_vs_complex()
BottleneckInvestigation.profile_string_heavy_content()
BottleneckInvestigation.test_actual_mib_snippet()

IO.puts("\n📊 INVESTIGATION COMPLETE")