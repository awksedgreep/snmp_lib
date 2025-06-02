#!/usr/bin/env elixir

# Debug all failing MIB files to understand their specific errors

# Change to the project directory and load the compiled modules
System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

# Known failing files from previous runs
failing_files = [
  "RFC-1215.mib",
  "RFC1155-SMI.mib", 
  "SMUX-MIB.mib",
  "SNMPv2-SMI.mib",
  "UDP-MIB.mib"
]

IO.puts("=== DEBUGGING ALL FAILING MIB FILES ===")
IO.puts("Total failing files: #{length(failing_files)}")
IO.puts("")

Enum.each(failing_files, fn filename ->
  mib_file = "test/fixtures/mibs/working/#{filename}"
  
  IO.puts("=== #{filename} ===")
  
  case File.read(mib_file) do
    {:ok, content} ->
      size = byte_size(content)
      lines = String.split(content, "\n") |> length()
      IO.puts("File: #{size} bytes, #{lines} lines")
      
      case SnmpLib.MIB.LexerErlangPort.tokenize(content) do
        {:ok, tokens} ->
          IO.puts("✓ Tokenization: #{length(tokens)} tokens")
          
          case SnmpLib.MIB.Parser.parse_tokens(tokens) do
            {:ok, mib} ->
              IO.puts("✓ Parsing: SUCCESS - #{length(mib.definitions)} definitions")
            {:error, errors} when is_list(errors) ->
              IO.puts("✗ Parsing: FAILED with #{length(errors)} errors:")
              Enum.each(errors, fn error ->
                IO.puts("  - #{inspect(error)}")
              end)
            {:error, error} ->
              IO.puts("✗ Parsing: FAILED")
              IO.puts("  #{inspect(error)}")
          end
        {:error, reason} ->
          IO.puts("✗ Tokenization: FAILED - #{reason}")
      end
    {:error, reason} ->
      IO.puts("✗ File read: FAILED - #{reason}")
  end
  
  IO.puts("")
end)