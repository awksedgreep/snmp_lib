#!/usr/bin/env elixir

# Simple debug for DOCSIS MIBs

System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

docsis_dir = "test/fixtures/mibs/docsis"

IO.puts("=== DOCSIS MIB Test ===")

case File.ls(docsis_dir) do
  {:ok, files} ->
    mib_files = files 
    |> Enum.filter(&String.ends_with?(&1, ".mib"))
    |> Enum.sort()
    
    IO.puts("Found #{length(mib_files)} DOCSIS MIB files")
    
    results = Enum.map(mib_files, fn filename ->
      mib_path = Path.join(docsis_dir, filename)
      
      case File.read(mib_path) do
        {:ok, content} ->
          case SnmpLib.MIB.LexerErlangPort.tokenize(content) do
            {:ok, tokens} ->
              case SnmpLib.MIB.Parser.parse_tokens(tokens) do
                {:ok, mib} ->
                  IO.puts("✅ #{filename} - SUCCESS (#{length(mib.definitions)} definitions)")
                  {:success, filename}
                {:error, _errors} ->
                  IO.puts("❌ #{filename} - FAILED")
                  {:failed, filename}
              end
            {:error, _reason} ->
              IO.puts("❌ #{filename} - TOKENIZATION FAILED")
              {:failed, filename}
          end
        {:error, _reason} ->
          IO.puts("❌ #{filename} - FILE READ FAILED")
          {:failed, filename}
      end
    end)
    
    successful = results |> Enum.count(fn {status, _} -> status == :success end)
    total = length(results)
    
    IO.puts("\n=== SUMMARY ===")
    IO.puts("✅ Successful: #{successful}/#{total} (#{Float.round(successful/total*100, 1)}%)")
    IO.puts("❌ Failed: #{total - successful}/#{total}")
    
  {:error, reason} ->
    IO.puts("✗ Failed to list DOCSIS directory: #{reason}")
end