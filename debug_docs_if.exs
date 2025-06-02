# Debug DOCS-IF-MIB specific issue
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")
Code.require_file("lib/snmp_lib/mib/ast.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Parser, Lexer}

IO.puts "Debugging DOCS-IF-MIB issue..."

# Read the file
{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-IF-MIB")

case Lexer.tokenize(content) do
  {:ok, tokens} ->
    IO.puts "✅ Tokenization successful: #{length(tokens)} tokens"
    
    case Parser.parse_tokens(tokens) do
      {:ok, mib} ->
        IO.puts "✅ Unexpected success! #{length(mib.definitions)} definitions"
        
      {:warning, mib, warnings} ->
        IO.puts "⚠️  Parsing with warnings: #{length(warnings)} warnings"
        
      {:error, errors} ->
        IO.puts "❌ Expected error: #{length(errors)} errors"
        first_error = List.first(errors)
        IO.puts "   Error: #{first_error.type} - #{first_error.message}"
        if first_error.line do
          IO.puts "   Error line: #{first_error.line}"
        end
        
        # Let's look at the content around line 147
        if first_error.line do
          lines = String.split(content, "\n")
          error_line = first_error.line
          
          IO.puts "\n   Content around line #{error_line}:"
          for i <- max(1, error_line-5)..min(length(lines), error_line+5) do
            line_content = Enum.at(lines, i-1) || ""
            marker = if i == error_line, do: " <-- ERROR", else: ""
            IO.puts "     #{i}: #{line_content}#{marker}"
          end
          
          # Also let's look at the tokens around that line
          IO.puts "\n   Tokens around line #{error_line}:"
          line_tokens = Enum.with_index(tokens) |> Enum.filter(fn {{_type, _value, pos}, _idx} ->
            pos && Map.has_key?(pos, :line) && pos.line >= error_line - 2 && pos.line <= error_line + 2
          end)
          
          Enum.each(line_tokens, fn {{type, value, pos}, idx} ->
            marker = if pos.line == error_line, do: " <-- ERROR LINE", else: ""
            IO.puts "     #{idx}: #{type} = #{inspect(value)} (line #{pos.line})#{marker}"
          end)
        end
    end
    
  {:error, error} ->
    IO.puts "❌ Tokenization failed"
    IO.puts "   Error: #{inspect(error)}"
end