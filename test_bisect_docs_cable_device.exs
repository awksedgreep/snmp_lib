#!/usr/bin/env elixir

Application.put_env(:snmp_lib, :environment, :test)

defmodule BisectDocsCableDeviceTest do
  @moduledoc "Binary search for the exact point where DOCS-CABLE-DEVICE-MIB breaks"

  def test_bisect_parsing do
    IO.puts("Binary search for DOCS-CABLE-DEVICE-MIB parsing break point...")
    
    {:ok, full_content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
    lines = String.split(full_content, "\n")
    total_lines = length(lines)
    
    IO.puts("Total lines in MIB: #{total_lines}")
    
    # Binary search for the breaking point
    {breaking_line, _success} = binary_search_break_point(lines, 1, total_lines)
    
    IO.puts("Found breaking point around line #{breaking_line}")
    
    # Show a few lines around the breaking point for analysis
    context_start = max(1, breaking_line - 5)
    context_end = min(total_lines, breaking_line + 5)
    
    IO.puts("\n📄 Context around breaking point (lines #{context_start}-#{context_end}):")
    lines
    |> Enum.slice(context_start - 1, context_end - context_start + 1)
    |> Enum.with_index(context_start)
    |> Enum.each(fn {line, line_num} ->
      marker = if line_num == breaking_line, do: " 👈", else: ""
      IO.puts("#{String.pad_leading(to_string(line_num), 4)}: #{line}#{marker}")
    end)
  end
  
  defp binary_search_break_point(lines, low, high) when low >= high do
    {low, false}
  end
  
  defp binary_search_break_point(lines, low, high) do
    mid = div(low + high, 2)
    
    # Test parsing up to line mid
    test_content = lines
    |> Enum.take(mid)
    |> Enum.join("\n")
    |> Kernel.<>("\nEND\n")  # Add END to make it a valid MIB
    
    result = SnmpLib.MIB.Parser.parse(test_content)
    
    case result do
      {:ok, _mib} ->
        IO.puts("✅ Lines 1-#{mid}: Success")
        # If parsing succeeds, the break is after this point
        binary_search_break_point(lines, mid + 1, high)
        
      {:error, [error]} ->
        if String.contains?(error.message, "MAX-ACCESS") do
          IO.puts("❌ Lines 1-#{mid}: MAX-ACCESS error found!")
          # If we get the specific error we're looking for, narrow down before this point
          binary_search_break_point(lines, low, mid - 1)
        else
          IO.puts("❌ Lines 1-#{mid}: Other error: #{String.slice(error.message, 0, 40)}...")
          # For other errors, continue searching after this point
          binary_search_break_point(lines, mid + 1, high)
        end
      
      {:error, reason} when is_binary(reason) ->
        if String.contains?(reason, "MAX-ACCESS") do
          IO.puts("❌ Lines 1-#{mid}: MAX-ACCESS error found!")
          binary_search_break_point(lines, low, mid - 1)
        else
          IO.puts("❌ Lines 1-#{mid}: Other error: #{String.slice(reason, 0, 40)}...")
          binary_search_break_point(lines, mid + 1, high)
        end
        
      other_error ->
        IO.puts("❌ Lines 1-#{mid}: Unexpected error format: #{inspect(other_error)}")
        binary_search_break_point(lines, mid + 1, high)
    end
  end
end

BisectDocsCableDeviceTest.test_bisect_parsing()