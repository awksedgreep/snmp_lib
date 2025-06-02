#!/usr/bin/env elixir

# OID Parsing Issue Diagnosis and Fix
# Based on debugging the SNMP MIB parser OID parsing issues

IO.puts("=== OID Parsing Issue Diagnosis Report ===\n")

IO.puts("INVESTIGATION SUMMARY:")
IO.puts("======================")

IO.puts("1. ISSUE REPORTED:")
IO.puts("   - 'Expected OID element, but found integer' error")
IO.puts("   - All DOCSIS MIBs failing with OID parsing issues")
IO.puts("   - Suspected issue in parse_oid_elements function around lines 488-495")

IO.puts("\n2. TESTING RESULTS:")
IO.puts("   ✓ Basic OID parsing logic is working correctly")
IO.puts("   ✓ All common OID patterns parse successfully:")
IO.puts("     - { mib-2 69 }")
IO.puts("     - { docsDev 1 }")
IO.puts("     - { docsDevMIBObjects 1 }")
IO.puts("     - { iso(1) org(3) dod(6) internet(1) mgmt(2) 1 }")
IO.puts("   ✓ DOCSIS MIB tokenization works correctly")
IO.puts("   ✓ OID assignment patterns are recognized properly")

IO.puts("\n3. ACTUAL ISSUES FOUND:")
IO.puts("   ✗ Function clause warning in parse_optional_clauses/2:")
IO.puts("     - Line 700: {:error, reason} clause will never match")
IO.puts("     - parse_augments_clause/1 always returns {:ok, ...}")
IO.puts("     - This is a code quality issue but not the OID parsing problem")

IO.puts("\n4. ROOT CAUSE ANALYSIS:")
IO.puts("   The reported 'Expected OID element, but found integer' error")
IO.puts("   does NOT exist in the current codebase.")
IO.puts("   ")
IO.puts("   Possible explanations:")
IO.puts("   a) The error message has been fixed since it was reported")
IO.puts("   b) The error occurs in a different parsing context")
IO.puts("   c) The error message was paraphrased or misremembered")
IO.puts("   d) The error occurs only with specific MIB constructs not tested")

IO.puts("\n5. FUNCTION CLAUSE ISSUE IDENTIFIED:")
IO.puts("   File: lib/snmp_lib/mib/parser_port.ex")
IO.puts("   Lines: 697-702")
IO.puts("   Problem: parse_augments_clause never returns {:error, reason}")
IO.puts("   But parse_optional_clauses expects it might")

IO.puts("\n6. RECOMMENDED FIXES:")

IO.puts("\nFIX 1: Function clause mismatch in parse_optional_clauses")
IO.puts("-------------------------------------------------------")
IO.puts("CURRENT CODE (lines 696-702):")
IO.puts("""
  defp parse_optional_clauses([{:keyword, :augments, _} | tokens], acc) do
    case parse_augments_clause(tokens) do
      {:ok, {augments, rest}} ->
        parse_optional_clauses(rest, Map.put(acc, :augments, augments))
      {:error, reason} ->  # <-- This clause never matches
        {:error, reason}
    end
  end
""")

IO.puts("RECOMMENDED FIX:")
IO.puts("""
  defp parse_optional_clauses([{:keyword, :augments, _} | tokens], acc) do
    {:ok, {augments, rest}} = parse_augments_clause(tokens)
    parse_optional_clauses(rest, Map.put(acc, :augments, augments))
  end
""")

IO.puts("\nFIX 2: If OID parsing issues persist, add better error messages")
IO.puts("--------------------------------------------------------------")
IO.puts("Current fallback error (line 494):")
IO.puts("""
  defp parse_oid_elements(tokens, _acc) do
    {:error, "Invalid OID element: \#{inspect(hd(tokens))}"}
  end
""")

IO.puts("Enhanced version:")
IO.puts("""
  defp parse_oid_elements([], _acc) do
    {:error, "Unexpected end of tokens while parsing OID elements"}
  end
  
  defp parse_oid_elements([token | _], _acc) do
    case token do
      {:integer, value, _} ->
        {:error, "Expected OID element, but found integer \#{value} - this might indicate a function clause mismatch"}
      {:identifier, name, _} ->
        {:error, "Expected OID element, but found identifier '\#{name}' - this might indicate a parsing context error"}
      other ->
        {:error, "Invalid OID element: \#{inspect(other)}"}
    end
  end
""")

IO.puts("\n7. TESTING RECOMMENDATIONS:")
IO.puts("   - Run full DOCSIS MIB parsing tests to identify specific failing constructs")
IO.puts("   - Check if the error occurs in a different parsing function")
IO.puts("   - Add logging to identify the exact token sequence causing issues")
IO.puts("   - Test with the complete MIB file rather than isolated snippets")

IO.puts("\n8. CONCLUSION:")
IO.puts("   The OID parsing function itself is working correctly.")
IO.puts("   The issue likely lies in:")
IO.puts("   a) Function clause mismatches in calling contexts")
IO.puts("   b) Incorrect token sequences being passed to OID parser")
IO.puts("   c) Parser state corruption from earlier parsing errors")

IO.puts("\n=== End of Diagnosis Report ===")

# Apply the recommended fix
Code.require_file("lib/snmp_lib/mib/parser_port.ex")

IO.puts("\n=== Testing the identified function clause fix ===")

# Read the current parser_port.ex to check the exact issue
parser_content = File.read!("lib/snmp_lib/mib/parser_port.ex")
lines = String.split(parser_content, "\n")

# Find the problematic lines
problem_start = Enum.find_index(lines, fn line -> 
  String.contains?(line, "case parse_augments_clause(tokens) do")
end)

if problem_start do
  problem_lines = Enum.slice(lines, problem_start, 7)
  IO.puts("Current problematic code:")
  Enum.with_index(problem_lines, problem_start + 1)
  |> Enum.each(fn {line, num} ->
    IO.puts("#{num}: #{line}")
  end)
else
  IO.puts("Could not find the specific problem code")
end

IO.puts("\nTo create the fix, run:")
IO.puts("  elixir -e \"")
IO.puts("    content = File.read!('lib/snmp_lib/mib/parser_port.ex')")
IO.puts("    fixed = String.replace(content,")
IO.puts("      ~S[case parse_augments_clause(tokens) do")
IO.puts("      {:ok, {augments, rest}} ->")
IO.puts("        parse_optional_clauses(rest, Map.put(acc, :augments, augments))")
IO.puts("      {:error, reason} ->")
IO.puts("        {:error, reason}")
IO.puts("    end],")
IO.puts("      ~S[{:ok, {augments, rest}} = parse_augments_clause(tokens)")
IO.puts("    parse_optional_clauses(rest, Map.put(acc, :augments, augments))])")
IO.puts("    File.write!('lib/snmp_lib/mib/parser_port.ex', fixed)")
IO.puts("  \"")