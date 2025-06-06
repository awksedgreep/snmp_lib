#!/usr/bin/env elixir

# Test different ranges of BITS values to find the limit

defmodule BitsRangeTester do
  def test_bits_with_value(value) do
  simple_mib = """
  TEST-MIB DEFINITIONS ::= BEGIN
  
  testObject OBJECT-TYPE
      SYNTAX      BITS {
                      test(#{value})
                  }
      MAX-ACCESS  read-create
      STATUS      current
      DESCRIPTION "Test"
      ::= { 1 2 3 }
  
  END
  """
  
  case SnmpLib.MIB.Parser.parse(simple_mib) do
    {:ok, _result} ->
      IO.puts("✓ BITS with value #{value}: SUCCESS")
    {:error, error} ->
      IO.puts("✗ BITS with value #{value}: FAILED - #{inspect(error)}")
  end
  
  def run do
    IO.puts("Testing BITS with different integer values...")

    # Test powers of 2 and specific problematic values
    test_values = [
      0, 1, 7, 8, 15, 16, 31, 32, 63, 64, 
      100, 127, 128, 200, 209, 225, 255, 256, 
      500, 1000, 57699
    ]

    Enum.each(test_values, &test_bits_with_value/1)
  end
end

BitsRangeTester.run()