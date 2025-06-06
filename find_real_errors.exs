#!/usr/bin/env elixir

# Find the real parsing errors by testing file chunks

defmodule RealErrorFinder do
  def find_errors do
    files = [
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/IANAifType-MIB.mib"
    ]
    
    Enum.each(files, &find_error_in_file/1)
  end
  
  def find_error_in_file(file_path) do
    filename = Path.basename(file_path)
    IO.puts("Analyzing #{filename}")
    IO.puts(String.duplicate("=", 50))
    
    {:ok, content} = File.read(file_path)
    lines = String.split(content, "\n")
    
    # Test the file in chunks to isolate the problem
    test_chunks(lines, filename)
  end
  
  def test_chunks(lines, filename) do
    total_lines = length(lines)
    chunk_size = div(total_lines, 10)  # Start with 10 chunks
    
    IO.puts("Testing #{filename} in chunks of ~#{chunk_size} lines")
    
    0..(div(total_lines, chunk_size))
    |> Enum.each(fn chunk_idx ->
      start_idx = chunk_idx * chunk_size
      end_idx = min(start_idx + chunk_size, total_lines)
      
      if start_idx < total_lines do
        chunk_lines = Enum.slice(lines, start_idx, chunk_size)
        chunk_content = Enum.join(chunk_lines, "\n")
        
        # Create a minimal MIB wrapper
        test_content = """
        TEST-MIB DEFINITIONS ::= BEGIN
        
        #{chunk_content}
        
        END
        """
        
        case SnmpLib.MIB.Parser.parse(test_content) do
          {:ok, _} ->
            IO.puts("✓ Chunk #{chunk_idx} (lines #{start_idx+1}-#{end_idx}): OK")
          {:error, error} ->
            IO.puts("✗ Chunk #{chunk_idx} (lines #{start_idx+1}-#{end_idx}): #{inspect(error)}")
            
            # If we found an error, narrow it down further
            if chunk_size > 5 do
              IO.puts("  Narrowing down error in chunk #{chunk_idx}...")
              narrow_down_error(chunk_lines, start_idx)
            end
        end
      end
    end)
  end
  
  def narrow_down_error(chunk_lines, base_line_offset) do
    # Binary search to find the exact problematic lines
    test_subchunk(chunk_lines, 0, length(chunk_lines), base_line_offset)
  end
  
  def test_subchunk(lines, start_idx, end_idx, base_offset) when end_idx - start_idx <= 2 do
    # Base case: test individual lines
    start_idx..(end_idx-1)
    |> Enum.each(fn idx ->
      if idx < length(lines) do
        line = Enum.at(lines, idx)
        test_content = """
        TEST-MIB DEFINITIONS ::= BEGIN
        
        #{line}
        
        END
        """
        
        case SnmpLib.MIB.Parser.parse(test_content) do
          {:ok, _} ->
            IO.puts("    Line #{base_offset + idx + 1}: OK - #{String.slice(line, 0, 50)}")
          {:error, error} ->
            IO.puts("    Line #{base_offset + idx + 1}: ERROR - #{String.slice(line, 0, 50)}")
            IO.puts("      Error: #{inspect(error)}")
        end
      end
    end)
  end
  
  def test_subchunk(lines, start_idx, end_idx, base_offset) do
    mid_idx = div(start_idx + end_idx, 2)
    
    # Test first half
    first_half = Enum.slice(lines, start_idx, mid_idx - start_idx)
    first_content = """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    #{Enum.join(first_half, "\n")}
    
    END
    """
    
    case SnmpLib.MIB.Parser.parse(first_content) do
      {:ok, _} ->
        IO.puts("    Lines #{base_offset + start_idx + 1}-#{base_offset + mid_idx}: OK")
        # Error must be in second half
        test_subchunk(lines, mid_idx, end_idx, base_offset)
      {:error, _} ->
        IO.puts("    Lines #{base_offset + start_idx + 1}-#{base_offset + mid_idx}: ERROR")
        # Error is in first half
        test_subchunk(lines, start_idx, mid_idx, base_offset)
    end
  end
end

RealErrorFinder.find_errors()