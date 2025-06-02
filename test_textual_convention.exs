#!/usr/bin/env elixir

Application.put_env(:snmp_lib, :environment, :test)

defmodule TextualConventionTest do
  @moduledoc "Test TEXTUAL-CONVENTION parsing fix"

  def test_docs_if_mib do
    IO.puts("Testing DOCS-IF-MIB TEXTUAL-CONVENTION parsing...")
    
    {:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-IF-MIB")
    {:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)
    
    result = SnmpLib.MIB.Parser.parse_tokens(tokens)
    
    case result do
      {:error, [error]} -> 
        IO.puts("❌ Error occurred:")
        IO.puts("  Type: #{error.type}")
        IO.puts("  Message: #{inspect(error.message)}")
        IO.puts("  Line: #{error.line}")
      {:ok, mib} -> 
        IO.puts("✅ Success! MIB name: #{mib.name}")
        IO.puts("✅ Definitions parsed: #{length(mib.definitions)}")
        
        # Check for TEXTUAL-CONVENTION definitions
        textual_conventions = Enum.filter(mib.definitions, fn def ->
          def.__type__ == :textual_convention
        end)
        
        IO.puts("✅ TEXTUAL-CONVENTION definitions: #{length(textual_conventions)}")
        
        # Show the first few textual conventions
        textual_conventions
        |> Enum.take(3)
        |> Enum.each(fn tc ->
          IO.puts("  - #{tc.name}: #{inspect(tc.syntax)}")
        end)
    end
  end
end

TextualConventionTest.test_docs_if_mib()