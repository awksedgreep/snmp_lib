# Debug "Missing clause" error
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")
Code.require_file("lib/snmp_lib/mib/ast.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Parser, Lexer}

IO.puts "Debugging 'Missing clause' error in DOCS-CABLE-DEVICE-MIB..."

# Read the file
{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")

case Lexer.tokenize(content) do
  {:ok, tokens} ->
    IO.puts "✅ Tokenization successful: #{length(tokens)} tokens"
    
    case Parser.parse_tokens(tokens) do
      {:ok, mib} ->
        IO.puts "✅ Unexpected success! #{length(mib.definitions)} definitions"
        
      {:warning, mib, warnings} ->
        IO.puts "⚠️  Parsing with warnings: #{length(warnings)} warnings"
        
      {:error, errors} ->
        IO.puts "❌ Parsing failed: #{length(errors)} errors"
        first_error = List.first(errors)
        
        IO.puts "   First error: #{inspect(first_error)}"
        
        # The error format might contain more details
        if is_map(first_error) do
          IO.puts "   Error details:"
          Enum.each(first_error, fn {key, value} ->
            IO.puts "     #{key}: #{inspect(value)}"
          end)
        end
        
        # Try to get a stack trace or more details about the "Missing clause" error
        if is_tuple(first_error) do
          case first_error do
            {:missing_clause, details} ->
              IO.puts "   Missing clause details: #{inspect(details)}"
            {error_type, message} ->
              IO.puts "   Error type: #{error_type}"
              IO.puts "   Message: #{message}"
            _ ->
              IO.puts "   Unknown error format: #{inspect(first_error)}"
          end
        end
    end
    
  {:error, error} ->
    IO.puts "❌ Tokenization failed"
    IO.puts "   Error: #{inspect(error)}"
end