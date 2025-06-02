#!/usr/bin/env elixir

# Debug specific lines around the error in DOCS-CABLE-DEVICE-MIB

mib_file = "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB"

case File.read(mib_file) do
  {:ok, content} ->
    lines = String.split(content, "\n")
    
    # Show lines around 2689
    start_line = max(1, 2689 - 15)
    end_line = min(length(lines), 2689 + 10)
    
    IO.puts("=== Lines #{start_line} to #{end_line} around error location (line 2689) ===")
    
    Enum.slice(lines, start_line-1, end_line-start_line+1)
    |> Enum.with_index(start_line)
    |> Enum.each(fn {line, line_num} ->
      marker = if line_num == 2689, do: " >>> ", else: "     "
      IO.puts("#{marker}#{line_num}: #{line}")
    end)
    
  {:error, reason} ->
    IO.puts("Error reading file: #{reason}")
end