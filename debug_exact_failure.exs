# Debug exact content that causes the failure
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")
Code.require_file("lib/snmp_lib/mib/ast.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Parser, Lexer}

# Get the exact failing content from the DOCS-CABLE-DEVICE-MIB
{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
lines = String.split(content, "\n")

# Test exactly 205 lines (which should work) vs 210 lines (which fails)
working_content = (Enum.take(lines, 205) |> Enum.join("\n")) <> "\nEND"
failing_content = (Enum.take(lines, 210) |> Enum.join("\n")) <> "\nEND"

IO.puts "=== Testing 205 lines (should work) ==="
case Lexer.tokenize(working_content) do
  {:ok, tokens} ->
    case Parser.parse_tokens(tokens) do
      {:ok, mib} ->
        IO.puts "✅ 205 lines: SUCCESS - #{length(mib.definitions)} definitions"
      {:error, errors} ->
        IO.puts "❌ 205 lines: FAILED - #{List.first(errors) |> SnmpLib.MIB.Error.format()}"
    end
  {:error, error} ->
    IO.puts "❌ 205 lines: TOKENIZATION FAILED"
end

IO.puts "\n=== Testing 210 lines (should fail) ==="
case Lexer.tokenize(failing_content) do
  {:ok, tokens} ->
    case Parser.parse_tokens(tokens) do
      {:ok, mib} ->
        IO.puts "✅ 210 lines: SUCCESS - #{length(mib.definitions)} definitions"
      {:error, errors} ->
        IO.puts "❌ 210 lines: FAILED - #{List.first(errors) |> SnmpLib.MIB.Error.format()}"
        
        # Show lines 205-210 to see what's different
        IO.puts "\n   Lines 205-210:"
        for i <- 204..209 do
          line = Enum.at(lines, i)
          IO.puts "   #{i+1}: #{line}"
        end
    end
  {:error, error} ->
    IO.puts "❌ 210 lines: TOKENIZATION FAILED"
end