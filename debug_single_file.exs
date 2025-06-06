#!/usr/bin/env elixir

# Test a single problematic MIB file to see the exact error format
Mix.install([])

# Add the lib directory to the code path
Code.append_path("lib")
Code.require_file("lib/snmp_lib/mib/parser.ex")

defmodule SingleFileTest do
  def test_file(filename) do
    IO.puts("Testing file: #{filename}")
    
    file_path = "test/fixtures/mibs/working/#{filename}"
    case File.read(file_path) do
      {:ok, content} ->
        case SnmpLib.MIB.Parser.parse(content) do
          {:ok, result} ->
            IO.puts("  Parse successful!")
          {:error, reason} ->
            IO.puts("  Parse error:")
            IO.puts("    Raw error: #{inspect(reason)}")
            IO.puts("    Error type: #{inspect(reason.__struct__ || :tuple)}")
            case reason do
              {line, module, message} ->
                IO.puts("    Line: #{line}")
                IO.puts("    Module: #{module}")
                IO.puts("    Message: #{inspect(message)}")
                IO.puts("    Message type: #{inspect(message.__struct__ || elem(message, 0) || :other)}")
              _ ->
                IO.puts("    Not a line/module/message tuple")
            end
        end
        
      {:error, reason} ->
        IO.puts("  File read failed: #{inspect(reason)}")
    end
    
    IO.puts("")
  end
  
  def run do
    IO.puts("=== Single File Test ===")
    test_file("IANAifType-MIB.mib")
    test_file("DISMAN-SCHEDULE-MIB.mib") 
    test_file("IANA-ADDRESS-FAMILY-NUMBERS-MIB.mib")
  end
end

SingleFileTest.run()