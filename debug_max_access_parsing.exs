#!/usr/bin/env elixir

Application.put_env(:snmp_lib, :environment, :test)

defmodule MaxAccessDebug do
  @moduledoc "Debug MAX-ACCESS parsing issue"

  def test_max_access_parsing do
    IO.puts("Testing MAX-ACCESS parsing...")
    
    # Create a minimal OBJECT-TYPE that should work
    test_tokens = [
      {:identifier, "TEST-MIB", 1},
      {:keyword, :definitions, 1}, 
      {:symbol, :assign, 1},
      {:keyword, :begin, 1},
      {:identifier, "testObject", 1},
      {:keyword, :object_type, 1},
      {:keyword, :syntax, 1},
      {:keyword, :integer, 1},
      {:keyword, :max_access, 1},
      {:identifier, "not-accessible", 1},
      {:keyword, :status, 1},
      {:identifier, "current", 1},
      {:symbol, :assign, 1},
      {:symbol, :open_brace, 1},
      {:identifier, "test", 1},
      {:integer, 1, 1},
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
          IO.puts("✅ Has syntax: #{Map.has_key?(def, :syntax)}")
          IO.puts("✅ Has max_access: #{Map.has_key?(def, :max_access)}")
          IO.puts("✅ Has status: #{Map.has_key?(def, :status)}")
          if Map.has_key?(def, :max_access), do: IO.puts("✅ Max access value: #{inspect(def.max_access)}")
        end
    end
  end
end

MaxAccessDebug.test_max_access_parsing()