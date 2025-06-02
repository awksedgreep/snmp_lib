#!/usr/bin/env elixir

# Debug encoding issues in failing DOCSIS MIBs

System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

docsis_dir = "test/fixtures/mibs/docsis"
failed_files = ["IF-MIB", "PKTC-EVENT-MIB"]

IO.puts("=== Analyzing Encoding Issues ===")

Enum.each(failed_files, fn filename ->
  IO.puts("\n=== #{filename} ===")
  mib_path = Path.join(docsis_dir, filename)
  
  case File.read(mib_path) do
    {:ok, content} ->
      IO.puts("✓ File read: #{byte_size(content)} bytes")
      
      # Check if content is valid UTF-8
      case String.valid?(content) do
        true ->
          IO.puts("✓ Valid UTF-8 encoding")
        false ->
          IO.puts("✗ Invalid UTF-8 encoding detected!")
          # Try to find where the invalid UTF-8 starts
          case :unicode.characters_to_binary(content, :utf8, :utf8) do
            {:error, valid_part, invalid_rest} ->
              IO.puts("Invalid UTF-8 starts at byte position: #{byte_size(valid_part)}")
              IO.puts("Invalid bytes: #{inspect(binary_part(invalid_rest, 0, min(10, byte_size(invalid_rest))))}")
            {:incomplete, valid_part, incomplete_rest} ->
              IO.puts("Incomplete UTF-8 at byte position: #{byte_size(valid_part)}")
              IO.puts("Incomplete bytes: #{inspect(binary_part(incomplete_rest, 0, min(10, byte_size(incomplete_rest))))}")
            _ ->
              IO.puts("Unknown UTF-8 validation issue")
          end
      end
      
      # Look for problematic characters
      lines = String.split(content, "\n")
      IO.puts("Total lines: #{length(lines)}")
      
      # Check for tab characters (might be issue in PKTC-EVENT-MIB)
      lines_with_tabs = lines
      |> Enum.with_index(1)
      |> Enum.filter(fn {line, _idx} -> String.contains?(line, "\t") end)
      
      if length(lines_with_tabs) > 0 do
        IO.puts("⚠️  Found #{length(lines_with_tabs)} lines with tab characters")
        Enum.take(lines_with_tabs, 3) |> Enum.each(fn {line, idx} ->
          IO.puts("Line #{idx}: #{String.slice(line, 0, 50)}...")
        end)
      end
      
      # Check for non-ASCII characters
      non_ascii_lines = lines
      |> Enum.with_index(1)
      |> Enum.filter(fn {line, _idx} -> 
        # Check if line contains non-ASCII characters (> 127)
        String.to_charlist(line) |> Enum.any?(&(&1 > 127))
      end)
      
      if length(non_ascii_lines) > 0 do
        IO.puts("⚠️  Found #{length(non_ascii_lines)} lines with non-ASCII characters")
        Enum.take(non_ascii_lines, 3) |> Enum.each(fn {line, idx} ->
          # Show the problematic characters
          problematic_chars = line
          |> String.to_charlist()
          |> Enum.filter(&(&1 > 127))
          |> Enum.take(5)
          
          IO.puts("Line #{idx}: non-ASCII chars #{inspect(problematic_chars)}")
        end)
      end
      
      # Look for unclosed quotes specifically
      quote_issues = lines
      |> Enum.with_index(1)
      |> Enum.filter(fn {line, _idx} ->
        # Count double quotes
        quote_count = line |> String.graphemes() |> Enum.count(&(&1 == "\""))
        rem(quote_count, 2) != 0  # Odd number of quotes
      end)
      
      if length(quote_issues) > 0 do
        IO.puts("⚠️  Found #{length(quote_issues)} lines with odd number of quotes")
        Enum.take(quote_issues, 5) |> Enum.each(fn {line, idx} ->
          quotes = line |> String.graphemes() |> Enum.count(&(&1 == "\""))
          IO.puts("Line #{idx} (#{quotes} quotes): #{String.slice(line, 0, 80)}...")
        end)
      end
      
      # For IF-MIB, specifically look around line 3868
      if filename == "IF-MIB" do
        IO.puts("\n--- Examining IF-MIB around line 3868 ---")
        problem_lines = Enum.slice(lines, 3860..3875)
        Enum.with_index(problem_lines, 3861) |> Enum.each(fn {line, idx} ->
          quote_count = line |> String.graphemes() |> Enum.count(&(&1 == "\""))
          IO.puts("#{idx}: (#{quote_count} quotes) #{line}")
        end)
      end
      
    {:error, reason} ->
      IO.puts("✗ File read failed: #{reason}")
  end
end)