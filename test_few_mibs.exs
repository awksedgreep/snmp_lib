#!/usr/bin/env elixir

defmodule TestFewMibs do
  def run do
    IO.puts("🧪 Testing 1:1 parser with a few MIBs...")
    
    # Test a small subset first
    test_files = [
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/SNMPv2-SMI.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/SNMPv2-TC.mib", 
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/RFC1155-SMI.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/docsis/INET-ADDRESS-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/broken/IPV6-TC.mib"
    ]
    
    results = %{success: 0, failed: 0, errors: []}
    
    Enum.each(test_files, fn file_path ->
      filename = Path.basename(file_path)
      directory = file_path |> Path.dirname() |> Path.basename()
      
      IO.write("🔍 Testing #{directory}/#{filename}...")
      
      case File.read(file_path) do
        {:ok, content} ->
          case SnmpLib.MIB.ActualParser.parse(content) do
            {:ok, result} ->
              defs_count = length(Map.get(result, :definitions, []))
              IO.puts(" ✅ SUCCESS (#{defs_count} definitions)")
              
            {:error, reason} ->
              IO.puts(" ❌ FAILED: #{inspect(reason)}")
          end
          
        {:error, error} ->
          IO.puts(" ❌ FILE_ERROR: #{inspect(error)}")
      end
    end)
  end
end

TestFewMibs.run()