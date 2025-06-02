#!/usr/bin/env elixir

Application.put_env(:snmp_lib, :environment, :test)

defmodule Test1to1Parser do
  @moduledoc "Test the actual 1:1 Erlang SNMP parser port"

  def test_real_parser do
    IO.puts("Testing real 1:1 Erlang SNMP MIB parser...")
    
    # Test 1: Initialize the parser
    IO.puts("\n🔧 Step 1: Compiling actual Erlang grammar...")
    
    case SnmpLib.MIB.ActualParser.init_parser() do
      {:ok, parser_module} ->
        IO.puts("✅ Success! Generated parser module: #{parser_module}")
        test_parsing_with_real_parser()
        
      {:error, reason} ->
        IO.puts("❌ Failed to compile grammar: #{inspect(reason)}")
        IO.puts("\n💡 This might be because:")
        IO.puts("   - Erlang/OTP SNMP application not available")
        IO.puts("   - Grammar file compilation issues")
        IO.puts("   - yecc not available in current Erlang installation")
        
        # Try to diagnose the issue
        diagnose_parser_issues()
    end
  end

  defp test_parsing_with_real_parser do
    IO.puts("\n🧪 Step 2: Testing with simple MIB...")
    
    simple_mib = """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    IMPORTS
        OBJECT-TYPE, Integer32
        FROM SNMPv2-SMI;
    
    testObject OBJECT IDENTIFIER ::= { test 1 }
    
    testValue OBJECT-TYPE
        SYNTAX      Integer32
        MAX-ACCESS  read-only
        STATUS      current
        DESCRIPTION "Test object"
        ::= { testObject 1 }
    
    END
    """
    
    case SnmpLib.MIB.ActualParser.parse(simple_mib) do
      {:ok, parsed_mib} ->
        IO.puts("✅ SUCCESS! Parsed with real Erlang grammar")
        IO.puts("   MIB name: #{parsed_mib.name}")
        IO.puts("   Version: #{parsed_mib.version}")
        IO.puts("   Definitions: #{length(parsed_mib.definitions)}")
        
        # Test on DOCS-IF-MIB
        test_docsis_with_real_parser()
        
      {:error, reason} ->
        IO.puts("❌ Parsing failed: #{inspect(reason)}")
    end
  end

  defp test_docsis_with_real_parser do
    IO.puts("\n🧪 Step 3: Testing DOCS-IF-MIB with real parser...")
    
    docs_if_path = "test/fixtures/mibs/docsis/DOCS-IF-MIB"
    
    if File.exists?(docs_if_path) do
      {:ok, content} = File.read(docs_if_path)
      
      case SnmpLib.MIB.ActualParser.parse(content) do
        {:ok, parsed_mib} ->
          IO.puts("✅ DOCS-IF-MIB SUCCESS with real parser!")
          IO.puts("   MIB name: #{parsed_mib.name}")
          IO.puts("   Version: #{parsed_mib.version}")
          IO.puts("   Definitions: #{length(parsed_mib.definitions)}")
          
          # Count OBJECT-TYPE definitions
          object_types = parsed_mib.definitions |> Enum.filter(& &1.__type__ == :objectType)
          IO.puts("   OBJECT-TYPE definitions: #{length(object_types)}")
          
        {:error, reason} ->
          IO.puts("❌ DOCS-IF-MIB failed: #{inspect(reason)}")
      end
    else
      IO.puts("⚠️  DOCS-IF-MIB file not found")
    end
  end

  defp diagnose_parser_issues do
    IO.puts("\n🔍 Diagnosing parser compilation issues...")
    
    # Check if yecc is available
    case Code.ensure_loaded(:yecc) do
      {:module, :yecc} ->
        IO.puts("✅ yecc module is available")
        
        # Check if SNMP application is available
        case Code.ensure_loaded(:snmpc_tok) do
          {:module, :snmpc_tok} ->
            IO.puts("✅ Erlang SNMP tokenizer is available")
          {:error, _} ->
            IO.puts("❌ Erlang SNMP application not available")
            IO.puts("   You may need to install erlang-snmp package")
        end
        
        # Check grammar file
        grammar_file = Path.join([File.cwd!(), "src", "snmpc_mib_gram.yrl"])
        if File.exists?(grammar_file) do
          IO.puts("✅ Grammar file exists: #{grammar_file}")
        else
          IO.puts("❌ Grammar file missing: #{grammar_file}")
        end
        
      {:error, _} ->
        IO.puts("❌ yecc parser generator not available")
        IO.puts("   This suggests Erlang/OTP development tools are missing")
    end
  end
end

Test1to1Parser.test_real_parser()