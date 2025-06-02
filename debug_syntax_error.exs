#!/usr/bin/env elixir

Application.put_env(:snmp_lib, :environment, :test)

defmodule SyntaxErrorDebug do
  @moduledoc "Debug the syntax error in DOCS-IF-MIB"

  def test_docs_if_mib_syntax_error do
    IO.puts("Testing DOCS-IF-MIB syntax error around line 2875...")
    
    {:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-IF-MIB")
    {:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)
    
    # Find tokens around line 2875
    syntax_tokens = tokens
    |> Enum.with_index()
    |> Enum.filter(fn {{_type, _value, line}, _idx} -> line >= 2870 && line <= 2880 end)
    
    IO.puts("Tokens around line 2875:")
    syntax_tokens
    |> Enum.each(fn {{type, value, line}, idx} ->
      IO.puts("  #{idx}: Line #{line}: #{inspect({type, value})}")
    end)
    
    # Also look for the definition that should precede this syntax
    pre_tokens = tokens
    |> Enum.with_index()
    |> Enum.filter(fn {{_type, _value, line}, _idx} -> line >= 2860 && line <= 2875 end)
    
    IO.puts("\nTokens before the error:")
    pre_tokens
    |> Enum.each(fn {{type, value, line}, idx} ->
      IO.puts("  #{idx}: Line #{line}: #{inspect({type, value})}")
    end)
  end
end

SyntaxErrorDebug.test_docs_if_mib_syntax_error()