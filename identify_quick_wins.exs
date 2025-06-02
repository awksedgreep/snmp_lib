#!/usr/bin/env elixir

IO.puts("🔍 IDENTIFYING POTENTIAL QUICK WINS")
IO.puts("===================================")

# Let's look for patterns in the failures that might have simple fixes
# Focus on the "broken" directory first since those might be easier

IO.puts("\n📂 ANALYZING BROKEN DIRECTORY FAILURES")
IO.puts(String.duplicate("-", 40))

broken_dir = "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/broken"
case File.ls(broken_dir) do
  {:ok, files} ->
    mib_files = files |> Enum.filter(fn file -> 
      String.ends_with?(file, ".mib") or 
      (not String.contains?(file, ".") and not String.ends_with?(file, ".bin"))
    end)
    
    IO.puts("Total files in broken directory: #{length(mib_files)}")
    IO.puts("All should be failing (100% failure rate expected)")
    
    # Test each one to see what specific errors we get
    failures_by_type = Enum.reduce(mib_files, %{}, fn file, acc ->
      file_path = Path.join(broken_dir, file)
      case File.read(file_path) do
        {:ok, content} ->
          case SnmpLib.MIB.ActualParser.parse(content) do
            {:ok, _} -> 
              IO.puts("⚠️  #{file} - UNEXPECTEDLY WORKING!")
              Map.update(acc, :unexpected_success, [file], &[file | &1])
            {:error, {line, :mib_grammar_elixir, error_info}} ->
              error_type = classify_error(error_info)
              IO.puts("❌ #{file} - #{error_type}")
              Map.update(acc, error_type, [file], &[file | &1])
            {:error, other} ->
              IO.puts("❌ #{file} - Other: #{inspect(other)}")
              Map.update(acc, :other_error, [file], &[file | &1])
          end
        {:error, _} -> 
          IO.puts("📁 #{file} - File read error")
          Map.update(acc, :file_error, [file], &[file | &1])
      end
    end)
    
    IO.puts("\n📊 ERROR PATTERN SUMMARY:")
    Enum.each(failures_by_type, fn {error_type, files} ->
      IO.puts("#{error_type}: #{length(files)} files")
      if length(files) <= 3 do
        Enum.each(files, fn file -> IO.puts("  • #{file}") end)
      else
        Enum.take(files, 3) |> Enum.each(fn file -> IO.puts("  • #{file}") end)
        IO.puts("  • ... and #{length(files) - 3} more")
      end
    end)
    
  {:error, _} ->
    IO.puts("❌ Cannot read broken directory")
end

# Function to classify error types for pattern analysis
def classify_error(error_info) when is_list(error_info) do
  case error_info do
    [~c"syntax error before: ", ~c"'MODULE-IDENTITY'"] -> :macro_module_identity
    [~c"syntax error before: ", ~c"'TEXTUAL-CONVENTION'"] -> :macro_textual_convention
    [~c"syntax error before: ", ~c"'OBJECT-GROUP'"] -> :macro_object_group
    [~c"syntax error before: ", ~c"'TRAP-TYPE'"] -> :macro_trap_type
    [~c"syntax error before: ", ~c"'OBJECT-TYPE'"] -> :macro_object_type
    [~c"syntax error before: ", token] when is_list(token) ->
      case List.to_string(token) do
        <<digit, _::binary>> when digit >= ?0 and digit <= ?9 -> :numeric_issue
        _ -> :syntax_error
      end
    _ -> :other_syntax
  end
end

IO.puts("\n🎯 POTENTIAL IMPROVEMENT STRATEGY:")
IO.puts("1. Look for any unexpected successes in 'broken' directory")
IO.puts("2. Identify if any error patterns have simple fixes")
IO.puts("3. Focus on non-MACRO related issues first")
IO.puts("4. Consider if any working files can be moved to 'working' directory")