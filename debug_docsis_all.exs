#!/usr/bin/env elixir

# Debug all DOCSIS MIBs (including those without .mib extension)

System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

docsis_dir = "test/fixtures/mibs/docsis"

IO.puts("=== DOCSIS MIB Test (All Files) ===")

case File.ls(docsis_dir) do
  {:ok, files} ->
    # Filter out binary files and directories, include files without extension and .mib files
    mib_files = files 
    |> Enum.filter(fn filename -> 
      not String.ends_with?(filename, ".bin") and 
      not String.ends_with?(filename, ".sh") and
      filename != "." and filename != ".."
    end)
    |> Enum.sort()
    
    IO.puts("Found #{length(mib_files)} potential DOCSIS MIB files")
    
    results = Enum.map(mib_files, fn filename ->
      mib_path = Path.join(docsis_dir, filename)
      
      # Check if it's actually a file (not directory)
      case File.stat(mib_path) do
        {:ok, %{type: :regular}} ->
          case File.read(mib_path) do
            {:ok, content} ->
              # Check if content looks like a MIB (contains DEFINITIONS)
              if String.contains?(content, "DEFINITIONS") do
                case SnmpLib.MIB.LexerErlangPort.tokenize(content) do
                  {:ok, tokens} ->
                    case SnmpLib.MIB.Parser.parse_tokens(tokens) do
                      {:ok, mib} ->
                        IO.puts("✅ #{filename} - SUCCESS (#{length(mib.definitions)} definitions)")
                        {:success, filename}
                      {:error, _errors} ->
                        IO.puts("❌ #{filename} - PARSING FAILED")
                        {:failed, filename}
                    end
                  {:error, _reason} ->
                    IO.puts("❌ #{filename} - TOKENIZATION FAILED")
                    {:failed, filename}
                end
              else
                IO.puts("⚠️  #{filename} - SKIPPED (not a MIB file)")
                {:skipped, filename}
              end
            {:error, _reason} ->
              IO.puts("❌ #{filename} - FILE READ FAILED")
              {:failed, filename}
          end
        {:ok, %{type: :directory}} ->
          IO.puts("⚠️  #{filename} - SKIPPED (directory)")
          {:skipped, filename}
        {:error, _reason} ->
          IO.puts("❌ #{filename} - STAT FAILED")
          {:failed, filename}
      end
    end)
    
    successful = results |> Enum.count(fn {status, _} -> status == :success end)
    failed = results |> Enum.count(fn {status, _} -> status == :failed end)
    skipped = results |> Enum.count(fn {status, _} -> status == :skipped end)
    total = successful + failed
    
    IO.puts("\n=== SUMMARY ===")
    if total > 0 do
      IO.puts("✅ Successful: #{successful}/#{total} (#{Float.round(successful/total*100, 1)}%)")
      IO.puts("❌ Failed: #{failed}/#{total}")
    else
      IO.puts("No MIB files processed")
    end
    IO.puts("⚠️  Skipped: #{skipped}")
    
  {:error, reason} ->
    IO.puts("✗ Failed to list DOCSIS directory: #{reason}")
end