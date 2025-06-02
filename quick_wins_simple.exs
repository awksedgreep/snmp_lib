#!/usr/bin/env elixir

# Function to classify error types for pattern analysis
defmodule ErrorAnalyzer do
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
end

IO.puts("🔍 QUICK ANALYSIS OF BROKEN DIRECTORY")
IO.puts("=====================================")

broken_dir = "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/broken"
case File.ls(broken_dir) do
  {:ok, files} ->
    mib_files = files |> Enum.filter(fn file -> 
      String.ends_with?(file, ".mib") or 
      (not String.contains?(file, ".") and not String.ends_with?(file, ".bin"))
    end)
    
    IO.puts("Testing #{length(mib_files)} files in broken directory...")
    
    results = Enum.map(mib_files, fn file ->
      file_path = Path.join(broken_dir, file)
      case File.read(file_path) do
        {:ok, content} ->
          case SnmpLib.MIB.ActualParser.parse(content) do
            {:ok, _} -> 
              {file, :unexpected_success}
            {:error, {_line, :mib_grammar_elixir, error_info}} ->
              error_type = ErrorAnalyzer.classify_error(error_info)
              {file, error_type}
            {:error, _other} ->
              {file, :other_error}
          end
        {:error, _} -> 
          {file, :file_error}
      end
    end)
    
    # Group by error type
    grouped = Enum.group_by(results, fn {_file, error_type} -> error_type end)
    
    IO.puts("\n📊 RESULTS:")
    Enum.each(grouped, fn {error_type, file_results} ->
      files = Enum.map(file_results, fn {file, _} -> file end)
      IO.puts("#{error_type}: #{length(files)} files")
      if error_type == :unexpected_success do
        IO.puts("  🎯 POTENTIAL QUICK WIN - These should be moved to working!")
        Enum.each(files, fn file -> IO.puts("    • #{file}") end)
      end
    end)
    
  {:error, _} ->
    IO.puts("❌ Cannot read broken directory")
end

IO.puts("\n✨ This analysis helps identify if any files were misclassified!")