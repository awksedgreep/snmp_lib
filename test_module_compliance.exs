#!/usr/bin/env elixir

Application.put_env(:snmp_lib, :environment, :test)

defmodule ModuleComplianceTest do
  @moduledoc "Test MODULE-COMPLIANCE parsing fix"

  def test_module_compliance_parsing do
    IO.puts("Testing MODULE-COMPLIANCE parsing...")
    
    # Test basic MODULE-COMPLIANCE like in DOCS-IF-MIB
    test_tokens = [
      {:identifier, "TEST-MIB", 1},
      {:keyword, :definitions, 1}, 
      {:symbol, :assign, 1},
      {:keyword, :begin, 1},
      {:identifier, "testCompliance", 1},
      {:keyword, :module_compliance, 1},
      {:keyword, :status, 1},
      {:identifier, "current", 1},
      {:keyword, :description, 1},
      {:string, "Test compliance statement", 1},
      {:keyword, :module, 1},
      {:keyword, :mandatory_groups, 1},
      {:symbol, :open_brace, 1},
      {:identifier, "testGroup", 1},
      {:symbol, :close_brace, 1},
      {:keyword, :end, 1}
    ]
    
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
        
        if length(mib.definitions) > 0 do
          def = hd(mib.definitions)
          IO.puts("✅ Object name: #{def.name}")
          IO.puts("✅ Object type: #{def.__type__}")
          IO.puts("✅ Has status: #{Map.has_key?(def, :status)}")
          IO.puts("✅ Has description: #{Map.has_key?(def, :description)}")
          if Map.has_key?(def, :status), do: IO.puts("✅ Status value: #{inspect(def.status)}")
        end
    end
  end
end

ModuleComplianceTest.test_module_compliance_parsing()