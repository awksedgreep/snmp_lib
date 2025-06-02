#!/usr/bin/env elixir

# Test all regular MIB files (excluding DOCSIS)

# Change to the project directory and load the compiled modules
System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

# Find all regular MIB files (excluding DOCSIS)
{mib_files_output, 0} = System.cmd("find", ["test/fixtures/mibs", "-name", "*.mib", "-not", "-path", "*/docsis/*"])

mib_files = 
  mib_files_output
  |> String.trim()
  |> String.split("\n")
  |> Enum.reject(&(&1 == ""))
  |> Enum.sort()

IO.puts("=== REGULAR MIB PARSING RESULTS ===")
IO.puts("Total regular MIB files: #{length(mib_files)}")
IO.puts("")

# Track results
successful = Enum.reduce(mib_files, [], fn mib_file, acc ->
  mib_name = Path.basename(mib_file)
  
  case File.read(mib_file) do
    {:ok, content} ->
      case SnmpLib.MIB.LexerErlangPort.tokenize(content) do
        {:ok, tokens} ->
          case SnmpLib.MIB.Parser.parse_tokens(tokens) do
            {:ok, mib} ->
              IO.puts("✅ #{mib_name} - SUCCESS (#{length(mib.definitions)} definitions)")
              [mib_name | acc]
            {:error, _errors} ->
              IO.puts("❌ #{mib_name} - FAILED (parsing error)")
              acc
          end
        {:error, _reason} ->
          IO.puts("❌ #{mib_name} - FAILED (tokenization error)")
          acc
      end
    {:error, _reason} ->
      IO.puts("❌ #{mib_name} - FAILED (file read error)")
      acc
  end
end)

failed = Enum.reduce(mib_files, [], fn mib_file, acc ->
  mib_name = Path.basename(mib_file)
  
  case File.read(mib_file) do
    {:ok, content} ->
      case SnmpLib.MIB.LexerErlangPort.tokenize(content) do
        {:ok, tokens} ->
          case SnmpLib.MIB.Parser.parse_tokens(tokens) do
            {:ok, _mib} ->
              acc
            {:error, _errors} ->
              [mib_name | acc]
          end
        {:error, _reason} ->
          [mib_name | acc]
      end
    {:error, _reason} ->
      [mib_name | acc]
  end
end)

IO.puts("")
IO.puts("=== SUMMARY ===")
IO.puts("✅ Successful: #{length(successful)}/#{length(mib_files)} (#{Float.round(length(successful) / length(mib_files) * 100, 1)}%)")
IO.puts("❌ Failed: #{length(failed)}/#{length(mib_files)}")

if length(failed) > 0 do
  IO.puts("")
  IO.puts("=== FAILED FILES ===")
  Enum.each(Enum.reverse(failed), fn file ->
    IO.puts("- #{file}")
  end)
end