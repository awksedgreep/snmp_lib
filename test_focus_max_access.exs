#!/usr/bin/env elixir

Application.put_env(:snmp_lib, :environment, :test)

defmodule FocusMaxAccessTest do
  @moduledoc "Focus on the exact MAX-ACCESS issue around line 2024"

  def test_focus_issue do
    IO.puts("Testing MAX-ACCESS issue with focused content around line 2024...")
    
    # Test content starting from line 2005 through 2035
    {:ok, full_content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
    lines = String.split(full_content, "\n")
    
    # Take lines 1-2023 (which work) plus the problem area 2024-2035
    working_lines = Enum.take(lines, 2023)
    problem_lines = Enum.slice(lines, 2023, 12)  # Lines 2024-2035
    
    test_content = (working_lines ++ problem_lines)
    |> Enum.join("\n")
    |> Kernel.<>("\nEND\n")
    
    IO.puts("Testing with lines 1-2023 plus 2024-2035...")
    result = SnmpLib.MIB.Parser.parse(test_content)
    
    case result do
      {:error, [error]} -> 
        IO.puts("❌ Error occurred:")
        IO.puts("  Type: #{error.type}")
        IO.puts("  Message: #{inspect(error.message)}")
        IO.puts("  Line: #{error.line}")
        
        # Show the specific line that failed
        if error.line > 0 and error.line <= length(working_lines) + length(problem_lines) do
          failed_line = Enum.at(working_lines ++ problem_lines, error.line - 1)
          IO.puts("  Failed on line #{error.line}: #{failed_line}")
        end
        
      {:ok, mib} -> 
        IO.puts("✅ Success! MIB name: #{mib.name}")
        IO.puts("✅ Definitions parsed: #{length(mib.definitions)}")
        
        # Show the last few definitions
        mib.definitions
        |> Enum.take(-3)
        |> Enum.with_index(length(mib.definitions) - 2)
        |> Enum.each(fn {def, idx} ->
          IO.puts("  #{idx}. #{def.name} (#{def.__type__})")
        end)
    end
    
    # Now test just the problem area in isolation
    IO.puts("\n" <> String.duplicate("=", 60))
    IO.puts("Testing JUST the problem area (docsDevFilterPolicyStatus)...")
    
    isolated_test = """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    IMPORTS
        RowStatus
        FROM SNMPv2-TC;
    
    docsDevFilterPolicyEntry OBJECT IDENTIFIER ::= { test 1 }
    
    docsDevFilterPolicyStatus OBJECT-TYPE
            SYNTAX      RowStatus
            MAX-ACCESS  read-create
            STATUS      deprecated
            DESCRIPTION
                "Object used to create an entry in this table."
            ::= { docsDevFilterPolicyEntry 5 }
    
    END
    """
    
    result2 = SnmpLib.MIB.Parser.parse(isolated_test)
    
    case result2 do
      {:error, [error]} -> 
        IO.puts("❌ Isolated test failed:")
        IO.puts("  Type: #{error.type}")
        IO.puts("  Message: #{inspect(error.message)}")
        IO.puts("  Line: #{error.line}")
        
      {:ok, mib} -> 
        IO.puts("✅ Isolated test SUCCESS! MIB name: #{mib.name}")
        IO.puts("✅ Definitions parsed: #{length(mib.definitions)}")
    end
  end
end

FocusMaxAccessTest.test_focus_issue()