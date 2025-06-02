#!/usr/bin/env elixir

Application.put_env(:snmp_lib, :environment, :test)

defmodule DebugConvertedTokens do
  def test_converted_tokens do
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
    
    IO.puts("🔍 Testing converted tokens...")
    
    case SnmpLib.MIB.ActualParser.tokenize(simple_mib) do
      {:ok, tokens} ->
        IO.puts("✅ Converted tokens for grammar:")
        Enum.with_index(tokens, 1) |> Enum.each(fn {token, index} ->
          IO.puts("   #{index}. #{inspect(token)}")
        end)
        
      {:error, reason} ->
        IO.puts("❌ Tokenization failed: #{inspect(reason)}")
    end
  end
end

DebugConvertedTokens.test_converted_tokens()