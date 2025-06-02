#!/usr/bin/env elixir

Application.put_env(:snmp_lib, :environment, :test)

defmodule ObjectGroupMinimalTest do
  @moduledoc "Minimal OBJECT-GROUP parsing test"

  def test_object_group_parsing do
    IO.puts("Testing minimal OBJECT-GROUP parsing...")
    
    # Use the exact tokens from the lexer output
    test_tokens = [
      {:identifier, "TEST-MIB", 1},
      {:keyword, :definitions, 1},
      {:symbol, :assign, 1},
      {:keyword, :begin, 1},
      {:identifier, "testGroup", 2},
      {:keyword, :object_group, 2},
      {:keyword, :objects, 3},
      {:symbol, :open_brace, 3},
      {:identifier, "object1", 3},
      {:symbol, :comma, 3},
      {:identifier, "object2", 3},
      {:symbol, :comma, 3},
      {:identifier, "object3", 3},
      {:symbol, :close_brace, 3},
      {:keyword, :status, 4},
      {:identifier, "current", 4},
      {:keyword, :description, 5},
      {:string, "Test object group", 5},
      {:symbol, :assign, 6},
      {:symbol, :open_brace, 6},
      {:identifier, "test", 6},
      {:integer, 1, 6},
      {:symbol, :close_brace, 6},
      {:keyword, :end, 7}
    ]
    
    # Debug the parser step by step
    IO.puts("Calling parse_tokens...")
    result = SnmpLib.MIB.Parser.parse_tokens(test_tokens)
    
    case result do
      {:error, [error]} -> 
        IO.puts("❌ Error occurred:")
        IO.puts("  Type: #{error.type}")
        IO.puts("  Message: #{inspect(error.message)}")
        IO.puts("  Line: #{error.line}")
        
        # Let's also try to debug by calling the definition parser directly
        IO.puts("\n--- Debugging parse_definition directly ---")
        
        # The tokens that should be passed to parse_definition for testGroup
        definition_tokens = [
          {:keyword, :object_group, 2},
          {:keyword, :objects, 3},
          {:symbol, :open_brace, 3},
          {:identifier, "object1", 3},
          {:symbol, :comma, 3},
          {:identifier, "object2", 3},
          {:symbol, :comma, 3},
          {:identifier, "object3", 3},
          {:symbol, :close_brace, 3},
          {:keyword, :status, 4},
          {:identifier, "current", 4},
          {:keyword, :description, 5},
          {:string, "Test object group", 5},
          {:symbol, :assign, 6},
          {:symbol, :open_brace, 6},
          {:identifier, "test", 6},
          {:integer, 1, 6},
          {:symbol, :close_brace, 6}
        ]
        
        IO.puts("These should be the tokens passed to parse_definition:")
        definition_tokens
        |> Enum.with_index()
        |> Enum.each(fn {{type, value, line}, idx} ->
          IO.puts("  #{idx}: Line #{line}: #{inspect({type, value})}")
        end)
        
      {:ok, mib} -> 
        IO.puts("✅ Success! MIB name: #{mib.name}")
        IO.puts("✅ Definitions parsed: #{length(mib.definitions)}")
        
        if length(mib.definitions) > 0 do
          def = hd(mib.definitions)
          IO.puts("✅ Object name: #{def.name}")
          IO.puts("✅ Object type: #{def.__type__}")
          IO.puts("✅ Has objects: #{Map.has_key?(def, :objects)}")
          IO.puts("✅ Has status: #{Map.has_key?(def, :status)}")
          IO.puts("✅ Has description: #{Map.has_key?(def, :description)}")
          if Map.has_key?(def, :objects), do: IO.puts("✅ Objects: #{inspect(def.objects)}")
          if Map.has_key?(def, :status), do: IO.puts("✅ Status value: #{inspect(def.status)}")
        end
    end
  end
end

ObjectGroupMinimalTest.test_object_group_parsing()