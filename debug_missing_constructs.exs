# Debug missing MIB constructs
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")
Code.require_file("lib/snmp_lib/mib/ast.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Parser, Lexer}

# Test the patterns that are failing in DOCSIS MIBs
test_cases = [
  # Test 1: TEXTUAL-CONVENTION assignment 
  """
  TEST-MIB DEFINITIONS ::= BEGIN
  
  TenthdBmV ::= TEXTUAL-CONVENTION
       DISPLAY-HINT "d-1"
       STATUS       current
       DESCRIPTION  "Test description"
       SYNTAX       Integer32
  
  END
  """,
  
  # Test 2: OBJECT IDENTIFIER assignment
  """
  TEST-MIB DEFINITIONS ::= BEGIN
  
  docsIfMibObjects OBJECT IDENTIFIER ::= { transmission 127 }
  
  END
  """,
  
  # Test 3: MODULE-IDENTITY (should work)
  """
  TEST-MIB DEFINITIONS ::= BEGIN
  
  testMib MODULE-IDENTITY
      LAST-UPDATED "200101010000Z"
      ORGANIZATION "Test"
      CONTACT-INFO "Test"
      DESCRIPTION  "Test"
      ::= { 1 2 3 }
  
  END
  """
]

test_cases
|> Enum.with_index()
|> Enum.each(fn {test_case, index} ->
  IO.puts "\n" <> String.duplicate("=", 50)
  IO.puts "🧪 Test Case #{index + 1}"
  IO.puts String.duplicate("=", 50)
  
  case Lexer.tokenize(test_case) do
    {:ok, tokens} ->
      IO.puts "✅ Tokenization: #{length(tokens)} tokens"
      
      case Parser.parse_tokens(tokens) do
        {:ok, mib} ->
          IO.puts "✅ Parsing successful!"
          IO.puts "   MIB: #{mib.name}"
          IO.puts "   Definitions: #{length(mib.definitions)}"
          
        {:warning, mib, warnings} ->
          IO.puts "⚠️  Parsing with warnings"
          IO.puts "   MIB: #{mib.name}"
          IO.puts "   Warnings: #{length(warnings)}"
          first_warning = List.first(warnings)
          IO.puts "   First warning: #{SnmpLib.MIB.Error.format(first_warning)}"
          
        {:error, errors} ->
          IO.puts "❌ Parsing failed: #{length(errors)} errors"
          first_error = List.first(errors)
          error_msg = SnmpLib.MIB.Error.format(first_error)
          IO.puts "   Error: #{error_msg}"
      end
      
    {:error, error} ->
      IO.puts "❌ Tokenization failed"
      error_msg = SnmpLib.MIB.Error.format(error)
      IO.puts "   Error: #{error_msg}"
  end
end)