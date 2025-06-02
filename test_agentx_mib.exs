#!/usr/bin/env elixir

defmodule TestAgentxMib do
  def run do
    IO.puts("🧪 Testing enhanced 1:1 parser with AGENTX-MIB that contains MODULE-COMPLIANCE...")
    
    # Read the AGENTX-MIB file
    mib_path = "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/AGENTX-MIB.mib"
    
    case File.read(mib_path) do
      {:ok, mib_content} ->
        IO.puts("📄 Testing AGENTX-MIB.mib (contains MODULE-COMPLIANCE at line 480)")
        IO.puts("📊 File size: #{byte_size(mib_content)} bytes")
        
        case SnmpLib.MIB.ActualParser.parse(mib_content) do
          {:ok, parsed_result} ->
            IO.puts("✅ SUCCESS! Enhanced 1:1 parser successfully parsed AGENTX-MIB with MODULE-COMPLIANCE!")
            IO.puts("🎯 Parsed #{length(parsed_result.definitions)} definitions")
            
            # Show sample of parsed content
            IO.puts("📋 Sample parsed definitions:")
            parsed_result.definitions
            |> Enum.take(3)
            |> Enum.each(fn def ->
              IO.puts("  - #{def.__type__}: #{def.name}")
            end)
            
          {:error, reason} ->
            IO.puts("❌ PARSING_FAILED for AGENTX-MIB: #{inspect(reason)}")
            
            # Let's also try just tokenizing to see if the issue is in parsing or tokenization
            IO.puts("🔍 Testing tokenization separately...")
            case SnmpLib.MIB.ActualParser.tokenize(mib_content) do
              {:ok, tokens} ->
                IO.puts("✅ Tokenization successful! #{length(tokens)} tokens")
                
                # Look for MODULE-COMPLIANCE tokens
                module_compliance_tokens = tokens
                |> Enum.filter(fn
                  {:'MODULE-COMPLIANCE', _line} -> true
                  _ -> false
                end)
                
                IO.puts("🔍 Found #{length(module_compliance_tokens)} MODULE-COMPLIANCE tokens")
                
                # Look for MODULE tokens
                module_tokens = tokens
                |> Enum.filter(fn
                  {:'MODULE', _line} -> true
                  _ -> false
                end)
                
                IO.puts("🔍 Found #{length(module_tokens)} MODULE tokens")
                
              {:error, token_reason} ->
                IO.puts("❌ Tokenization failed: #{inspect(token_reason)}")
            end
        end
        
      {:error, file_error} ->
        IO.puts("❌ Failed to read MIB file: #{inspect(file_error)}")
    end
  end
end

TestAgentxMib.run()