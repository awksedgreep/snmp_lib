#!/usr/bin/env elixir

IO.puts("🧪 SPECIFIC ENUMERATION PARSING TEST")
IO.puts("====================================")

# Test the specific problematic patterns found in real MIBs
test_cases = [
  # Test case 1: Small numbers (should work)
  """
  TEST-MIB DEFINITIONS ::= BEGIN
  IMPORTS enterprises FROM RFC1155-SMI;
  
  test OBJECT IDENTIFIER ::= { enterprises 99999 }
  
  testEnum OBJECT-TYPE
      SYNTAX INTEGER {
          small(1),
          medium(19)
      }
      ACCESS read-only
      STATUS mandatory
      ::= { test 1 }
  END
  """,
  
  # Test case 2: The problematic "e1(19)" pattern
  """
  TEST-MIB DEFINITIONS ::= BEGIN
  IMPORTS enterprises FROM RFC1155-SMI;
  
  test OBJECT IDENTIFIER ::= { enterprises 99999 }
  
  testEnum OBJECT-TYPE
      SYNTAX INTEGER {
          ds1(18),
          e1(19)
      }
      ACCESS read-only
      STATUS mandatory
      ::= { test 1 }
  END
  """,
  
  # Test case 3: Large number like 225
  """
  TEST-MIB DEFINITIONS ::= BEGIN
  IMPORTS enterprises FROM RFC1155-SMI;
  
  test OBJECT IDENTIFIER ::= { enterprises 99999 }
  
  testEnum OBJECT-TYPE
      SYNTAX INTEGER {
          fcipLink(224),
          rpr(225)
      }
      ACCESS read-only
      STATUS mandatory
      ::= { test 1 }
  END
  """
]

Enum.with_index(test_cases, 1) |> Enum.each(fn {test_case, index} ->
  IO.puts("\n📋 Test Case #{index}:")
  IO.puts(String.duplicate("-", 30))
  
  case SnmpLib.MIB.ActualParser.parse(test_case) do
    {:ok, _result} ->
      IO.puts("✅ SUCCESS")
    {:error, {line, :mib_grammar_elixir, error_info}} ->
      IO.puts("❌ ERROR at line #{line}: #{inspect(error_info)}")
      
      # Show the actual line that failed
      lines = String.split(test_case, "\n")
      if line > 0 and line <= length(lines) do
        failed_line = Enum.at(lines, line - 1, "")
        IO.puts("   Failed line: #{String.trim(failed_line)}")
      end
    {:error, other} ->
      IO.puts("❌ OTHER ERROR: #{inspect(other)}")
  end
end)

IO.puts("\n🎯 ANALYSIS:")
IO.puts("If Test 1 works but Test 2/3 fail, the issue is with specific enumeration values")
IO.puts("If all tests fail, the issue is with the basic MIB structure")