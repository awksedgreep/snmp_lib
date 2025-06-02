# Debug DOCSIS SIZE constraint issue
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")
Code.require_file("lib/snmp_lib/mib/ast.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Parser, Lexer}

# Simple test case with SIZE constraint
simple_size_test = """
TEST-MIB DEFINITIONS ::= BEGIN

testObject OBJECT-TYPE
    SYNTAX       OCTET STRING (SIZE (0 | 36..260))
    MAX-ACCESS   read-only
    STATUS       current
    DESCRIPTION  "Test object"
    ::= { 1 2 3 }

END
"""

IO.puts "Testing simple SIZE constraint parsing..."

case Lexer.tokenize(simple_size_test) do
  {:ok, tokens} ->
    IO.puts "✅ Tokenization successful: #{length(tokens)} tokens"
    
    # Show tokens around OCTET STRING
    octet_index = Enum.find_index(tokens, fn {type, value, _} -> 
      type == :keyword and value == :octet 
    end)
    
    if octet_index do
      relevant_tokens = Enum.slice(tokens, (octet_index - 2)..(octet_index + 15))
      IO.puts "\n🔍 Tokens around OCTET STRING:"
      Enum.each(relevant_tokens, fn {type, value, pos} ->
        IO.puts "  #{type}: #{value} (line #{pos[:line]})"
      end)
    end
    
    case Parser.parse_tokens(tokens) do
      {:ok, mib} ->
        IO.puts "✅ Parsing successful!"
        IO.puts "   MIB: #{mib.name}"
        IO.puts "   Definitions: #{length(mib.definitions)}"
        
      {:warning, mib, warnings} ->
        IO.puts "⚠️  Parsing with warnings"
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