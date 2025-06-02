#!/usr/bin/env elixir

IO.puts("🔍 DEBUGGING NUMERIC PARSING ISSUES")
IO.puts("====================================")

# The 4 files with numeric parsing problems
problem_files = [
  "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/IANA-ADDRESS-FAMILY-NUMBERS-MIB.mib",
  "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/IANAifType-MIB.mib", 
  "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/RFC1213-MIB.mib",
  "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/DISMAN-SCHEDULE-MIB.mib"
]

Enum.each(problem_files, fn file_path ->
  filename = Path.basename(file_path)
  IO.puts("\n📄 Testing #{filename}")
  IO.puts(String.duplicate("-", 50))
  
  case File.read(file_path) do
    {:ok, content} ->
      case SnmpLib.MIB.ActualParser.parse(content) do
        {:ok, _result} ->
          IO.puts("✅ SUCCESS - This file is now working!")
        {:error, {line, :mib_grammar_elixir, error_info}} ->
          IO.puts("❌ ERROR at line #{line}: #{inspect(error_info)}")
          
          # Get the context around the error line
          lines = String.split(content, "\n")
          if line > 0 and line <= length(lines) do
            start_line = max(1, line - 2)
            end_line = min(length(lines), line + 2)
            
            IO.puts("\n📍 Context around line #{line}:")
            Enum.each(start_line..end_line, fn i ->
              line_content = Enum.at(lines, i - 1, "")
              marker = if i == line, do: ">>> ", else: "    "
              IO.puts("#{marker}#{i}: #{line_content}")
            end)
          end
        {:error, other} ->
          IO.puts("❌ ERROR: #{inspect(other)}")
      end
    {:error, reason} ->
      IO.puts("❌ File read error: #{inspect(reason)}")
  end
end)

IO.puts("\n\n🎯 NEXT STEPS")
IO.puts(String.duplicate("=", 30))
IO.puts("1. Examine the specific error contexts")
IO.puts("2. Identify the numeric patterns causing issues")
IO.puts("3. Fix tokenizer or grammar handling")
IO.puts("4. Verify fixes push success rate to 92%")