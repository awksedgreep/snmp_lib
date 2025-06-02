#!/usr/bin/env elixir

# Detailed failure analysis script
IO.puts("🔍 DETAILED FAILURE ANALYSIS")
IO.puts("========================================")

mib_dirs = [
  {"/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working", "Working"},
  {"/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/broken", "Broken"},
  {"/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/docsis", "DOCSIS"}
]

failures = []

Enum.each(mib_dirs, fn {dir, name} ->
  IO.puts("\n📁 #{name} Directory: #{dir}")
  IO.puts("----------------------------------------")
  
  case File.ls(dir) do
    {:ok, files} ->
      mib_files = files |> Enum.filter(fn file -> 
        String.ends_with?(file, ".mib") or 
        (not String.contains?(file, ".") and not String.ends_with?(file, ".bin"))
      end)
      
      Enum.each(mib_files, fn file ->
        file_path = Path.join(dir, file)
        case File.read(file_path) do
          {:ok, content} ->
            case SnmpLib.MIB.ActualParser.parse(content) do
              {:ok, _} -> 
                IO.puts("✅ #{file}")
              {:error, reason} -> 
                IO.puts("❌ #{file}")
                IO.puts("   Error: #{inspect(reason)}")
                failures = [{file, name, reason} | failures]
            end
          {:error, _} -> 
            IO.puts("📁 #{file} - File read error")
        end
      end)
      
    {:error, _} ->
      IO.puts("❌ Cannot read directory")
  end
end)

IO.puts("\n\n🎯 FAILURE SUMMARY")
IO.puts("========================================")
IO.puts("Total failures: #{length(failures)}")

# Group failures by directory
failures_by_dir = Enum.group_by(failures, fn {_file, dir, _reason} -> dir end)

Enum.each(failures_by_dir, fn {dir, dir_failures} ->
  IO.puts("\n📂 #{dir} Directory Failures:")
  Enum.each(dir_failures, fn {file, _dir, reason} ->
    IO.puts("  • #{file}")
    case reason do
      {line, :mib_grammar_elixir, error_info} ->
        IO.puts("    Line #{line}: #{inspect(error_info)}")
      other ->
        IO.puts("    #{inspect(other)}")
    end
  end)
end)

# Analyze error patterns
IO.puts("\n\n🔍 ERROR PATTERN ANALYSIS")
IO.puts("========================================")

error_patterns = failures
|> Enum.map(fn {_file, _dir, reason} -> reason end)
|> Enum.frequencies()

Enum.each(error_patterns, fn {pattern, count} ->
  IO.puts("#{count}x: #{inspect(pattern)}")
end)

IO.puts("\n\n📋 SPECIFIC FAILED FILES")
IO.puts("========================================")
failed_files = failures |> Enum.map(fn {file, dir, _reason} -> "#{dir}/#{file}" end)
Enum.each(failed_files, fn file ->
  IO.puts("• #{file}")
end)

IO.puts("\n✨ Analysis complete!")