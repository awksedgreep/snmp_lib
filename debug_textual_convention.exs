# Debug TEXTUAL-CONVENTION parsing issue
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")
Code.require_file("lib/snmp_lib/mib/ast.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Parser, Lexer}

# Test TEXTUAL-CONVENTION definition that's failing
test_content = """
TEST-MIB DEFINITIONS ::= BEGIN

DocsisUpstreamType ::= TEXTUAL-CONVENTION
    STATUS          current
    DESCRIPTION
         "Indicates the DOCSIS Upstream Channel Type.
          'unknown' means information not available."
    SYNTAX INTEGER {
        unknown(0),
        tdma(1),
        atdma(2),
        scdma(3)
    }

END
"""

IO.puts "Testing TEXTUAL-CONVENTION parsing..."

case Lexer.tokenize(test_content) do
  {:ok, tokens} ->
    IO.puts "✅ Tokenization successful: #{length(tokens)} tokens"
    
    # Find the TEXTUAL-CONVENTION part
    textual_conv_start = Enum.find_index(tokens, fn 
      {:keyword, :textual_convention, _} -> true
      _ -> false
    end)
    
    if textual_conv_start do
      IO.puts "\nTokens around TEXTUAL-CONVENTION:"
      relevant_tokens = Enum.slice(tokens, max(0, textual_conv_start - 3), 15)
      Enum.with_index(relevant_tokens, max(0, textual_conv_start - 3)) |> Enum.each(fn {{type, value, pos}, idx} ->
        line_info = if Map.has_key?(pos || %{}, :line), do: " (line #{pos.line})", else: ""
        marker = if idx == textual_conv_start, do: " <<<< TEXTUAL-CONVENTION", else: ""
        IO.puts "   #{idx}: #{type} = #{inspect(value)}#{line_info}#{marker}"
      end)
    end
    
    case Parser.parse_tokens(tokens) do
      {:ok, mib} ->
        IO.puts "✅ Parsing successful!"
        IO.puts "   MIB: #{mib.name}"
        IO.puts "   Definitions: #{length(mib.definitions)}"
        
        textual_conv = List.first(mib.definitions)
        IO.puts "   Textual Convention: #{textual_conv.name}"
        IO.puts "   Type: #{inspect(textual_conv)}"
        
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
        
        # Show tokens around the error position 
        if Map.has_key?(first_error, :line) do
          error_line = first_error.line
          IO.puts "\n   Looking for tokens around line #{error_line}..."
          
          # Find tokens with that line number
          line_tokens = Enum.with_index(tokens) |> Enum.filter(fn {{_type, _value, pos}, _idx} ->
            Map.has_key?(pos || %{}, :line) && pos.line == error_line
          end)
          
          if not Enum.empty?(line_tokens) do
            IO.puts "   Tokens on error line #{error_line}:"
            Enum.each(line_tokens, fn {{type, value, pos}, idx} ->
              IO.puts "     #{idx}: #{type} = #{inspect(value)} (line #{pos.line})"
            end)
          end
        end
    end
    
  {:error, error} ->
    IO.puts "❌ Tokenization failed"
    error_msg = SnmpLib.MIB.Error.format(error)
    IO.puts "   Error: #{error_msg}"
end