# Debug SEQUENCE type parsing
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")
Code.require_file("lib/snmp_lib/mib/ast.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Parser, Lexer}

# Test SEQUENCE type definition
sequence_test = """
TEST-MIB DEFINITIONS ::= BEGIN

DocsBpi2CmBaseEntry ::= SEQUENCE {
    docsBpi2CmPrivacyEnable     TruthValue,
    docsBpi2CmPublicKey         OCTET STRING,
    docsBpi2CmAuthState         INTEGER,
    docsBpi2CmAuthKeySequenceNumber  Integer32
}

END
"""

IO.puts "Testing SEQUENCE type definition..."

case Lexer.tokenize(sequence_test) do
  {:ok, tokens} ->
    IO.puts "✅ Tokenization successful: #{length(tokens)} tokens"
    
    case Parser.parse_tokens(tokens) do
      {:ok, mib} ->
        IO.puts "✅ Parsing successful!"
        IO.puts "   MIB: #{mib.name}"
        IO.puts "   Definitions: #{length(mib.definitions)}"
        
        sequence_def = List.first(mib.definitions)
        IO.puts "   Type: #{sequence_def.__type__}"
        IO.puts "   Name: #{sequence_def.name}"
        IO.puts "   Elements: #{length(sequence_def.elements)}"
        
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