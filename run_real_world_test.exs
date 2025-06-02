# Simple test runner for real-world MIB files
alias SnmpLib.MIB.{Parser, Lexer}

defmodule RealWorldTester do
  alias SnmpLib.MIB.{Parser, Lexer}
  
  def run do
    # Standard MIBs that our parser should be able to handle
    test_files = [
      # Core SNMPv2 MIBs - using simple test files first
      {"Simple MIB", "simple_test.mib"}
    ]

    IO.puts "\n=== Real-World MIB Parsing Tests ==="
    IO.puts "Testing parser compatibility with standard production MIBs\n"
    
    # Let's first create a simple test MIB to verify basic functionality
    simple_mib_content = """
    TEST-MIB DEFINITIONS ::= BEGIN
    IMPORTS DisplayString FROM SNMPv2-TC;
    
    testObject OBJECT-TYPE
        SYNTAX DisplayString
        MAX-ACCESS read-only
        STATUS current
        DESCRIPTION "A simple test object"
        ::= { iso org(3) dod(6) internet(1) mgmt(2) mib-2(1) system(1) 1 }
    END
    """
    
    IO.puts "Testing with simple MIB content..."
    
    case Lexer.tokenize(simple_mib_content) do
      {:ok, tokens} ->
        IO.puts "  ✅ TOKENIZATION SUCCESS: #{length(tokens)} tokens"
        
        case Parser.parse_tokens(tokens) do
          {:ok, mib} ->
            IO.puts "  ✅ PARSING SUCCESS: #{length(mib.definitions)} definitions"
            IO.puts "     Module: #{mib.name}"
            IO.puts "     Imports: #{length(mib.imports)} import groups"
            
            # Count different definition types
            type_counts = count_definition_types(mib.definitions)
            IO.puts "     Definition types:"
            Enum.each(type_counts, fn {type, count} ->
              IO.puts "       #{type}: #{count}"
            end)
            
            IO.puts "\n🎉 Basic parsing test PASSED!"
            
          {:error, errors} ->
            IO.puts "  ❌ PARSING FAILED: #{length(errors)} errors"
            Enum.take(errors, 3) |> Enum.each(fn error ->
              IO.puts "     #{SnmpLib.MIB.Error.format(error)}"
            end)
            
          {:warning, mib, warnings} ->
            IO.puts "  ⚠️  PARSED WITH WARNINGS: #{length(warnings)} warnings"
            Enum.take(warnings, 2) |> Enum.each(fn warning ->
              IO.puts "     #{SnmpLib.MIB.Error.format(warning)}"
            end)
            IO.puts "  ✅ Definitions parsed: #{length(mib.definitions)}"
        end
        
      {:error, error} ->
        IO.puts "  ❌ TOKENIZATION FAILED: #{SnmpLib.MIB.Error.format(error)}"
    end
  end
  
  defp count_definition_types(definitions) do
    definitions
    |> Enum.group_by(& &1.__type__)
    |> Enum.map(fn {type, list} -> {type, length(list)} end)
    |> Enum.sort_by(fn {_type, count} -> -count end)
  end
end

# Run the test
RealWorldTester.run()