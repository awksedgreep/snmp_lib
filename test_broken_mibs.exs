#!/usr/bin/env elixir

# Test the previously broken MIB files with our enhanced parser

System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

broken_dir = "test/fixtures/mibs/broken"

IO.puts("=== BROKEN MIB Test (Previously Failed Files) ===")

case File.ls(broken_dir) do
  {:ok, files} ->
    mib_files = files
    |> Enum.filter(&String.ends_with?(&1, ".mib"))
    |> Enum.sort()
    
    IO.puts("Found #{length(mib_files)} previously broken MIB files")
    
    results = Enum.map(mib_files, fn filename ->
      file_path = Path.join(broken_dir, filename)
      
      case File.read(file_path) do
        {:ok, content} ->
          case SnmpLib.MIB.Lexer.tokenize(content) do
            {:ok, tokens} ->
              case SnmpLib.MIB.Parser.parse_tokens(tokens) do
                {:ok, mib} ->
                  IO.puts("✅ #{filename} - SUCCESS (#{length(mib.definitions)} definitions)")
                  {:success, filename, length(mib.definitions)}
                {:error, reason} ->
                  IO.puts("❌ #{filename} - PARSING FAILED: #{inspect(reason)}")
                  {:parse_error, filename, reason}
              end
            {:error, reason} ->
              IO.puts("❌ #{filename} - TOKENIZATION FAILED: #{reason}")
              {:token_error, filename, reason}
          end
        {:error, reason} ->
          IO.puts("❌ #{filename} - FILE READ FAILED: #{reason}")
          {:file_error, filename, reason}
      end
    end)
    
    successful = Enum.count(results, fn {status, _, _} -> status == :success end)
    total = length(results)
    
    IO.puts("\n=== SUMMARY ===")
    IO.puts("✅ Successful: #{successful}/#{total} (#{Float.round(successful/total*100, 1)}%)")
    IO.puts("❌ Failed: #{total - successful}/#{total}")
    
    if successful > 0 do
      IO.puts("\n=== NEWLY WORKING FILES ===")
      results
      |> Enum.filter(fn {status, _, _} -> status == :success end)
      |> Enum.each(fn {:success, filename, defs} ->
        IO.puts("🎉 #{filename} - #{defs} definitions")
      end)
    end
    
    failed_files = results
    |> Enum.filter(fn {status, _, _} -> status != :success end)
    
    if length(failed_files) > 0 do
      IO.puts("\n=== STILL FAILING FILES ===")
      failed_files
      |> Enum.each(fn {_status, filename, reason} ->
        IO.puts("💥 #{filename} - #{inspect(reason)}")
      end)
    end
    
  {:error, reason} ->
    IO.puts("❌ Failed to read broken directory: #{reason}")
end