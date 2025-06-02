#!/usr/bin/env elixir

Application.put_env(:snmp_lib, :environment, :test)

defmodule LexerDebugTest do
  @moduledoc "Debug lexer tokenization"

  def test_object_group_tokenization do
    IO.puts("Testing OBJECT-GROUP tokenization...")
    
    content = """
    TEST-MIB DEFINITIONS ::= BEGIN
    testGroup OBJECT-GROUP
        OBJECTS { object1, object2, object3 }
        STATUS current
        DESCRIPTION "Test object group"
        ::= { test 1 }
    END
    """
    
    {:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)
    
    IO.puts("All tokens:")
    tokens
    |> Enum.with_index()
    |> Enum.each(fn {{type, value, line}, idx} ->
      IO.puts("  #{idx}: Line #{line}: #{inspect({type, value})}")
    end)
    
    # Find OBJECT-GROUP token specifically
    object_group_tokens = tokens
    |> Enum.filter(fn {type, value, _line} ->
      (type == :keyword and value == :object_group) or 
      (type == :identifier and String.downcase(value) == "object-group")
    end)
    
    IO.puts("\nOBJECT-GROUP related tokens:")
    object_group_tokens
    |> Enum.each(fn {type, value, line} ->
      IO.puts("  Line #{line}: #{inspect({type, value})}")
    end)
  end
end

LexerDebugTest.test_object_group_tokenization()