#!/usr/bin/env elixir

# Investigate the exact context around reported error lines

defmodule ContextInvestigator do
  def investigate do
    IO.puts("CONTEXT INVESTIGATION FOR PARSING ERRORS")
    IO.puts(String.duplicate("=", 60))
    
    files = [
      {"/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/DISMAN-SCHEDULE-MIB.mib", 296, "209"},
      {"/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/IANA-ADDRESS-FAMILY-NUMBERS-MIB.mib", 130, "57699"},
      {"/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/IANAifType-MIB.mib", 329, "225"},
      {"/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/RFC1213-MIB.mib", 302, "225"}
    ]
    
    Enum.each(files, fn {file, line, number} ->
      investigate_file(file, line, number)
    end)
  end
  
  def investigate_file(file_path, error_line, expected_number) do
    filename = Path.basename(file_path)
    IO.puts("\n#{filename} - Line #{error_line} - Expected: #{expected_number}")
    IO.puts(String.duplicate("-", 50))
    
    case File.read(file_path) do
      {:ok, content} ->
        lines = String.split(content, "\n")
        
        # Show context around the error line
        IO.puts("Context around line #{error_line}:")
        start_line = max(1, error_line - 5)
        end_line = min(length(lines), error_line + 5)
        
        Enum.with_index(lines, 1)
        |> Enum.filter(fn {_line, idx} -> idx >= start_line and idx <= end_line end)
        |> Enum.each(fn {line_content, idx} ->
          marker = if idx == error_line, do: " >>> ", else: "     "
          IO.puts("#{String.pad_leading(to_string(idx), 3)}#{marker}#{line_content}")
        end)
        
        # Search for the expected number in the entire file
        IO.puts("\nSearching for '#{expected_number}' in entire file:")
        case find_number_occurrences(lines, expected_number) do
          [] ->
            IO.puts("  Number '#{expected_number}' NOT FOUND in file")
          occurrences ->
            IO.puts("  Found #{length(occurrences)} occurrence(s):")
            Enum.each(occurrences, fn {line_num, line_content} ->
              content_str = if is_binary(line_content), do: line_content, else: to_string(line_content)
              IO.puts("    Line #{line_num}: #{String.trim(content_str)}")
            end)
        end
        
        # Also search for variations (hex, etc.)
        search_variations(lines, expected_number)
        
      {:error, reason} ->
        IO.puts("Error reading file: #{inspect(reason)}")
    end
  end
  
  defp find_number_occurrences(lines, number_str) do
    lines
    |> Enum.with_index(1)
    |> Enum.filter(fn {line, _idx} -> String.contains?(line, number_str) end)
  end
  
  defp search_variations(lines, number_str) do
    # Try to convert to integer and search for hex/octal variations
    case Integer.parse(number_str) do
      {num, ""} ->
        hex_str = Integer.to_string(num, 16)
        octal_str = Integer.to_string(num, 8)
        
        hex_occurrences = find_number_occurrences(lines, hex_str)
        octal_occurrences = find_number_occurrences(lines, octal_str)
        
        unless Enum.empty?(hex_occurrences) do
          IO.puts("  Found hex variations (#{hex_str}):")
          Enum.each(hex_occurrences, fn {line_num, line_content} ->
            content_str = if is_binary(line_content), do: line_content, else: to_string(line_content)
            IO.puts("    Line #{line_num}: #{String.trim(content_str)}")
          end)
        end
        
        unless Enum.empty?(octal_occurrences) do
          IO.puts("  Found octal variations (#{octal_str}):")
          Enum.each(octal_occurrences, fn {line_num, line_content} ->
            content_str = if is_binary(line_content), do: line_content, else: to_string(line_content)
            IO.puts("    Line #{line_num}: #{String.trim(content_str)}")
          end)
        end
        
      _ ->
        IO.puts("  Could not parse '#{number_str}' as integer for variation search")
    end
  end
end

ContextInvestigator.investigate()