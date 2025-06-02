#!/usr/bin/env elixir

defmodule TestEnhancedFixes do
  def run do
    IO.puts("🧪 Testing enhanced 1:1 parser with fixes for MODULE-COMPLIANCE...")
    
    # Let's test with a minimal MODULE-COMPLIANCE example first
    minimal_mib = """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    IMPORTS
        MODULE-COMPLIANCE, OBJECT-GROUP
            FROM SNMPv2-CONF;
    
    testCompliance MODULE-COMPLIANCE
        STATUS current
        DESCRIPTION "Test compliance"
        MODULE -- this module
            MANDATORY-GROUPS { testGroup }
        ::= { test 1 }
        
    END
    """
    
    IO.puts("📄 Testing minimal MODULE-COMPLIANCE MIB...")
    
    case SnmpLib.MIB.ActualParser.parse(minimal_mib) do
      {:ok, parsed_result} ->
        IO.puts("✅ SUCCESS! MODULE-COMPLIANCE parsing working!")
        IO.puts("🎯 Parsed #{length(parsed_result.definitions)} definitions")
        
      {:error, reason} ->
        IO.puts("❌ Minimal MODULE-COMPLIANCE failed: #{inspect(reason)}")
        
        # Test just tokenization
        IO.puts("🔍 Testing tokenization...")
        case SnmpLib.MIB.ActualParser.tokenize(minimal_mib) do
          {:ok, tokens} ->
            IO.puts("✅ Tokenization successful! #{length(tokens)} tokens")
            
            # Look for key tokens
            compliance_tokens = tokens |> Enum.count(fn {t, _} -> t == :'MODULE-COMPLIANCE' end)
            module_tokens = tokens |> Enum.count(fn {t, _} -> t == :'MODULE' end)
            
            IO.puts("   - MODULE-COMPLIANCE tokens: #{compliance_tokens}")
            IO.puts("   - MODULE tokens: #{module_tokens}")
            
          {:error, token_reason} ->
            IO.puts("❌ Tokenization failed: #{inspect(token_reason)}")
        end
    end
    
    IO.puts("\n" <> String.duplicate("=", 60))
    IO.puts("🧪 Now testing with sample of previously failing MIBs...")
    
    # Test a few MIBs that were failing with MODULE-COMPLIANCE issues
    failing_mibs = [
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/AGENTX-MIB.mib"
    ]
    
    Enum.each(failing_mibs, fn mib_path ->
      mib_name = Path.basename(mib_path)
      IO.puts("\n📄 Testing #{mib_name}...")
      
      case File.read(mib_path) do
        {:ok, mib_content} ->
          case SnmpLib.MIB.ActualParser.parse(mib_content) do
            {:ok, parsed_result} ->
              IO.puts("✅ SUCCESS: #{mib_name} parsed successfully!")
              IO.puts("   Parsed #{length(parsed_result.definitions)} definitions")
              
            {:error, reason} ->
              IO.puts("❌ FAILED: #{mib_name} - #{inspect(reason)}")
          end
          
        {:error, file_error} ->
          IO.puts("❌ File read error: #{inspect(file_error)}")
      end
    end)
  end
end

TestEnhancedFixes.run()