#!/usr/bin/env elixir

Application.put_env(:snmp_lib, :environment, :test)

defmodule IntegerConstraintTest do
  @moduledoc "Test integer constraint parsing fix"

  def test_constraint_parsing do
    IO.puts("Testing integer constraint parsing...")
    
    # Test complex constraint like (0 | 64..66 | 68..70 | 72 | 74..78)
    test_tokens = [
      {:identifier, "TEST-MIB", 1},
      {:keyword, :definitions, 1}, 
      {:symbol, :assign, 1},
      {:keyword, :begin, 1},
      {:identifier, "testObject", 1},
      {:keyword, :object_type, 1},
      {:keyword, :syntax, 1},
      {:keyword, :integer, 1},
      {:symbol, :open_paren, 1},
      {:integer, 0, 1},
      {:symbol, :pipe, 1},
      {:integer, 64, 1},
      {:symbol, :range, 1},
      {:integer, 66, 1},
      {:symbol, :pipe, 1},
      {:integer, 68, 1},
      {:symbol, :range, 1},
      {:integer, 70, 1},
      {:symbol, :pipe, 1},
      {:integer, 72, 1},
      {:symbol, :close_paren, 1},
      {:keyword, :max_access, 1},
      {:identifier, "read-only", 1},
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
          if Map.has_key?(def, :syntax), do: IO.puts("✅ Syntax value: #{inspect(def.syntax)}")
        end
    end
  end
end

IntegerConstraintTest.test_constraint_parsing()