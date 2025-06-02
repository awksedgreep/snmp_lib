#!/usr/bin/env elixir

defmodule TestRealMib do
  def run do
    IO.puts("🧪 Testing enhanced 1:1 parser with real MIB files...")
    
    # Test with a few real MIB files to verify functionality
    test_files = [
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/RFC1155-SMI.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/SNMPv2-SMI.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/SNMPv2-TC.mib"
    ]
    
    Enum.each(test_files, fn file_path ->
      filename = Path.basename(file_path)
      IO.puts("\n🔍 Testing #{filename}...")
      
      case File.read(file_path) do
        {:ok, content} ->
          case SnmpLib.MIB.ActualParser.parse(content) do
            {:ok, parsed_result} ->
              definitions_count = length(Map.get(parsed_result, :definitions, []))
              IO.puts("✅ SUCCESS: #{filename} (#{definitions_count} definitions)")
              IO.puts("   📋 MIB name: #{parsed_result.name}")
              IO.puts("   📋 Version: #{parsed_result.version}")
              IO.puts("   📋 Imports: #{length(parsed_result.imports)} modules")
              IO.puts("   📋 Exports: #{length(parsed_result.exports)} items")
              
            {:error, reason} ->
              IO.puts("❌ FAILED: #{filename}")
              IO.puts("   💥 Error: #{inspect(reason)}")
          end
          
        {:error, file_error} ->
          IO.puts("❌ FILE_ERROR: #{filename} - #{inspect(file_error)}")
      end
    end)
    
    IO.puts("\n🎯 Enhanced 1:1 parser test completed!")
  end
end

TestRealMib.run()