#!/usr/bin/env elixir

IO.puts("🧪 MINIMAL ENUMERATION TEST")
IO.puts("===========================")

# Test simple enumeration patterns
test_cases = [
  # Simple working case
  """
  TestMIB DEFINITIONS ::= BEGIN
  testEnum OBJECT-TYPE
      SYNTAX INTEGER {
          small(1),
          medium(19)
      }
      ::= { test 1 }
  END
  """,
  
  # Test with the problematic number patterns
  """
  TestMIB DEFINITIONS ::= BEGIN
  testEnum OBJECT-TYPE
      SYNTAX INTEGER {
          small(1),
          e1(19)
      }
      ::= { test 1 }
  END
  """,
  
  # Test with large number
  """
  TestMIB DEFINITIONS ::= BEGIN
  testEnum OBJECT-TYPE
      SYNTAX INTEGER {
          small(1),
          rpr(225)
      }
      ::= { test 1 }
  END
  """
]

Enum.with_index(test_cases, 1) |> Enum.each(fn {test_case, index} ->
  IO.puts("\n📋 Test Case #{index}:")
  IO.puts(String.duplicate("-", 20))
  
  case SnmpLib.MIB.ActualParser.parse(test_case) do
    {:ok, _result} ->
      IO.puts("✅ SUCCESS")
    {:error, {line, :mib_grammar_elixir, error_info}} ->
      IO.puts("❌ ERROR at line #{line}: #{inspect(error_info)}")
    {:error, other} ->
      IO.puts("❌ OTHER ERROR: #{inspect(other)}")
  end
end)

IO.puts("\n🔍 This should help identify the actual issue!")