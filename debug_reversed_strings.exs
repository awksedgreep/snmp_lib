#!/usr/bin/env elixir

# Debug reversed string issue in MIB descriptions

Logger.configure(level: :warn)

IO.puts("🔍 Debugging Reversed String Issue")
IO.puts("=================================")

# Test with a simple MIB containing a description
test_mib = """
TEST-MIB DEFINITIONS ::= BEGIN

IMPORTS
    Integer32, OBJECT-TYPE, MODULE-IDENTITY
        FROM SNMPv2-SMI;

testObject OBJECT-TYPE
    SYNTAX Integer32
    MAX-ACCESS read-only
    STATUS current
    DESCRIPTION "This is a test description that should not be reversed"
    ::= { 1 3 6 1 4 1 12345 1 }

END
"""

IO.puts("Testing MIB parsing...")
case SnmpLib.MIB.Parser.parse(test_mib) do
  {:ok, mib_data} ->
    IO.puts("✅ Parsing successful")
    
    # Find the test object
    test_obj = Enum.find(mib_data.definitions, fn def ->
      def.name == "testObject"
    end)
    
    if test_obj do
      IO.puts("\n📝 Found test object:")
      IO.puts("  Name: #{test_obj.name}")
      IO.puts("  Description: #{inspect(test_obj.description)}")
      
      # Check if description is reversed
      desc_str = to_string(test_obj.description)
      IO.puts("  Description as string: \"#{desc_str}\"")
      
      if String.contains?(desc_str, "desrever") do
        IO.puts("❌ ISSUE CONFIRMED: Description is reversed!")
        IO.puts("  Expected: 'This is a test description that should not be reversed'")
        IO.puts("  Actual: '#{desc_str}'")
      else
        IO.puts("✅ Description appears correct")
      end
    else
      IO.puts("❌ Could not find test object")
    end
    
  {:error, reason} ->
    IO.puts("❌ Parsing failed: #{inspect(reason)}")
end

# Also test with a real DOCSIS MIB file to see the issue
IO.puts("\n🔍 Testing with real MIB file...")
docsis_dir = "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/docsis"

case File.read(Path.join(docsis_dir, "DOCS-IF-MIB")) do
  {:ok, content} ->
    case SnmpLib.MIB.Parser.parse(content) do
      {:ok, mib_data} ->
        # Find an object with description
        obj_with_desc = Enum.find(mib_data.definitions, fn def ->
          Map.has_key?(def, :description) and def.description != nil and 
          def.description != :undefined and String.length(to_string(def.description)) > 10
        end)
        
        if obj_with_desc do
          IO.puts("📝 Found object with description:")
          IO.puts("  Name: #{obj_with_desc.name}")
          desc_str = to_string(obj_with_desc.description)
          IO.puts("  Description (first 100 chars): \"#{String.slice(desc_str, 0, 100)}...\"")
          
          # Check for common reversed patterns
          if String.contains?(desc_str, " eht ") or String.contains?(desc_str, " fo ") do
            IO.puts("❌ ISSUE CONFIRMED: Real MIB description appears reversed!")
          else
            IO.puts("✅ Real MIB description appears correct")
          end
        else
          IO.puts("⚠️  Could not find object with description in real MIB")
        end
        
      {:error, reason} ->
        IO.puts("❌ Real MIB parsing failed: #{inspect(reason)}")
    end
    
  {:error, reason} ->
    IO.puts("❌ Could not read real MIB file: #{inspect(reason)}")
end