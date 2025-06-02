#!/usr/bin/env elixir

Application.put_env(:snmp_lib, :environment, :test)

defmodule FinalDocsisFixTest do
  @moduledoc "Test that the imports parser fix resolves the DOCSIS MAX-ACCESS issues"

  def test_final_fix do
    IO.puts("Testing final DOCSIS parser fix...")
    
    # Test the specific MIBs that were failing before
    test_mibs = [
      {"DOCS-CABLE-DEVICE-MIB", "test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB"},
      {"DOCS-IF-MIB", "test/fixtures/mibs/docsis/DOCS-IF-MIB"},
      {"DOCS-QOS-MIB", "test/fixtures/mibs/docsis/DOCS-QOS-MIB"}
    ]
    
    for {mib_name, file_path} <- test_mibs do
      IO.puts("\n" <> String.duplicate("=", 60))
      IO.puts("🧪 Testing #{mib_name}...")
      
      if File.exists?(file_path) do
        {:ok, content} = File.read(file_path)
        
        case SnmpLib.MIB.Parser.parse(content) do
          {:ok, mib} ->
            IO.puts("✅ SUCCESS: #{mib.name}")
            IO.puts("   📊 Total definitions: #{length(mib.definitions)}")
            
            # Count different types of definitions
            type_counts = mib.definitions
            |> Enum.group_by(& &1.__type__)
            |> Enum.map(fn {type, defs} -> {type, length(defs)} end)
            |> Enum.sort()
            
            type_counts |> Enum.each(fn {type, count} ->
              IO.puts("   📋 #{type}: #{count}")
            end)
            
            # Check for OBJECT-TYPE definitions with MAX-ACCESS
            object_types = mib.definitions |> Enum.filter(& &1.__type__ == :object_type)
            object_types_with_access = object_types |> Enum.filter(& Map.has_key?(&1, :max_access))
            
            IO.puts("   🎯 OBJECT-TYPE definitions: #{length(object_types)}")
            IO.puts("   🔐 With MAX-ACCESS: #{length(object_types_with_access)}")
            
            if length(object_types) > 0 and length(object_types_with_access) == 0 do
              IO.puts("   ⚠️  WARNING: No OBJECT-TYPE definitions have MAX-ACCESS clauses!")
            end
            
          {:error, [error]} ->
            IO.puts("❌ FAILED: #{error.type}")
            IO.puts("   💬 Message: #{error.message}")
            IO.puts("   📍 Line: #{error.line}")
            
          {:error, reason} when is_binary(reason) ->
            IO.puts("❌ FAILED: #{reason}")
            
          other ->
            IO.puts("❓ UNEXPECTED: #{inspect(other)}")
        end
      else
        IO.puts("⚠️  File not found: #{file_path}")
      end
    end
    
    IO.puts("\n" <> String.duplicate("=", 60))
    IO.puts("📋 Test Summary Complete")
  end
end

FinalDocsisFixTest.test_final_fix()