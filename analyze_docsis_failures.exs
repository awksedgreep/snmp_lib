#!/usr/bin/env elixir

IO.puts("🔍 ANALYZING DOCSIS DIRECTORY FAILURES")
IO.puts("=====================================")

docsis_dir = "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/docsis"
{:ok, files} = File.ls(docsis_dir)

mib_files = files |> Enum.filter(fn file -> 
  String.ends_with?(file, ".mib") or 
  (not String.contains?(file, ".") and not String.ends_with?(file, ".bin"))
end)

IO.puts("Testing #{length(mib_files)} files in DOCSIS directory...")

failures = Enum.map(mib_files, fn file ->
  file_path = Path.join(docsis_dir, file)
  case File.read(file_path) do
    {:ok, content} ->
      case SnmpLib.MIB.ActualParser.parse(content) do
        {:ok, _} -> nil
        {:error, {line, :mib_grammar_elixir, error_info}} ->
          {file, line, error_info}
        {:error, other} ->
          {file, :unknown, other}
      end
    {:error, _} -> 
      {file, :file_error, :file_read_failed}
  end
end) |> Enum.filter(&(&1 != nil))

IO.puts("\n📊 RESULTS:")
IO.puts("Working files: #{length(mib_files) - length(failures)}/#{length(mib_files)} (#{Float.round((length(mib_files) - length(failures)) / length(mib_files) * 100, 1)}%)")
IO.puts("Failed files: #{length(failures)}")

if length(failures) > 0 do
  IO.puts("\n❌ FAILURE DETAILS:")
  Enum.each(failures, fn {file, line, error} ->
    IO.puts("  • #{file} (line #{line}): #{inspect(error)}")
  end)
  
  # Group by error pattern
  error_groups = Enum.group_by(failures, fn {_file, _line, error} ->
    case error do
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
      _ -> :other_error
    end
  end)
  
  IO.puts("\n🔍 ERROR PATTERN ANALYSIS:")
  Enum.each(error_groups, fn {error_type, group_failures} ->
    files = Enum.map(group_failures, fn {file, _line, _error} -> file end)
    IO.puts("#{error_type}: #{length(files)} files")
    Enum.each(files, fn file -> IO.puts("    • #{file}") end)
  end)
end