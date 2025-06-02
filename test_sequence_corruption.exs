#!/usr/bin/env elixir

Application.put_env(:snmp_lib, :environment, :test)

defmodule SequenceCorruptionTest do
  @moduledoc "Test if SEQUENCE definitions corrupt the parser state for subsequent OBJECT-TYPE definitions"

  def test_sequence_corruption do
    IO.puts("Testing SEQUENCE definition impact on subsequent OBJECT-TYPE parsing...")
    
    # Test 1: OBJECT-TYPE without preceding SEQUENCE (should work)
    simple_test = """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    IMPORTS
        OBJECT-TYPE,
        Integer32
        FROM SNMPv2-SMI;
    
    testBase OBJECT IDENTIFIER ::= { test 1 }
    
    testObject OBJECT-TYPE
        SYNTAX      Integer32 (1..2147483647)
        MAX-ACCESS  not-accessible
        STATUS      current
        DESCRIPTION "Test object."
        ::= { testBase 1 }
    
    END
    """
    
    IO.puts("🧪 Test 1: Simple OBJECT-TYPE (baseline)")
    result1 = SnmpLib.MIB.Parser.parse(simple_test)
    
    case result1 do
      {:ok, mib} ->
        IO.puts("✅ SUCCESS: #{length(mib.definitions)} definitions")
        mib.definitions |> Enum.each(fn def ->
          if def.__type__ == :object_type do
            IO.puts("  - #{def.name}: MAX-ACCESS = #{inspect(Map.get(def, :max_access))}")
          end
        end)
        
      {:error, [error]} ->
        IO.puts("❌ FAILED: #{error.message}")
        
      {:error, reason} when is_binary(reason) ->
        IO.puts("❌ FAILED: #{reason}")
    end
    
    # Test 2: SEQUENCE followed by OBJECT-TYPE (the problematic case)
    sequence_test = """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    IMPORTS
        OBJECT-TYPE,
        Integer32
        FROM SNMPv2-SMI
        
        RowStatus
        FROM SNMPv2-TC;
    
    testBase OBJECT IDENTIFIER ::= { test 1 }
    
    TestEntry ::= SEQUENCE {
        testIndex   Integer32,
        testStatus  RowStatus
    }
    
    testObject OBJECT-TYPE
        SYNTAX      Integer32 (1..2147483647)
        MAX-ACCESS  not-accessible
        STATUS      current
        DESCRIPTION "Test object."
        ::= { testBase 1 }
    
    END
    """
    
    IO.puts("\n🧪 Test 2: SEQUENCE followed by OBJECT-TYPE (problematic case)")
    result2 = SnmpLib.MIB.Parser.parse(sequence_test)
    
    case result2 do
      {:ok, mib} ->
        IO.puts("✅ SUCCESS: #{length(mib.definitions)} definitions")
        mib.definitions |> Enum.each(fn def ->
          if def.__type__ == :object_type do
            IO.puts("  - #{def.name}: MAX-ACCESS = #{inspect(Map.get(def, :max_access))}")
          else
            IO.puts("  - #{def.name} (#{def.__type__})")
          end
        end)
        
      {:error, [error]} ->
        IO.puts("❌ FAILED: #{error.message}")
        
      {:error, reason} when is_binary(reason) ->
        IO.puts("❌ FAILED: #{reason}")
    end
    
    # Test 3: Extract the exact problematic content from DOCS-CABLE-DEVICE-MIB
    IO.puts("\n🧪 Test 3: Exact content from DOCS-CABLE-DEVICE-MIB around line 1989-2003")
    
    real_world_test = """
    DOCS-CABLE-DEVICE-MIB DEFINITIONS ::= BEGIN
    
    IMPORTS
        OBJECT-TYPE,
        Integer32
        FROM SNMPv2-SMI
        
        RowStatus,
        RowPointer
        FROM SNMPv2-TC;
    
    docsDevFilterPolicyTable OBJECT IDENTIFIER ::= { test 1 }
    docsDevFilterPolicyEntry OBJECT IDENTIFIER ::= { docsDevFilterPolicyTable 1 }
    
    DocsDevFilterPolicyEntry ::= SEQUENCE {
            docsDevFilterPolicyIndex   Integer32,
            docsDevFilterPolicyId      Integer32,
            docsDevFilterPolicyStatus  RowStatus,
            docsDevFilterPolicyPtr     RowPointer
        }

    docsDevFilterPolicyIndex OBJECT-TYPE
            SYNTAX      Integer32 (1..2147483647)
            MAX-ACCESS  not-accessible
            STATUS      deprecated
            DESCRIPTION "Index value for the table."
            ::= { docsDevFilterPolicyEntry 1 }
    
    END
    """
    
    result3 = SnmpLib.MIB.Parser.parse(real_world_test)
    
    case result3 do
      {:ok, mib} ->
        IO.puts("✅ SUCCESS: #{length(mib.definitions)} definitions")
        mib.definitions |> Enum.each(fn def ->
          if def.__type__ == :object_type do
            IO.puts("  - #{def.name}: MAX-ACCESS = #{inspect(Map.get(def, :max_access))}")
          else
            IO.puts("  - #{def.name} (#{def.__type__})")
          end
        end)
        
      {:error, [error]} ->
        IO.puts("❌ FAILED: #{error.message}")
        
      {:error, reason} when is_binary(reason) ->
        IO.puts("❌ FAILED: #{reason}")
    end
  end
end

SequenceCorruptionTest.test_sequence_corruption()