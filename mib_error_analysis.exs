# Analysis of individual MIB parsing errors
# Run with: mix run mib_error_analysis.exs

defmodule MibErrorAnalysis do
  @mib_files [
    {"DISMAN-SCHEDULE-MIB.mib", 296, "syntax error before: 209"},
    {"IANA-ADDRESS-FAMILY-NUMBERS-MIB.mib", 130, "syntax error before: 57699"},
    {"IANAifType-MIB.mib", 329, "syntax error before: 225"},
    {"RFC1155-SMI.mib", 103, "syntax error before: 'Counter'"},
    {"RFC1213-MIB.mib", 302, "syntax error before: 225"}
  ]

  def analyze do
    IO.puts(String.duplicate("=", 80))
    IO.puts("MIB PARSING ERROR ANALYSIS")
    IO.puts(String.duplicate("=", 80))
    IO.puts("")

    Enum.each(@mib_files, &analyze_mib_error/1)

    IO.puts("")
    IO.puts(String.duplicate("=", 80))
    IO.puts("SUMMARY OF ISSUES")
    IO.puts(String.duplicate("=", 80))
    
    summarize_issues()
  end

  defp analyze_mib_error({filename, line_number, error_message}) do
    IO.puts("File: #{filename}")
    IO.puts("Line: #{line_number}")
    IO.puts("Error: #{error_message}")
    
    file_path = "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/#{filename}"
    
    case File.read(file_path) do
      {:ok, content} ->
        lines = String.split(content, "\n")
        show_context_around_line(lines, line_number, filename)
      {:error, reason} ->
        IO.puts("Could not read file: #{reason}")
    end
    
    IO.puts("")
  end

  defp show_context_around_line(lines, target_line, filename) do
    total_lines = length(lines)
    
    if target_line > total_lines do
      IO.puts("Error line #{target_line} exceeds file length (#{total_lines} lines)")
      IO.puts("Showing end of file:")
      start_line = max(1, total_lines - 5)
      Enum.with_index(lines, 1)
      |> Enum.drop(start_line - 1)
      |> Enum.each(fn {line, num} ->
        marker = if num == total_lines, do: " <-- END", else: ""
        IO.puts("#{String.pad_leading(to_string(num), 4)}: #{line}#{marker}")
      end)
    else
      IO.puts("Context around line #{target_line}:")
      start_line = max(1, target_line - 3)
      end_line = min(total_lines, target_line + 3)
      
      Enum.with_index(lines, 1)
      |> Enum.filter(fn {_, num} -> num >= start_line and num <= end_line end)
      |> Enum.each(fn {line, num} ->
        marker = if num == target_line, do: " <-- ERROR", else: ""
        IO.puts("#{String.pad_leading(to_string(num), 4)}: #{line}#{marker}")
      end)
    end
  end

  defp summarize_issues do
    IO.puts("Error Pattern Analysis:")
    IO.puts("")
    
    IO.puts("1. Numeric Token Errors:")
    IO.puts("   - Lines 296, 329, 302: 'syntax error before: 209/225'")
    IO.puts("   - Line 130: 'syntax error before: 57699'")
    IO.puts("   - These suggest issues with numeric literal parsing")
    IO.puts("")
    
    IO.puts("2. Keyword/Type Errors:")
    IO.puts("   - Line 103: 'syntax error before: Counter'")
    IO.puts("   - This suggests issues with ASN.1 type recognition")
    IO.puts("")
    
    IO.puts("3. Common Issue:")
    IO.puts("   - All errors are 'syntax error before: X' from mib_grammar_elixir")
    IO.puts("   - This indicates the grammar/parser doesn't recognize certain tokens")
    IO.puts("   - Likely need to update the grammar rules or lexer")
    IO.puts("")
    
    IO.puts("Next Steps:")
    IO.puts("1. Examine the specific lines in each file")
    IO.puts("2. Identify what ASN.1 constructs are causing issues")
    IO.puts("3. Update the grammar or lexer to handle these constructs")
    IO.puts("4. Focus on numeric literal parsing and ASN.1 type definitions")
  end
end

MibErrorAnalysis.analyze()