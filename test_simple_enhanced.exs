#!/usr/bin/env elixir

defmodule TestSimpleEnhanced do
  def run do
    IO.puts("🧪 Testing enhanced 1:1 parser...")
    
    # First check if our modules are available
    IO.puts("📦 Checking module availability...")
    
    try do
      Code.ensure_loaded(SnmpLib.MIB.ActualParser)
      IO.puts("✅ SnmpLib.MIB.ActualParser loaded")
    rescue
      e -> IO.puts("❌ SnmpLib.MIB.ActualParser not available: #{inspect(e)}")
    end
    
    try do
      Code.ensure_loaded(SnmpLib.MIB.SnmpTokenizer)
      IO.puts("✅ SnmpLib.MIB.SnmpTokenizer loaded")
    rescue
      e -> IO.puts("❌ SnmpLib.MIB.SnmpTokenizer not available: #{inspect(e)}")
    end
    
    # Test simple tokenization first
    simple_content = "TEST-MIB DEFINITIONS ::= BEGIN current END"
    
    IO.puts("\n🔧 Testing tokenization...")
    
    case SnmpLib.MIB.SnmpTokenizer.tokenize(to_charlist(simple_content), &SnmpLib.MIB.SnmpTokenizer.null_get_line/0) do
      {:ok, tokens} ->
        IO.puts("✅ Tokenization successful")
        IO.puts("📋 Tokens:")
        Enum.each(tokens, fn token ->
          IO.puts("   #{inspect(token)}")
        end)
        
        # Now test if the parser module is available
        IO.puts("\n🔧 Testing parser initialization...")
        
        case SnmpLib.MIB.ActualParser.init_parser() do
          {:ok, parser_module} ->
            IO.puts("✅ Parser initialized: #{parser_module}")
            
            # Test parsing
            IO.puts("\n🔧 Testing parsing...")
            
            try do
              case apply(parser_module, :parse, [tokens]) do
                {:ok, parse_tree} ->
                  IO.puts("✅ Parsing successful")
                  IO.puts("🌳 Parse tree: #{inspect(parse_tree)}")
                  
                {:error, reason} ->
                  IO.puts("❌ Parsing failed: #{inspect(reason)}")
              end
            rescue
              e -> IO.puts("❌ Parser exception: #{inspect(e)}")
            end
            
          {:error, reason} ->
            IO.puts("❌ Parser initialization failed: #{inspect(reason)}")
        end
        
      {:error, reason} ->
        IO.puts("❌ Tokenization failed: #{inspect(reason)}")
    end
  end
end

TestSimpleEnhanced.run()