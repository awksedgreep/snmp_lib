#!/usr/bin/env elixir

# Add lib to the code path manually
Code.prepend_paths(["lib"])
Code.require_file("lib/snmp_lib.ex")

# Let's analyze the specific failing MIB files
failing_files = [
  "test/fixtures/mibs/working/IANAifType-MIB.mib",     # Large numbers
  "test/fixtures/mibs/working/RFC-1215.mib",           # TYPE notation 
  "test/fixtures/mibs/working/SNMPv2-SMI.mib",         # MACRO definitions
  "test/fixtures/mibs/working/SNMPv2-TC.mib",          # MACRO definitions
  "test/fixtures/mibs/working/SNMPv2-CONF.mib",        # MACRO definitions
  "test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB",   # DOCSIS files (without extension)
  "test/fixtures/mibs/docsis/DOCS-QOS-MIB"            # DOCSIS files (without extension)
]

IO.puts("Analyzing MIB Failure Patterns")
IO.puts("=" <> String.duplicate("=", 50))

for file <- failing_files do
  IO.puts("\n--- Testing #{file} ---")
  
  file_path = if String.ends_with?(file, ".mib"), do: file, else: file
  
  case File.read(file_path) do
    {:ok, content} ->
      # Try lexer first
      case SnmpLib.MIB.Lexer.tokenize(content) do
        {:ok, tokens} ->
          IO.puts("  Lexer: ✓ Success (#{length(tokens)} tokens)")
          
          # Try parser next
          case SnmpLib.MIB.Parser.parse(tokens) do
            {:ok, _ast} ->
              IO.puts("  Parser: ✓ Success")
              
            {:error, error} ->
              IO.puts("  Parser: ✗ Error: #{inspect(error)}")
              
              # Show the first few tokens to understand structure
              IO.puts("  First 10 tokens:")
              tokens 
              |> Enum.take(10) 
              |> Enum.each(fn token -> IO.puts("    #{inspect(token)}") end)
          end
          
        {:error, error} ->
          IO.puts("  Lexer: ✗ Error: #{inspect(error)}")
          
          # Show first part of content
          first_lines = content 
                       |> String.split("\n") 
                       |> Enum.take(10)
                       |> Enum.join("\n")
          IO.puts("  First 10 lines:")
          IO.puts("    #{first_lines}")
      end
      
    {:error, file_error} ->
      IO.puts("✗ FILE ERROR: #{inspect(file_error)}")
  end
end

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("Specific Pattern Analysis")
IO.puts("=" <> String.duplicate("=", 60))

# Test specific problematic patterns from the error messages
test_patterns = [
  # Large number test
  {"Large number in enum", "ianaifTypes ::= { bridge (209) }"},
  
  # TYPE notation test  
  {"TYPE notation", "TYPE NOTATION ::= \"ENTERPRISE\" value"},
  
  # MACRO definition test
  {"MACRO definition", "TRAP-TYPE MACRO ::= BEGIN"},
  
  # OBJECT-TYPE without MAX-ACCESS
  {"Missing MAX-ACCESS", """
  someObject OBJECT-TYPE
      SYNTAX INTEGER
      STATUS current
      ::= { someGroup 1 }
  """}
]

for {name, pattern} <- test_patterns do
  IO.puts("\n--- Testing pattern: #{name} ---")
  
  case SnmpLib.MIB.Lexer.tokenize(pattern) do
    {:ok, tokens} ->
      IO.puts("  Lexer: ✓ Success")
      Enum.each(tokens, fn token -> IO.puts("    #{inspect(token)}") end)
      
      case SnmpLib.MIB.Parser.parse(tokens) do
        {:ok, _ast} ->
          IO.puts("  Parser: ✓ Success")
          
        {:error, error} ->
          IO.puts("  Parser: ✗ Error: #{inspect(error)}")
      end
      
    {:error, error} ->
      IO.puts("  Lexer: ✗ Error: #{inspect(error)}")
  end
end