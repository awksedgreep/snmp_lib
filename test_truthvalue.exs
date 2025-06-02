# Test TruthValue syntax recognition
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")
Code.require_file("lib/snmp_lib/mib/ast.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Parser, Lexer}

# Test cases that might cause TruthValue issues
test_cases = [
  # Basic TruthValue in OBJECT-TYPE
  """
  TEST-MIB DEFINITIONS ::= BEGIN
  testObj OBJECT-TYPE
      SYNTAX      TruthValue
      MAX-ACCESS  read-write
      STATUS      current
      DESCRIPTION "Test object"
      ::= { iso 1 }
  END
  """,
  
  # TruthValue in SEQUENCE
  """
  TEST-MIB DEFINITIONS ::= BEGIN
  TestEntry ::= SEQUENCE {
      testFlag    TruthValue
  }
  END
  """,
  
  # TruthValue as TEXTUAL-CONVENTION syntax
  """
  TEST-MIB DEFINITIONS ::= BEGIN
  MyTruthValue ::= TEXTUAL-CONVENTION
      STATUS current
      DESCRIPTION "Test"
      SYNTAX TruthValue
  END
  """
]

Enum.with_index(test_cases, 1)
|> Enum.each(fn {test_mib, index} ->
  IO.puts "Test Case #{index}:"
  IO.puts "=================="
  
  case Lexer.tokenize(test_mib) do
    {:ok, tokens} ->
      # Find TruthValue token
      truth_value_tokens = Enum.filter(tokens, fn
        {:keyword, :truth_value, _} -> true
        {:identifier, "TruthValue", _} -> true
        _ -> false
      end)
      
      IO.puts "✅ Tokenization successful: #{length(tokens)} tokens"
      IO.puts "   TruthValue tokens found: #{length(truth_value_tokens)}"
      
      Enum.each(truth_value_tokens, fn token ->
        IO.puts "   Token: #{inspect(token)}"
      end)
      
      case Parser.parse_tokens(tokens) do
        {:ok, mib} ->
          IO.puts "✅ Parsing successful!"
          IO.puts "   MIB: #{mib.name}"
          
        {:warning, mib, warnings} ->
          IO.puts "⚠️  Parsing with warnings"
          IO.puts "   Warnings: #{length(warnings)}"
          first_warning = List.first(warnings)
          IO.puts "   First warning: #{inspect(first_warning)}"
          
        {:error, errors} ->
          IO.puts "❌ Parsing failed: #{length(errors)} errors"
          first_error = List.first(errors)
          IO.puts "   Error: #{inspect(first_error)}"
          
          # Check if error is about TruthValue
          error_mentions_truth = first_error 
            |> inspect() 
            |> String.contains?("TruthValue")
          IO.puts "   Error mentions TruthValue: #{error_mentions_truth}"
      end
      
    {:error, error} ->
      IO.puts "❌ Tokenization failed"
      IO.puts "   Error: #{inspect(error)}"
  end
  
  IO.puts ""
end)