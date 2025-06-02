# Test TruthValue with imports and without imports
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")
Code.require_file("lib/snmp_lib/mib/ast.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Parser, Lexer}

# Test case: TruthValue used without importing it from SNMPv2-TC
test_mib = """
TEST-MIB DEFINITIONS ::= BEGIN

-- Note: No IMPORTS section

testObj OBJECT-TYPE
    SYNTAX      TruthValue  -- This might fail if TruthValue requires import
    MAX-ACCESS  read-write
    STATUS      current
    DESCRIPTION "Test object using TruthValue without import"
    ::= { iso 1 }

END
"""

IO.puts "Testing TruthValue without explicit import:"
IO.puts "============================================="

case Lexer.tokenize(test_mib) do
  {:ok, tokens} ->
    IO.puts "✅ Tokenization successful: #{length(tokens)} tokens"
    
    # Find TruthValue token
    truth_value_tokens = Enum.filter(tokens, fn
      {:keyword, :truth_value, _} -> true
      {:identifier, "TruthValue", _} -> true
      _ -> false
    end)
    
    IO.puts "   TruthValue tokens found: #{length(truth_value_tokens)}"
    
    Enum.each(truth_value_tokens, fn token ->
      IO.puts "   Token: #{inspect(token)}"
    end)
    
    case Parser.parse_tokens(tokens) do
      {:ok, mib} ->
        IO.puts "✅ Parsing successful!"
        IO.puts "   MIB: #{mib.name}"
        IO.puts "   Definitions: #{length(mib.definitions)}"
        
        # Check if the object type was parsed correctly
        if length(mib.definitions) > 0 do
          obj = List.first(mib.definitions)
          IO.puts "   Object type: #{obj.__type__}"
          IO.puts "   Object name: #{obj.name}"
          if Map.has_key?(obj, :syntax) do
            IO.puts "   Object syntax: #{inspect(obj.syntax)}"
          end
        end
        
      {:warning, mib, warnings} ->
        IO.puts "⚠️  Parsing with warnings"
        IO.puts "   Warnings: #{length(warnings)}"
        
        Enum.with_index(warnings, 1) |> Enum.each(fn {warning, idx} ->
          IO.puts "   Warning #{idx}: #{inspect(warning)}"
        end)
        
        IO.puts "   MIB: #{mib.name}"
        
      {:error, errors} ->
        IO.puts "❌ Parsing failed: #{length(errors)} errors"
        
        Enum.with_index(errors, 1) |> Enum.each(fn {error, idx} ->
          IO.puts "   Error #{idx}: #{inspect(error)}"
          
          # Check if error is about TruthValue
          error_mentions_truth = error 
            |> inspect() 
            |> String.contains?("TruthValue")
          if error_mentions_truth do
            IO.puts "   --> This error mentions TruthValue!"
          end
        end)
    end
    
  {:error, error} ->
    IO.puts "❌ Tokenization failed"
    IO.puts "   Error: #{inspect(error)}"
end

IO.puts ""
IO.puts "Testing with proper import:"
IO.puts "============================"

test_mib_with_import = """
TEST-MIB DEFINITIONS ::= BEGIN

IMPORTS
    TruthValue FROM SNMPv2-TC;

testObj OBJECT-TYPE
    SYNTAX      TruthValue
    MAX-ACCESS  read-write
    STATUS      current
    DESCRIPTION "Test object using TruthValue with proper import"
    ::= { iso 1 }

END
"""

case Lexer.tokenize(test_mib_with_import) do
  {:ok, tokens} ->
    IO.puts "✅ Tokenization successful: #{length(tokens)} tokens"
    
    case Parser.parse_tokens(tokens) do
      {:ok, mib} ->
        IO.puts "✅ Parsing successful!"
        IO.puts "   MIB: #{mib.name}"
        IO.puts "   Imports: #{length(mib.imports)}"
        
        if length(mib.imports) > 0 do
          import_info = List.first(mib.imports)
          IO.puts "   First import: #{inspect(import_info)}"
        end
        
      {:warning, mib, warnings} ->
        IO.puts "⚠️  Parsing with warnings"
        IO.puts "   Warnings: #{length(warnings)}"
        
      {:error, errors} ->
        IO.puts "❌ Parsing failed: #{length(errors)} errors"
        
        Enum.with_index(errors, 1) |> Enum.each(fn {error, idx} ->
          IO.puts "   Error #{idx}: #{inspect(error)}"
        end)
    end
    
  {:error, error} ->
    IO.puts "❌ Tokenization failed"
    IO.puts "   Error: #{inspect(error)}"
end