#!/usr/bin/env elixir

# Script to help identify and fix OID test patterns

defmodule OidTestFixer do
  def analyze_test_file(file_path) do
    content = File.read!(file_path)
    
    # Pattern 1: Tests expecting {:object_identifier, "string"} but getting list
    if String.contains?(content, "{:object_identifier,") do
      IO.puts("\n#{file_path} contains OID tuple expectations")
      
      # Find lines with this pattern
      lines = String.split(content, "\n")
      Enum.with_index(lines, 1)
      |> Enum.filter(fn {line, _} -> 
        String.contains?(line, "{:object_identifier,") or
        String.contains?(line, "expected {:object_identifier")
      end)
      |> Enum.each(fn {line, num} ->
        IO.puts("  Line #{num}: #{String.trim(line)}")
      end)
    end
    
    # Pattern 2: Tests encoding string OIDs
    if String.contains?(content, ":object_identifier, oid_string") or
       String.contains?(content, ":object_identifier, \"") do
      IO.puts("\n#{file_path} encodes string OIDs")
    end
  end
  
  def suggest_fixes() do
    IO.puts("\nSuggested fixes for OID tests:")
    IO.puts("1. When encoding string OIDs, they will decode as lists")
    IO.puts("2. Replace assertions like:")
    IO.puts("   assert decoded_value == {:object_identifier, \"1.3.6.1\"}")
    IO.puts("   with:")
    IO.puts("   assert decoded_value == [1, 3, 6, 1]")
    IO.puts("3. Or if you need to compare strings:")
    IO.puts("   assert Enum.join(decoded_value, \".\") == \"1.3.6.1\"")
  end
end

# Analyze the failing test files
test_files = [
  "/Users/mcotner/Documents/elixir/snmp_lib/test/snmp_lib/object_identifier_string_test.exs",
  "/Users/mcotner/Documents/elixir/snmp_lib/test/snmp_lib/multibyte_oid_encoding_test.exs",
  "/Users/mcotner/Documents/elixir/snmp_lib/test/snmp_lib/edge_cases_test.exs",
  "/Users/mcotner/Documents/elixir/snmp_lib/test/snmp_lib/rfc_compliance_test.exs"
]

IO.puts("Analyzing OID test patterns...")
Enum.each(test_files, &OidTestFixer.analyze_test_file/1)
OidTestFixer.suggest_fixes()
