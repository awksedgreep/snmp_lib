# Debug INTEGER enumeration parsing specifically
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")
Code.require_file("lib/snmp_lib/mib/ast.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Parser, Lexer}

# Test just the INTEGER enumeration part that's failing
test_content = """
TEST-MIB DEFINITIONS ::= BEGIN

docsDevRole OBJECT-TYPE
        SYNTAX INTEGER {
            cm(1),
            cmtsActive(2),
            cmtsBackup(3)
        }
        MAX-ACCESS  read-only
        STATUS      current
        DESCRIPTION "Test"
        ::= { test 1 }

END
"""

IO.puts "Testing INTEGER enumeration parsing..."

case Lexer.tokenize(test_content) do
  {:ok, tokens} ->
    IO.puts "✅ Tokenization successful: #{length(tokens)} tokens"
    
    case Parser.parse_tokens(tokens) do
      {:ok, mib} ->
        IO.puts "✅ Parsing successful!"
        IO.puts "   MIB: #{mib.name}"
        IO.puts "   Definitions: #{length(mib.definitions)}"
        
        object_type = List.first(mib.definitions)
        IO.puts "   Object type: #{object_type.name}"
        IO.puts "   Syntax: #{inspect(object_type.syntax)}"
        
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
        
        # Show the error context
        if Map.has_key?(first_error, :line) do
          IO.puts "   Error line: #{first_error.line}"
        end
        
        # Let's also check specific token patterns 
        IO.puts "\n   Checking SYNTAX part specifically..."
        syntax_start = Enum.find_index(tokens, fn 
          {:keyword, :syntax, _} -> true
          _ -> false
        end)
        
        if syntax_start do
          syntax_tokens = Enum.slice(tokens, syntax_start, 20)
          Enum.with_index(syntax_tokens, syntax_start) |> Enum.each(fn {{type, value, pos}, idx} ->
            line_info = if Map.has_key?(pos || %{}, :line), do: " (line #{pos.line})", else: ""
            IO.puts "     #{idx}: #{type} = #{inspect(value)}#{line_info}"
          end)
        end
    end
    
  {:error, error} ->
    IO.puts "❌ Tokenization failed"
    error_msg = SnmpLib.MIB.Error.format(error)
    IO.puts "   Error: #{error_msg}"
end