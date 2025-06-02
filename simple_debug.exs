# Simple debug to find missing clause error
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")
Code.require_file("lib/snmp_lib/mib/ast.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Parser, Lexer}

# Read the file
{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")

case Lexer.tokenize(content) do
  {:ok, tokens} ->
    IO.puts "Tokenization successful: #{length(tokens)} tokens"
    
    case Parser.parse_tokens(tokens) do
      {:error, [error | _]} ->
        IO.puts "Error type: #{error.type}"
        IO.puts "Error message: #{error.message}"
        IO.puts "Error context: #{inspect(error.context)}"
        
        # Print line number if available
        if error.line do
          IO.puts "Line: #{error.line}"
        end
        
      other ->
        IO.puts "Unexpected result: #{inspect(other)}"
    end
    
  {:error, error} ->
    IO.puts "Tokenization failed: #{inspect(error)}"
end