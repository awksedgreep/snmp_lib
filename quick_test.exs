#!/usr/bin/env elixir

# Load all the required modules
Code.require_file("lib/snmp_lib.ex")
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

# Test the ported parser on DOCSIS MIBs
alias SnmpLib.MIB.{Parser, Lexer}

defmodule QuickTest do
  def test_docsis_mib do
    file_path = "test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB"
    
    IO.puts("🔍 Testing DOCS-CABLE-DEVICE-MIB with ported parser...")
    
    case File.read(file_path) do
      {:ok, content} ->
        IO.puts("✅ File read: #{String.length(content)} characters")
        
        case Lexer.tokenize(content) do
          {:ok, tokens} ->
            IO.puts("✅ Tokenization: #{length(tokens)} tokens")
            
            case Parser.parse_tokens(tokens) do
              {:ok, mib} ->
                IO.puts("✅ Parsing successful!")
                IO.puts("  - MIB name: #{mib.name}")
                IO.puts("  - Definitions: #{length(mib.definitions)}")
                IO.puts("  - Imports: #{length(mib.imports)}")
                IO.puts("  - Version: #{mib.version}")
                
                # Show breakdown of definition types
                type_counts = mib.definitions
                |> Enum.group_by(& &1.__type__)
                |> Enum.map(fn {type, list} -> {type, length(list)} end)
                |> Enum.sort_by(fn {_, count} -> count end, :desc)
                
                IO.puts("  - Definition types:")
                Enum.each(type_counts, fn {type, count} ->
                  IO.puts("    • #{type}: #{count}")
                end)
                
                :success
                
              {:error, errors} ->
                IO.puts("❌ Parsing failed: #{length(errors)} errors")
                Enum.each(Enum.take(errors, 3), fn error ->
                  IO.puts("  Error: #{inspect(error)}")
                end)
                :failed
            end
            
          {:error, error} ->
            IO.puts("❌ Tokenization failed: #{inspect(error)}")
            :failed
        end
        
      {:error, reason} ->
        IO.puts("❌ File read failed: #{reason}")
        :failed
    end
  end
  
  def test_small_mib do
    IO.puts("\n🔍 Testing smaller MIB first...")
    
    simple_mib = """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    IMPORTS
        MODULE-IDENTITY, OBJECT-TYPE,
        Integer32
            FROM SNMPv2-SMI;
    
    testMib MODULE-IDENTITY
        LAST-UPDATED "200001010000Z"
        ORGANIZATION "Test Org"
        CONTACT-INFO "test@example.com"
        DESCRIPTION "A simple test MIB"
        ::= { 1 3 6 1 4 1 99999 1 }
    
    testObject OBJECT-TYPE
        SYNTAX      Integer32
        MAX-ACCESS  read-only
        STATUS      current
        DESCRIPTION "A test object"
        ::= { testMib 1 }
    
    END
    """
    
    case Lexer.tokenize(simple_mib) do
      {:ok, tokens} ->
        IO.puts("✅ Simple MIB tokenization: #{length(tokens)} tokens")
        
        case Parser.parse_tokens(tokens) do
          {:ok, mib} ->
            IO.puts("✅ Simple MIB parsing successful!")
            IO.puts("  - Name: #{mib.name}")
            IO.puts("  - Definitions: #{length(mib.definitions)}")
            :success
            
          {:error, errors} ->
            IO.puts("❌ Simple MIB parsing failed: #{length(errors)} errors")
            Enum.each(errors, fn error ->
              IO.puts("  Error: #{inspect(error)}")
            end)
            :failed
        end
        
      {:error, error} ->
        IO.puts("❌ Simple MIB tokenization failed: #{inspect(error)}")
        :failed
    end
  end
end

# Run the tests
IO.puts("=" |> String.duplicate(70))
IO.puts("🧪 PORTED PARSER VALIDATION TEST")
IO.puts("=" |> String.duplicate(70))

small_result = QuickTest.test_small_mib()
docsis_result = QuickTest.test_docsis_mib()

IO.puts("\n" <> "=" |> String.duplicate(70))
IO.puts("📊 TEST RESULTS")
IO.puts("=" |> String.duplicate(70))
IO.puts("Simple MIB: #{small_result}")
IO.puts("DOCSIS MIB: #{docsis_result}")

case {small_result, docsis_result} do
  {:success, :success} ->
    IO.puts("🎉 EXCELLENT: Ported parser is working perfectly!")
  {:success, :failed} ->
    IO.puts("🎯 GOOD: Simple parsing works, DOCSIS needs debugging")
  {:failed, _} ->
    IO.puts("🚨 ISSUE: Basic parsing is failing, needs investigation")
end