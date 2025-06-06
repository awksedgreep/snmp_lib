#!/usr/bin/env elixir

# Extract the exact problematic section from IANAifType-MIB and test it in isolation

defmodule ProblemExtractor do
  def extract_section do
    {:ok, content} = File.read("/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/IANAifType-MIB.mib")
    lines = String.split(content, "\n")
    
    # Find the SYNTAX INTEGER line
    syntax_line_idx = Enum.find_index(lines, fn line -> 
      String.contains?(line, "SYNTAX  INTEGER {")
    end)
    
    if syntax_line_idx do
      IO.puts("Found SYNTAX INTEGER at line #{syntax_line_idx + 1}")
      
      # Extract from SYNTAX line until the closing brace
      extract_enumeration(lines, syntax_line_idx)
    else
      IO.puts("Could not find SYNTAX INTEGER line")
    end
  end
  
  def extract_enumeration(lines, start_idx) do
    # Find the closing brace
    end_idx = find_closing_brace(lines, start_idx)
    
    if end_idx do
      IO.puts("Found closing brace at line #{end_idx + 1}")
      
      # Extract the enumeration section
      enum_lines = Enum.slice(lines, start_idx, end_idx - start_idx + 1)
      
      # Test progressively larger chunks
      test_chunks(enum_lines)
    else
      IO.puts("Could not find closing brace")
    end
  end
  
  def find_closing_brace(lines, start_idx) do
    lines
    |> Enum.drop(start_idx)
    |> Enum.with_index(start_idx)
    |> Enum.find(fn {line, _idx} ->
      String.trim(line) == "}"
    end)
    |> case do
      {_line, idx} -> idx
      nil -> nil
    end
  end
  
  def test_chunks(enum_lines) do
    # Test incrementally larger chunks to find where it breaks
    chunk_sizes = [10, 20, 30, 50, 100, 200, length(enum_lines)]
    
    Enum.each(chunk_sizes, fn size ->
      test_chunk(enum_lines, size)
    end)
  end
  
  def test_chunk(enum_lines, size) do
    if size <= length(enum_lines) do
      chunk = Enum.take(enum_lines, size)
      
      # Add closing brace if not present
      chunk = if String.contains?(List.last(chunk), "}") do
        chunk
      else
        chunk ++ ["}"]
      end
      
      test_mib = """
      TEST-MIB DEFINITIONS ::= BEGIN
      
      IMPORTS
          TEXTUAL-CONVENTION  FROM SNMPv2-TC;
      
      TestType ::= TEXTUAL-CONVENTION
          STATUS      current
          DESCRIPTION "Test"
          #{Enum.join(chunk, "\n          ")}
      
      END
      """
      
      case SnmpLib.MIB.Parser.parse(test_mib) do
        {:ok, _} ->
          IO.puts("✓ Chunk size #{size}: SUCCESS")
        {:error, error} ->
          IO.puts("✗ Chunk size #{size}: FAILED - #{inspect(error)}")
          
          # If this chunk fails but the previous worked, we found the problem area
          if size > 10 do
            IO.puts("  Problem appears between #{div(size, 2)} and #{size} lines")
            
            # Show the content around the break point
            if size <= 50 do
              IO.puts("  Chunk content around break:")
              mid_point = div(size, 2)
              problem_area = Enum.slice(chunk, max(0, mid_point - 5), 10)
              Enum.with_index(problem_area, mid_point - 5)
              |> Enum.each(fn {line, idx} ->
                IO.puts("    #{idx + 1}: #{line}")
              end)
            end
          end
      end
    end
  end
end

ProblemExtractor.extract_section()