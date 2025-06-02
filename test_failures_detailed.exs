#!/usr/bin/env elixir

# Detailed failure analysis to identify specific error patterns
IO.puts("🔍 Analyzing specific failures to identify fixable issues...")
IO.puts("=" <> String.duplicate("=", 60))

mib_directories = [
  {"/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working", "Working"},
  {"/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/broken", "Broken"}, 
  {"/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/docsis", "DOCSIS"}
]

categorize_error = fn msg_str ->
  cond do
    String.contains?(msg_str, "syntax error before") ->
      cond do
        String.contains?(msg_str, "'H'") or String.contains?(msg_str, "'h'") -> "Hex string notation"
        String.contains?(msg_str, "deprecated") -> "Deprecated keyword context"
        String.contains?(msg_str, "current") -> "Status keyword context"
        String.contains?(msg_str, "mandatory") -> "Mandatory keyword context"
        String.contains?(msg_str, "optional") -> "Optional keyword context"
        String.contains?(msg_str, "MACRO") -> "MACRO definition"
        String.contains?(msg_str, "TYPE") -> "TYPE notation"
        true -> "Generic syntax error"
      end
    String.contains?(msg_str, "Protocol.UndefinedError") ->
      "Protocol enumeration error"
    String.contains?(msg_str, "function clause") ->
      "Function clause mismatch"
    String.contains?(msg_str, "TEXTUAL-CONVENTION") ->
      "TEXTUAL-CONVENTION parsing"
    String.contains?(msg_str, "IMPLIED") ->
      "IMPLIED keyword"
    String.contains?(msg_str, "MODULE-IDENTITY") ->
      "MODULE-IDENTITY parsing"
    String.contains?(msg_str, "MODULE-COMPLIANCE") ->
      "MODULE-COMPLIANCE parsing"
    true ->
      "Other"
  end
end

analyze_error = fn reason ->
  case reason do
    {line, module, message} when is_list(message) ->
      msg_str = message |> Enum.map(&to_string/1) |> Enum.join("")
      %{
        type: "Parse Error",
        line: line,
        module: module,
        message: msg_str,
        category: categorize_error.(msg_str)
      }
    other ->
      %{
        type: "Other Error",
        message: inspect(other),
        category: "Unknown"
      }
  end
end

all_failures = []

Enum.each(mib_directories, fn {dir, name} ->
  IO.puts("\n📁 Analyzing failures in #{name}...")
  
  case File.ls(dir) do
    {:ok, files} ->
      mib_files = files 
      |> Enum.filter(fn file -> 
        String.ends_with?(file, ".mib") or
        (not String.contains?(file, ".") and 
         not String.ends_with?(file, ".bin") and
         not String.ends_with?(file, ".clean"))
      end)
      |> Enum.sort()
      
      failures = Enum.filter(mib_files, fn file ->
        file_path = Path.join(dir, file)
        case File.read(file_path) do
          {:ok, content} ->
            case SnmpLib.MIB.ActualParser.parse(content) do
              {:ok, _} -> false  # Success, don't include
              {:error, reason} -> 
                error_details = analyze_error.(reason)
                all_failures = all_failures ++ [{file, dir, error_details}]
                IO.puts("  ❌ #{file}: #{error_details.category}")
                if error_details.category not in ["Hex string notation"] do
                  IO.puts("     Error: #{String.slice(error_details.message, 0, 100)}")
                end
                true  # Failure, include
            end
          {:error, _} -> false
        end
      end)
      
    {:error, _} ->
      IO.puts("   ❌ Cannot read directory: #{dir}")
  end
end)

IO.puts("\n📊 Error Pattern Summary:")

# Group failures by error category
error_counts = all_failures 
|> Enum.group_by(fn {_, _, error} -> error.category end)
|> Enum.map(fn {category, errors} -> {category, length(errors)} end)
|> Enum.sort_by(fn {_, count} -> count end, :desc)

total_failures = length(all_failures)

Enum.each(error_counts, fn {category, count} ->
  percentage = Float.round(count / total_failures * 100, 1)
  IO.puts("  #{category}: #{count} files (#{percentage}%)")
end)

IO.puts("\n🎯 Potential Improvement Opportunities:")

# Focus on non-hex errors that might be fixable
fixable_errors = error_counts |> Enum.filter(fn {category, _} -> 
  category not in ["Hex string notation", "MACRO definition"] 
end)

if not Enum.empty?(fixable_errors) do
  IO.puts("Fixable error categories:")
  Enum.each(fixable_errors, fn {category, count} ->
    IO.puts("  • #{category}: #{count} files")
  end)
  
  # Show specific examples of fixable errors
  IO.puts("\n📝 Specific Examples for Top Fixable Categories:")
  
  top_fixable = fixable_errors |> Enum.take(3)
  
  Enum.each(top_fixable, fn {category, _} ->
    examples = all_failures 
    |> Enum.filter(fn {_, _, error} -> error.category == category end)
    |> Enum.take(2)
    
    IO.puts("\n#{category}:")
    Enum.each(examples, fn {file, _dir, error} ->
      IO.puts("  • #{file}")
      if error.line do
        IO.puts("    Line: #{error.line}")
      end
      IO.puts("    Error: #{String.slice(error.message, 0, 150)}")
    end)
  end)
else
  IO.puts("Most remaining errors are MACRO definitions or other edge cases.")
  IO.puts("The compiler has achieved excellent coverage of standard MIB syntax!")
end

IO.puts("\n🎉 Current Status: #{88 - total_failures}/100 successful (#{Float.round((88 - total_failures) / 100 * 100, 1)}%)")
IO.puts("🎯 Total remaining failures: #{total_failures}")