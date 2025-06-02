#!/usr/bin/env elixir

# Simple test to check the current state of our parser

# Try to load a simple MIB manually
test_mib = """
TEST-MIB DEFINITIONS ::= BEGIN

testObject OBJECT-TYPE
    SYNTAX INTEGER
    MAX-ACCESS read-only
    STATUS current
    DESCRIPTION "A test object"
    ::= { 1 3 6 1 4 1 99999 1 }

END
"""

IO.puts("🧪 Testing simple MIB parsing...")
IO.puts("MIB content: #{byte_size(test_mib)} bytes")

try do
  # Try using the ActualParser
  result = SnmpLib.MIB.ActualParser.parse(test_mib)
  IO.puts("✅ ActualParser result: #{inspect(result)}")
rescue
  e ->
    IO.puts("❌ ActualParser failed: #{inspect(e)}")
    
    # Try using the regular parser
    try do
      result = SnmpLib.MIB.Parser.parse(test_mib)
      IO.puts("✅ Parser result: #{inspect(result)}")
    rescue
      e2 ->
        IO.puts("❌ Parser also failed: #{inspect(e2)}")
        
        # Try using the lexer directly
        try do
          {:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(test_mib)
          IO.puts("✅ Lexer produced #{length(tokens)} tokens")
          IO.puts("First 10 tokens: #{inspect(Enum.take(tokens, 10))}")
        rescue
          e3 ->
            IO.puts("❌ Lexer also failed: #{inspect(e3)}")
        end
    end
end