#!/usr/bin/env elixir

Application.put_env(:snmp_lib, :environment, :test)

defmodule FindCorruptionPointTest do
  @moduledoc "Find exactly where the parser state gets corrupted"

  def test_find_corruption_point do
    IO.puts("Finding where parser state gets corrupted...")
    
    {:ok, full_content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
    lines = String.split(full_content, "\n")
    
    # Test incrementally larger sections to find where MAX-ACCESS starts failing
    test_points = [2000, 2005, 2010, 2015, 2020, 2024, 2025, 2030]
    
    corruption_point = Enum.find(test_points, fn end_line ->
      test_content = lines
      |> Enum.take(end_line)
      |> Enum.join("\n")
      |> Kernel.<>("\nEND\n")
      
      result = SnmpLib.MIB.Parser.parse(test_content)
      
      case result do
        {:ok, mib} ->
          IO.puts("✅ Lines 1-#{end_line}: SUCCESS - #{length(mib.definitions)} definitions")
          false
          
        {:error, [error]} ->
          if String.contains?(error.message, "MAX-ACCESS") do
            IO.puts("❌ Lines 1-#{end_line}: MAX-ACCESS ERROR!")
            IO.puts("    Message: #{error.message}")
            true  # Found the corruption point
          else
            IO.puts("⚠️  Lines 1-#{end_line}: Other error: #{String.slice(error.message, 0, 50)}...")
            false
          end
          
        {:error, reason} when is_binary(reason) ->
          if String.contains?(reason, "MAX-ACCESS") do
            IO.puts("❌ Lines 1-#{end_line}: MAX-ACCESS ERROR!")
            IO.puts("    Message: #{reason}")
            true
          else
            IO.puts("⚠️  Lines 1-#{end_line}: Other error: #{String.slice(reason, 0, 50)}...")
            false
          end
          
        other ->
          IO.puts("❓ Lines 1-#{end_line}: Unexpected result: #{inspect(other)}")
          false
      end
    end)
    
    if corruption_point do
      IO.puts("\n🔍 Found corruption point at line #{corruption_point}")
    else
      IO.puts("\n❓ No corruption point found in test range")
    end
    
    # Now test if the issue is with the specific docsDevFilterPolicyStatus definition
    IO.puts("\n" <> String.duplicate("=", 60))
    IO.puts("Testing docsDevFilterPolicyStatus in isolation...")
    
    # Extract just that definition
    start_line = 2024 - 1  # 0-indexed
    end_line = 2034 - 1    # 0-indexed  
    problem_definition = Enum.slice(lines, start_line, end_line - start_line + 1)
    
    IO.puts("Problem definition lines:")
    problem_definition
    |> Enum.with_index(2024)
    |> Enum.each(fn {line, line_num} ->
      IO.puts("#{String.pad_leading(to_string(line_num), 4)}: #{line}")
    end)
    
    # Test this definition in a clean MIB
    isolated_test = """
    DOCS-CABLE-DEVICE-MIB DEFINITIONS ::= BEGIN
    
    IMPORTS
        OBJECT-TYPE
        FROM SNMPv2-SMI
        
        RowStatus
        FROM SNMPv2-TC;
    
    docsDevFilterPolicyEntry OBJECT IDENTIFIER ::= { test 1 }
    
    #{Enum.join(problem_definition, "\n")}
    
    END
    """
    
    result = SnmpLib.MIB.Parser.parse(isolated_test)
    
    case result do
      {:ok, mib} ->
        IO.puts("✅ Isolated test SUCCESS! #{length(mib.definitions)} definitions")
        mib.definitions |> Enum.each(fn def ->
          IO.puts("  - #{def.name} (#{def.__type__})")
          if def.__type__ == :object_type do
            IO.puts("    MAX-ACCESS: #{inspect(Map.get(def, :max_access))}")
          end
        end)
        
      {:error, [error]} ->
        IO.puts("❌ Isolated test FAILED!")
        IO.puts("    Type: #{error.type}")
        IO.puts("    Message: #{error.message}")
        
      {:error, reason} when is_binary(reason) ->
        IO.puts("❌ Isolated test FAILED!")
        IO.puts("    Message: #{reason}")
    end
  end
end

FindCorruptionPointTest.test_find_corruption_point()