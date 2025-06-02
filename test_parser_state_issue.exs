#!/usr/bin/env elixir

Application.put_env(:snmp_lib, :environment, :test)

defmodule ParserStateIssueTest do
  @moduledoc "Test if parser state is the issue causing MAX-ACCESS validation problems"

  def test_parser_state do
    IO.puts("Testing parser state issue...")
    
    # Get the lines around the problematic area
    {:ok, full_content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
    lines = String.split(full_content, "\n")
    
    # Test exactly lines 2018-2035 which contain the problematic definition
    test_lines = Enum.slice(lines, 2017, 18)  # Lines 2018-2035
    
    IO.puts("Extracted lines around the issue:")
    test_lines
    |> Enum.with_index(2018)
    |> Enum.each(fn {line, line_num} ->
      IO.puts("#{String.pad_leading(to_string(line_num), 4)}: #{line}")
    end)
    
    # Create a minimal test that includes proper header + this section
    minimal_test = """
    DOCS-CABLE-DEVICE-MIB DEFINITIONS ::= BEGIN
    
    IMPORTS
        OBJECT-TYPE,
        Integer32
        FROM SNMPv2-SMI
        
        RowStatus,
        RowPointer
        FROM SNMPv2-TC;
    
    docsDevFilterPolicyEntry OBJECT IDENTIFIER ::= { test 1 }
    
    #{Enum.join(test_lines, "\n")}
    
    END
    """
    
    IO.puts("\n" <> String.duplicate("=", 60))
    IO.puts("Testing minimal MIB with problematic section...")
    
    result = SnmpLib.MIB.Parser.parse(minimal_test)
    
    case result do
      {:error, [error]} -> 
        IO.puts("❌ Error occurred:")
        IO.puts("  Type: #{error.type}")
        IO.puts("  Message: #{inspect(error.message)}")
        IO.puts("  Line: #{error.line}")
        
      {:error, reason} when is_binary(reason) ->
        IO.puts("❌ String error: #{reason}")
        
      {:ok, mib} -> 
        IO.puts("✅ Success! MIB name: #{mib.name}")
        IO.puts("✅ Definitions parsed: #{length(mib.definitions)}")
        
        mib.definitions
        |> Enum.each(fn def ->
          IO.puts("  - #{def.name} (#{def.__type__})")
        end)
    end
    
    # Now let's test tokenization of just the problematic OBJECT-TYPE
    IO.puts("\n" <> String.duplicate("=", 60))
    IO.puts("Testing tokenization of just the problematic OBJECT-TYPE...")
    
    just_object_type = """
    docsDevFilterPolicyStatus OBJECT-TYPE
            SYNTAX      RowStatus
            MAX-ACCESS  read-create
            STATUS      deprecated
            DESCRIPTION
                "Object used to create an entry in this table.  There is
                 no restriction in changing any object in a row while
                 this object is set to active.
                 The following object MUST have a valid value before this
                 object can be set to active:  docsDevFilterPolicyPtr."
            ::= { docsDevFilterPolicyEntry 5 }
    """
    
    case SnmpLib.MIB.Lexer.tokenize(just_object_type) do
      {:ok, tokens} ->
        IO.puts("✅ Tokenization successful! Found #{length(tokens)} tokens")
        
        # Show the first few tokens
        tokens
        |> Enum.take(15)
        |> Enum.with_index()
        |> Enum.each(fn {{type, value, line}, idx} ->
          IO.puts("  #{idx}: {:#{type}, #{inspect(value)}, #{line}}")
        end)
        
      {:error, reason} ->
        IO.puts("❌ Tokenization failed: #{inspect(reason)}")
    end
  end
end

ParserStateIssueTest.test_parser_state()