#!/usr/bin/env elixir

IO.puts("🔍 TESTING MIB COMPILATION OUTPUT")
IO.puts("================================")

# Test parsing SMUX-MIB to see what we get
mib_content = File.read!("/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/SMUX-MIB.mib")

case SnmpLib.MIB.ActualParser.parse(mib_content) do
  {:ok, result} ->
    IO.puts("✅ Parsing successful!")
    IO.puts("Result type: #{inspect(result.__struct__)}")
    IO.puts("Available fields: #{inspect(Map.keys(result))}")
    
    # Check if we have actual MIB data structures
    if Map.has_key?(result, :name) do
      IO.puts("\n📋 MIB Name: #{result.name}")
    end
    
    if Map.has_key?(result, :object_types) do
      object_count = length(result.object_types || [])
      IO.puts("📊 Object Types: #{object_count}")
      
      if object_count > 0 do
        first_object = List.first(result.object_types)
        IO.puts("📄 Sample Object: #{inspect(first_object) |> String.slice(0, 100)}...")
      end
    end
    
    if Map.has_key?(result, :imports) do
      import_count = length(result.imports || [])
      IO.puts("📦 Imports: #{import_count}")
    end
    
    # Show overall structure
    IO.puts("\n🔍 Full result structure (first 300 chars):")
    result_str = inspect(result) |> String.slice(0, 300)
    IO.puts(result_str <> "...")
    
  {:error, reason} ->
    IO.puts("❌ Parsing failed: #{inspect(reason)}")
end

IO.puts("\n🎯 QUESTION: Do we have usable compiled MIB structures?")
IO.puts("Or do we need to add compilation beyond parsing?")