#!/usr/bin/env elixir

# Test compiling and running the enhanced parser
defmodule TestCompile do
  def run do
    IO.puts("🧪 Testing enhanced 1:1 parser compilation...")
    
    # Try to load the module
    case Code.ensure_loaded(SnmpLib.MIB.ActualParser) do
      {:module, _} ->
        IO.puts("✅ SnmpLib.MIB.ActualParser loaded successfully")
        test_parser()
      {:error, reason} ->
        IO.puts("❌ Failed to load SnmpLib.MIB.ActualParser: #{inspect(reason)}")
    end
  end
  
  defp test_parser do
    IO.puts("🔧 Testing grammar compilation...")
    
    case SnmpLib.MIB.ActualParser.init_parser() do
      {:ok, parser_module} ->
        IO.puts("✅ Grammar compiled successfully: #{parser_module}")
        test_simple_mib()
      {:error, reason} ->
        IO.puts("❌ Grammar compilation failed: #{inspect(reason)}")
    end
  end
  
  defp test_simple_mib do
    IO.puts("🧪 Testing simple MIB parsing...")
    
    simple_mib = """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    test OBJECT IDENTIFIER ::= { iso 1 }
    
    END
    """
    
    case SnmpLib.MIB.ActualParser.parse(simple_mib) do
      {:ok, result} ->
        IO.puts("✅ Simple MIB parsed successfully")
        IO.inspect(result, label: "Parse result")
      {:error, reason} ->
        IO.puts("❌ Simple MIB parsing failed: #{inspect(reason)}")
    end
  end
end

TestCompile.run()