# Test the grammar-based parser

alias SnmpLib.MIB.{Parser, Lexer}

IO.puts("=== Testing Grammar-Based Parser ===")

# Test simple MIB
test_mib = """
CLAB-DEF-MIB DEFINITIONS ::= BEGIN

IMPORTS
    enterprises
        FROM SNMPv2-SMI;

cableLabs  OBJECT IDENTIFIER ::= { enterprises 4491 }

END
"""

IO.puts("🔍 Testing simple MIB...")

case Parser.parse(test_mib) do
  {:ok, mib} -> 
    IO.puts("✅ SUCCESS: Parsed simple MIB")
    IO.puts("   Name: #{mib.name}")
    IO.puts("   Imports: #{length(mib.imports)}")
    IO.puts("   Definitions: #{length(mib.definitions)}")
    
    # Now test a DOCSIS MIB
    IO.puts("\n🔍 Testing CLAB-DEF-MIB from DOCSIS collection...")
    
    docsis_path = "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/docsis/CLAB-DEF-MIB"
    case File.read(docsis_path) do
      {:ok, content} ->
        case Parser.parse(content) do
          {:ok, mib} ->
            IO.puts("✅ SUCCESS: Parsed CLAB-DEF-MIB")
            IO.puts("   Name: #{mib.name}")
            IO.puts("   Imports: #{length(mib.imports)}")
            IO.puts("   Definitions: #{length(mib.definitions)}")
          {:error, errors} when is_list(errors) ->
            first_error = List.first(errors)
            IO.puts("❌ Parse error: #{inspect(first_error)}")
          {:error, error} ->
            IO.puts("❌ Parse error: #{inspect(error)}")
        end
      {:error, reason} ->
        IO.puts("❌ Failed to read CLAB-DEF-MIB: #{inspect(reason)}")
    end
    
  {:error, errors} when is_list(errors) ->
    first_error = List.first(errors)
    IO.puts("❌ Parse error: #{inspect(first_error)}")
  {:error, error} ->
    IO.puts("❌ Parse error: #{inspect(error)}")
end