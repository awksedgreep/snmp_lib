#!/usr/bin/env elixir

# Ensure we're in mix project mode and load compiled modules
System.put_env("MIX_ENV", "dev")
Code.require_file("mix.exs")

# Add build path to code loading
Code.append_path("_build/dev/lib/snmp_lib/ebin")

# Test direct module loading
try do
  # Force load the module
  Code.ensure_loaded!(SnmpLib.MIB.Parser)
  IO.puts("✅ SnmpLib.MIB.Parser module loaded successfully")
  
  # Test the parse function
  test_mib = """
  CLAB-DEF-MIB DEFINITIONS ::= BEGIN
  
  IMPORTS
      enterprises
          FROM SNMPv2-SMI;
  
  cableLabs  OBJECT IDENTIFIER ::= { enterprises 4491 }
  
  END
  """
  
  IO.puts("\n🔍 Testing simple MIB...")
  
  case SnmpLib.MIB.Parser.parse(test_mib) do
    {:ok, mib} -> 
      IO.puts("✅ SUCCESS: Parsed simple MIB")
      IO.puts("   Name: #{mib.name}")
      IO.puts("   Imports: #{length(mib.imports)}")
      IO.puts("   Definitions: #{length(mib.definitions)}")
    {:error, errors} when is_list(errors) ->
      first_error = List.first(errors)
      IO.puts("❌ Parse error: #{inspect(first_error)}")
    {:error, error} ->
      IO.puts("❌ Parse error: #{inspect(error)}")
  end
  
rescue
  e -> 
    IO.puts("❌ Exception: #{Exception.message(e)}")
    IO.puts("Stack trace: #{Exception.format_stacktrace(__STACKTRACE__)}")
end