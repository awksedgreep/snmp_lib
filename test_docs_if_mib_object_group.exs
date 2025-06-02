#!/usr/bin/env elixir

Application.put_env(:snmp_lib, :environment, :test)

defmodule DocsIfMibObjectGroupTest do
  @moduledoc "Test DOCS-IF-MIB with OBJECT-GROUP fix"

  def test_docs_if_mib_parsing do
    IO.puts("Testing DOCS-IF-MIB with OBJECT-GROUP support...")
    
    {:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-IF-MIB")
    result = SnmpLib.MIB.Parser.parse(content)
    
    case result do
      {:error, [error]} -> 
        IO.puts("❌ DOCS-IF-MIB still has errors:")
        IO.puts("  Type: #{error.type}")
        IO.puts("  Message: #{inspect(error.message)}")
        IO.puts("  Line: #{error.line}")
        
        # Let's see if we've progressed further
        if String.contains?(error.message, "OBJECT-GROUP") do
          IO.puts("  Still failing on OBJECT-GROUP parsing")
        else
          IO.puts("  ✅ OBJECT-GROUP issue resolved - now failing on: #{error.message}")
        end
        
      {:ok, mib} -> 
        IO.puts("✅ DOCS-IF-MIB parsed successfully!")
        IO.puts("✅ MIB name: #{mib.name}")
        IO.puts("✅ Definitions parsed: #{length(mib.definitions)}")
        
        # Count different types of definitions
        type_counts = mib.definitions
        |> Enum.group_by(& &1.__type__)
        |> Enum.map(fn {type, defs} -> {type, length(defs)} end)
        |> Enum.sort()
        
        IO.puts("✅ Definition types:")
        type_counts
        |> Enum.each(fn {type, count} ->
          IO.puts("  - #{type}: #{count}")
        end)
    end
  end
end

DocsIfMibObjectGroupTest.test_docs_if_mib_parsing()