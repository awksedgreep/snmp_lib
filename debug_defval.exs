#!/usr/bin/env elixir

# Load all the required modules
Code.require_file("lib/snmp_lib.ex")
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Parser, Lexer}

# Test MIB with DEFVAL issue
defmodule DefvalDebug do
  def test_defval_issue do
    # Extract just the problematic OBJECT-TYPE definition
    mib_with_defval = """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    IMPORTS
        MODULE-IDENTITY, OBJECT-TYPE,
        Integer32
            FROM SNMPv2-SMI;
    
    testBase OBJECT IDENTIFIER ::= { 1 3 6 1 4 1 99999 }
    
    docsDevSTPControl OBJECT-TYPE
        SYNTAX INTEGER {
            stEnabled(1),
            noStFilterBpdu(2),
            noStPassBpdu(3)
        }
        MAX-ACCESS  read-write
        STATUS      current
        DESCRIPTION
            "This object controls operation of the spanning tree protocol."
        DEFVAL { noStFilterBpdu }
        ::= { testBase 5 }
    
    END
    """
    
    IO.puts("🔍 Testing MIB with DEFVAL clause...")
    
    case Lexer.tokenize(mib_with_defval) do
      {:ok, tokens} ->
        IO.puts("✅ Tokenization: #{length(tokens)} tokens")
        
        # Find the DEFVAL token to confirm it's being tokenized correctly
        defval_tokens = Enum.filter(tokens, fn 
          {:keyword, :defval, _} -> true
          _ -> false
        end)
        IO.puts("Found #{length(defval_tokens)} DEFVAL tokens")
        
        case Parser.parse_tokens(tokens) do
          {:ok, mib} ->
            IO.puts("✅ Parsing successful!")
            IO.puts("  - MIB name: #{mib.name}")
            IO.puts("  - Definitions: #{length(mib.definitions)}")
            
            # Check if DEFVAL was preserved in the parsed object
            object_type = Enum.find(mib.definitions, fn def -> 
              def.__type__ == :object_type and def.name == "docsDevSTPControl"
            end)
            
            if object_type do
              IO.puts("  - Object type found: #{object_type.name}")
              IO.puts("  - Object fields: #{inspect(Map.keys(object_type))}")
            end
            
          {:error, errors} ->
            IO.puts("❌ Parsing failed: #{length(errors)} errors")
            Enum.each(errors, fn error ->
              IO.puts("  Error: #{inspect(error)}")
            end)
        end
        
      {:error, error} ->
        IO.puts("❌ Tokenization failed: #{inspect(error)}")
    end
  end
  
  def test_without_defval do
    # Test the same MIB without DEFVAL to isolate the issue
    mib_no_defval = """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    IMPORTS
        MODULE-IDENTITY, OBJECT-TYPE,
        Integer32
            FROM SNMPv2-SMI;
    
    testBase OBJECT IDENTIFIER ::= { 1 3 6 1 4 1 99999 }
    
    docsDevSTPControl OBJECT-TYPE
        SYNTAX INTEGER {
            stEnabled(1),
            noStFilterBpdu(2),
            noStPassBpdu(3)
        }
        MAX-ACCESS  read-write
        STATUS      current
        DESCRIPTION
            "This object controls operation of the spanning tree protocol."
        ::= { testBase 5 }
    
    END
    """
    
    IO.puts("\n🔍 Testing same MIB WITHOUT DEFVAL clause...")
    
    case Lexer.tokenize(mib_no_defval) do
      {:ok, tokens} ->
        IO.puts("✅ Tokenization: #{length(tokens)} tokens")
        
        case Parser.parse_tokens(tokens) do
          {:ok, mib} ->
            IO.puts("✅ Parsing successful!")
            IO.puts("  - MIB name: #{mib.name}")
            IO.puts("  - Definitions: #{length(mib.definitions)}")
            
          {:error, errors} ->
            IO.puts("❌ Parsing failed: #{length(errors)} errors")
            Enum.each(errors, fn error ->
              IO.puts("  Error: #{inspect(error)}")
            end)
        end
        
      {:error, error} ->
        IO.puts("❌ Tokenization failed: #{inspect(error)}")
    end
  end
end

DefvalDebug.test_without_defval()
DefvalDebug.test_defval_issue()