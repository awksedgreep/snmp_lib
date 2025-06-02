# Debug specific range where Missing clause occurs (200-250)
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")
Code.require_file("lib/snmp_lib/mib/ast.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Parser, Lexer}

# Test the exact range where the issue occurs
{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
lines = String.split(content, "\n")

# Test smaller increments between 200-250
test_ranges = [200, 210, 220, 225, 230, 235, 240, 245, 250]

IO.puts "Narrowing down the 'Missing clause' issue between lines 200-250..."

Enum.each(test_ranges, fn line_count ->
  test_lines = Enum.take(lines, line_count)
  test_content = Enum.join(test_lines, "\n") <> "\nEND"
  
  case Lexer.tokenize(test_content) do
    {:ok, tokens} ->
      case Parser.parse_tokens(tokens) do
        {:ok, mib} ->
          IO.puts "✅ Lines 1-#{line_count}: SUCCESS - #{length(mib.definitions)} definitions"
          
        {:warning, mib, warnings} ->
          IO.puts "⚠️  Lines 1-#{line_count}: WARNING - #{length(warnings)} warnings"
          
        {:error, errors} ->
          IO.puts "❌ Lines 1-#{line_count}: PARSING FAILED"
          first_error = List.first(errors)
          error_msg = SnmpLib.MIB.Error.format(first_error)
          IO.puts "   Error: #{error_msg}"
          
          # Show the content around the problematic line
          IO.puts "   Lines #{line_count-5} to #{line_count}:"
          for i <- max(0, line_count-5)..min(length(lines)-1, line_count-1) do
            line = Enum.at(lines, i)
            IO.puts "   #{i+1}: #{line}"
          end
          
          # Stop here since we found where it breaks
          System.halt(0)
      end
      
    {:error, error} ->
      IO.puts "❌ Lines 1-#{line_count}: TOKENIZATION FAILED"
      error_msg = SnmpLib.MIB.Error.format(error)
      IO.puts "   Error: #{error_msg}"
      System.halt(0)
  end
end)

IO.puts "All narrow range tests passed"