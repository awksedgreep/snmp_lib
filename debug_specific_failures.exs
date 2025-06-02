#!/usr/bin/env elixir

# Add the lib directory to the code path
Code.require_file("lib/snmp_lib.ex")

# Test specific failing files
failing_files = [
  "test/fixtures/mibs/working/IANAifType-MIB.mib",     # Large numbers
  "test/fixtures/mibs/working/RFC-1215.mib",           # TYPE notation 
  "test/fixtures/mibs/working/SNMPv2-SMI.mib",         # MACRO definitions
  "test/fixtures/mibs/working/SNMPv2-TC.mib",          # MACRO definitions
  "test/fixtures/mibs/working/SNMPv2-CONF.mib"         # MACRO definitions
]

IO.puts("Testing specific failing MIB files:")
IO.puts("=" <> String.duplicate("=", 50))

for file <- failing_files do
  IO.puts("\n--- Testing #{file} ---")
  
  case File.read(file) do
    {:ok, content} ->
      case SnmpLib.MIB.Compiler.compile_string(content) do
        {:ok, _ast} ->
          IO.puts("✓ SUCCESS: File compiled successfully")
          
        {:error, reason} ->
          IO.puts("✗ ERROR: #{inspect(reason)}")
          
          # Try to get more detailed error info
          case SnmpLib.MIB.Lexer.tokenize(content) do
            {:ok, tokens} ->
              IO.puts("  Lexer: ✓ Tokenization successful (#{length(tokens)} tokens)")
              
              case SnmpLib.MIB.Parser.parse(tokens) do
                {:ok, _ast} ->
                  IO.puts("  Parser: ✓ Parsing successful")
                  
                {:error, parse_error} ->
                  IO.puts("  Parser: ✗ #{inspect(parse_error)}")
              end
              
            {:error, lex_error} ->
              IO.puts("  Lexer: ✗ #{inspect(lex_error)}")
          end
      end
      
    {:error, file_error} ->
      IO.puts("✗ FILE ERROR: #{inspect(file_error)}")
  end
end

IO.puts("\n" <> String.duplicate("=", 60))