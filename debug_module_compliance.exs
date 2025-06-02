# Debug MODULE-COMPLIANCE parsing with MODULE clauses
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")
Code.require_file("lib/snmp_lib/mib/ast.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Parser, Lexer}

# Test MODULE-COMPLIANCE with MODULE clauses
module_compliance_test = """
TEST-MIB DEFINITIONS ::= BEGIN

docsIfExtCmCompliance MODULE-COMPLIANCE
    STATUS      current
    DESCRIPTION "The compliance statement."
    
    MODULE
        MANDATORY-GROUPS { docsIfDocsisVersionGroup }
        
    ::= { docsIfExtCompliances 1 }

END
"""

IO.puts "Testing MODULE-COMPLIANCE with MODULE clauses..."

case Lexer.tokenize(module_compliance_test) do
  {:ok, tokens} ->
    IO.puts "✅ Tokenization successful: #{length(tokens)} tokens"
    
    case Parser.parse_tokens(tokens) do
      {:ok, mib} ->
        IO.puts "✅ Parsing successful!"
        IO.puts "   MIB: #{mib.name}"
        IO.puts "   Definitions: #{length(mib.definitions)}"
        
        compliance = List.first(mib.definitions)
        IO.puts "   Type: #{compliance.__type__}"
        IO.puts "   Name: #{compliance.name}"
        IO.puts "   Module clauses: #{length(compliance.module_clauses)}"
        
      {:warning, mib, warnings} ->
        IO.puts "⚠️  Parsing with warnings"
        IO.puts "   Warnings: #{length(warnings)}"
        
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