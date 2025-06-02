# Debug by testing specific line ranges to narrow down the issue
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")
Code.require_file("lib/snmp_lib/mib/ast.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Parser, Lexer}

IO.puts "Testing specific line ranges to isolate the issue..."

{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
lines = String.split(content, "\n")

# Test a range from 245 to 260 to narrow down the exact breaking point
Enum.find(245..265, fn end_line ->
  test_content = (Enum.take(lines, end_line) |> Enum.join("\n")) <> "\nEND"
  
  case Lexer.tokenize(test_content) do
    {:ok, tokens} ->
      case Parser.parse_tokens(tokens) do
        {:ok, mib} ->
          IO.puts "✅ Lines 1-#{end_line}: SUCCESS - #{length(mib.definitions)} definitions"
          false # Continue testing
        {:warning, mib, warnings} ->
          IO.puts "⚠️  Lines 1-#{end_line}: SUCCESS with warnings - #{length(mib.definitions)} definitions, #{length(warnings)} warnings"
          false # Continue testing
        {:error, errors} ->
          first_error = List.first(errors)
          IO.puts "❌ Lines 1-#{end_line}: FAILED - #{first_error.type}: #{first_error.message}"
          
          # Show the content around this line to see what caused the break
          IO.puts "   Breaking point found! Lines #{end_line-5} to #{end_line}:"
          for i <- (end_line-5)..(end_line-1) do
            line = Enum.at(lines, i)
            if line do
              IO.puts "     #{i+1}: #{line}"
            end
          end
          
          true # Found the failure, stop
      end
    {:error, _error} ->
      IO.puts "❌ Lines 1-#{end_line}: TOKENIZATION FAILED"
      false # Continue testing
  end
end)