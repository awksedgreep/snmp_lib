#!/usr/bin/env elixir

# Simple test suite for DOCSIS MIBs

mibs_dir = "test/fixtures/mibs/docsis"

# Get list of DOCSIS MIB files  
case File.ls(mibs_dir) do
  {:ok, files} ->
    docsis_files = files
                  |> Enum.filter(&(String.contains?(&1, "DOCS") or String.contains?(&1, "CLAB")))
                  |> Enum.sort()

    IO.puts("=== DOCSIS MIB PARSING RESULTS ===")
    IO.puts("Total DOCSIS MIB files: #{length(docsis_files)}")
    IO.puts("")

    results = Enum.map(docsis_files, fn file ->
      file_path = Path.join(mibs_dir, file)
      
      case File.read(file_path) do
        {:ok, content} ->
          case SnmpLib.MIB.LexerErlangPort.tokenize(content) do
            {:ok, tokens} ->
              case SnmpLib.MIB.Parser.parse_tokens(tokens) do
                {:ok, mib} ->
                  IO.puts("✅ #{file} - SUCCESS (#{length(mib.definitions)} definitions)")
                  :success
                {:error, _errors} ->
                  IO.puts("❌ #{file} - PARSING FAILED")
                  :parse_failed
              end
            {:error, _reason} ->
              IO.puts("❌ #{file} - TOKENIZATION FAILED")
              :tokenize_failed
          end
        {:error, _reason} ->
          IO.puts("❌ #{file} - FILE READ FAILED")
          :file_failed
      end
    end)

    success_count = Enum.count(results, &(&1 == :success))
    total_count = length(results)
    success_rate = Float.round(success_count / total_count * 100, 1)

    IO.puts("")
    IO.puts("=== SUMMARY ===")
    IO.puts("✅ Successful: #{success_count}/#{total_count} (#{success_rate}%)")
    IO.puts("❌ Failed: #{total_count - success_count}/#{total_count}")

  {:error, reason} ->
    IO.puts("Error reading MIBs directory: #{reason}")
end