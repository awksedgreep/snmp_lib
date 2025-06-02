#!/usr/bin/env elixir

Application.put_env(:snmp_lib, :environment, :test)

defmodule NamedTypeObjectDebug do
  @moduledoc "Debug named type OBJECT-TYPE parsing"

  def test_named_type_parsing do
    IO.puts("Testing named type OBJECT-TYPE parsing...")
    
    # Create the exact token sequence from docsIfDownstreamChannelEntry
    test_tokens = [
      {:identifier, "TEST-MIB", 1},
      {:keyword, :definitions, 1}, 
      {:symbol, :assign, 1},
      {:keyword, :begin, 1},
      {:identifier, "docsIfDownstreamChannelEntry", 1},
      {:keyword, :object_type, 1},
      {:keyword, :syntax, 1},
      {:identifier, "DocsIfDownstreamChannelEntry", 1},
      {:keyword, :max_access, 1},
      {:identifier, "not-accessible", 1},
      {:keyword, :status, 1},
      {:identifier, "current", 1},
      {:keyword, :description, 1},
      {:string, "An entry provides a list of attributes for a single downstream channel.", 1},
      {:keyword, :index, 1},
      {:symbol, :open_brace, 1},
      {:identifier, "ifIndex", 1},
      {:symbol, :close_brace, 1},
      {:symbol, :assign, 1},
      {:symbol, :open_brace, 1},
      {:identifier, "docsIfDownstreamChannelTable", 1},
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
          IO.puts("✅ Has index: #{Map.has_key?(def, :index)}")
          if Map.has_key?(def, :syntax), do: IO.puts("✅ Syntax value: #{inspect(def.syntax)}")
          if Map.has_key?(def, :max_access), do: IO.puts("✅ Max access value: #{inspect(def.max_access)}")
          if Map.has_key?(def, :index), do: IO.puts("✅ Index value: #{inspect(def.index)}")
        end
    end
  end
end

NamedTypeObjectDebug.test_named_type_parsing()