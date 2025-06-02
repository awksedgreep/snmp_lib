# Debug DOCS-CABLE-DEVICE-MIB by testing incremental portions
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Lexer}

# Read the full file
{:ok, full_content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
lines = String.split(full_content, "\n")

IO.puts "Testing DOCS-CABLE-DEVICE-MIB incrementally to find the issue..."
IO.puts "Total lines: #{length(lines)}"

# Test incremental portions to find where it breaks
test_sizes = [50, 100, 150, 200, 250, 300, 350, 400]

Enum.each(test_sizes, fn size ->
  if size <= length(lines) do
    test_lines = Enum.take(lines, size)
    test_content = Enum.join(test_lines, "\n") <> "\nEND"
    
    case Lexer.tokenize(test_content) do
      {:ok, tokens} ->
        IO.puts "✅ Lines 1-#{size}: SUCCESS (#{length(tokens)} tokens)"
        
      {:error, error} ->
        IO.puts "❌ Lines 1-#{size}: FAILED"
        error_msg = SnmpLib.MIB.Error.format(error)
        IO.puts "   Error: #{error_msg}"
        
        # Show the problematic line
        if Map.has_key?(error, :line) do
          failing_line_num = error.line
          if failing_line_num <= length(test_lines) do
            failing_line = Enum.at(test_lines, failing_line_num - 1)
            IO.puts "   Failing line #{failing_line_num}: '#{failing_line}'"
          end
        end
        
        # Stop here since we found the issue
        System.halt(0)
    end
  end
end)

IO.puts "All incremental tests passed - the issue might be at the very end of the file"