# Debug FunctionClauseError with detailed stack trace
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")
Code.require_file("lib/snmp_lib/mib/ast.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Parser, Lexer}

IO.puts "Debugging FunctionClauseError in DOCS-CABLE-DEVICE-MIB..."

# Read the file
{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")

case Lexer.tokenize(content) do
  {:ok, tokens} ->
    IO.puts "✅ Tokenization successful: #{length(tokens)} tokens"
    
    try do
      case Parser.parse_tokens(tokens) do
        {:ok, mib} ->
          IO.puts "✅ Unexpected success! #{length(mib.definitions)} definitions"
          
        {:warning, mib, warnings} ->
          IO.puts "⚠️  Parsing with warnings: #{length(warnings)} warnings"
          
        {:error, errors} ->
          IO.puts "❌ Expected error: #{length(errors)} errors"
          first_error = List.first(errors)
          IO.puts "   Error: #{first_error.type} - #{first_error.message}"
      end
    rescue
      e in FunctionClauseError ->
        IO.puts "❌ Caught FunctionClauseError:"
        IO.puts "   Function: #{e.function}/#{e.arity}"
        IO.puts "   Module: #{e.module}"
        IO.puts "   Arguments: #{inspect(e.args, limit: 3)}"
        
        IO.puts "\nStack trace:"
        Process.info(self(), :current_stacktrace)
        |> elem(1)
        |> Enum.take(10)
        |> Enum.each(fn {module, function, arity, location} ->
          IO.puts "   #{module}.#{function}/#{arity} at #{inspect(location)}"
        end)
        
      e ->
        IO.puts "❌ Caught other error: #{inspect(e)}"
    end
    
  {:error, error} ->
    IO.puts "❌ Tokenization failed"
    IO.puts "   Error: #{inspect(error)}"
end