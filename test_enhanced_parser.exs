#!/usr/bin/env elixir

defmodule TestEnhancedParser do
  def run do
    IO.puts("🧪 Testing enhanced 1:1 parser with realistic MIB content...")
    
    # Test with a minimal valid SNMPv1 MIB structure
    mib_content = """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    testObject OBJECT-TYPE
        SYNTAX INTEGER
        ACCESS read-only
        STATUS mandatory
        DESCRIPTION "A test object"
        ::= { test 1 }
    
    END
    """
    
    IO.puts("📄 Testing MIB content:")
    IO.puts(mib_content)
    
    case SnmpLib.MIB.ActualParser.parse(mib_content) do
      {:ok, parsed_result} ->
        IO.puts("✅ SUCCESS! Enhanced 1:1 parser working!")
        IO.puts("🎯 Parsed result:")
        IO.inspect(parsed_result, pretty: true, limit: :infinity)
        
      {:error, reason} ->
        IO.puts("❌ PARSING_FAILED: #{inspect(reason)}")
    end
  end
end

TestEnhancedParser.run()