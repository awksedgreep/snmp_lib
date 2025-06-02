# Debug actual string from DOCS-CABLE-DEVICE-MIB
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Lexer}

# Extract the actual problematic content from DOCS-CABLE-DEVICE-MIB
{:ok, full_content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
lines = String.split(full_content, "\n")

# Get lines 92-195 which contains the problematic REVISION/DESCRIPTION
start_line = 92
end_line = 195
problem_lines = Enum.slice(lines, start_line - 1, end_line - start_line + 1)
problem_content = """
TEST-MIB DEFINITIONS ::= BEGIN

#{Enum.join(problem_lines, "\n")}

END
"""

IO.puts "Testing actual problematic content..."
IO.puts "Content length: #{String.length(problem_content)} characters"
IO.puts "Line count: #{length(String.split(problem_content, "\n"))}"

case Lexer.tokenize(problem_content) do
  {:ok, tokens} ->
    IO.puts "✅ Tokenization successful: #{length(tokens)} tokens"
    
  {:error, error} ->
    IO.puts "❌ Tokenization failed"
    error_msg = SnmpLib.MIB.Error.format(error)
    IO.puts "   Error: #{error_msg}"
    
    # Show the problematic line
    if Map.has_key?(error, :line) do
      failing_line_num = error.line
      content_lines = String.split(problem_content, "\n")
      if failing_line_num <= length(content_lines) do
        failing_line = Enum.at(content_lines, failing_line_num - 1)
        IO.puts "   Failing line #{failing_line_num}: '#{failing_line}'"
        
        # Show context around the failing line
        IO.puts "   Context:"
        for i <- max(0, failing_line_num - 3)..min(length(content_lines) - 1, failing_line_num + 1) do
          line = Enum.at(content_lines, i)
          marker = if i == failing_line_num - 1, do: ">>> ", else: "    "
          IO.puts "   #{marker}#{i + 1}: #{line}"
        end
      end
    end
end