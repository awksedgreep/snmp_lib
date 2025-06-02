#!/usr/bin/env elixir

Application.put_env(:snmp_lib, :environment, :test)

defmodule ObjectIdentifierIssueTest do
  @moduledoc "Test OBJECT IDENTIFIER followed by OBJECT-TYPE"

  def test_object_identifier_issue do
    IO.puts("Testing OBJECT IDENTIFIER followed by OBJECT-TYPE...")
    
    # Test with the exact sequence from DOCS-CABLE-DEVICE-MIB
    test_tokens = [
      {:identifier, "TEST-MIB", 1},
      {:keyword, :definitions, 1},
      {:symbol, :assign, 1},
      {:keyword, :begin, 1},
      # First OBJECT IDENTIFIER
      {:identifier, "docsDevMIBObjects", 195},
      {:keyword, :object, 196},
      {:keyword, :identifier, 196},
      {:symbol, :assign, 196},
      {:symbol, :open_brace, 196},
      {:identifier, "docsDev", 196},
      {:integer, 1, 196},
      {:symbol, :close_brace, 196},
      # Second OBJECT IDENTIFIER  
      {:identifier, "docsDevBase", 198},
      {:keyword, :object, 198},
      {:keyword, :identifier, 198},
      {:symbol, :assign, 198},
      {:symbol, :open_brace, 198},
      {:identifier, "docsDevMIBObjects", 198},
      {:integer, 1, 198},
      {:symbol, :close_brace, 198},
      # Now the OBJECT-TYPE that fails
      {:identifier, "docsDevRole", 207},
      {:keyword, :object_type, 207},
      {:keyword, :syntax, 208},
      {:keyword, :integer, 208},
      {:symbol, :open_brace, 208},
      {:identifier, "cm", 209},
      {:symbol, :open_paren, 209},
      {:integer, 1, 209},
      {:symbol, :close_paren, 209},
      {:symbol, :comma, 209},
      {:identifier, "cmtsActive", 210},
      {:symbol, :open_paren, 210},
      {:integer, 2, 210},
      {:symbol, :close_paren, 210},
      {:symbol, :close_brace, 210},
      {:keyword, :max_access, 211},
      {:identifier, "read-only", 211},
      {:keyword, :status, 212},
      {:identifier, "current", 212},
      {:keyword, :description, 213},
      {:string, "Defines the current role of this device", 213},
      {:symbol, :assign, 214},
      {:symbol, :open_brace, 214},
      {:identifier, "docsDevBase", 214},
      {:integer, 1, 214},
      {:symbol, :close_brace, 214},
      {:keyword, :end, 999}
    ]
    
    IO.puts("Testing parsing...")
    result = SnmpLib.MIB.Parser.parse_tokens(test_tokens)
    
    case result do
      {:error, [error]} -> 
        IO.puts("❌ Error occurred:")
        IO.puts("  Type: #{error.type}")
        IO.puts("  Message: #{inspect(error.message)}")
        IO.puts("  Line: #{error.line}")
        
      {:ok, mib} -> 
        IO.puts("✅ Success! MIB name: #{mib.name}")
        IO.puts("✅ Definitions parsed: #{length(mib.definitions)}")
        
        mib.definitions
        |> Enum.with_index()
        |> Enum.each(fn {def, idx} ->
          IO.puts("  #{idx + 1}. #{def.name} (#{def.__type__})")
        end)
    end
  end
end

ObjectIdentifierIssueTest.test_object_identifier_issue()