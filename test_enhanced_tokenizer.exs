#!/usr/bin/env elixir

# Test the enhanced Erlang-faithful tokenizer against all DOCSIS MIBs

# Get all DOCSIS MIB files
mibs_dir = "test/fixtures/mibs/docsis"
mib_files = File.ls!(mibs_dir)

IO.puts("Testing #{length(mib_files)} DOCSIS MIBs with enhanced Erlang-faithful tokenizer...")
IO.puts("=" <> String.duplicate("=", 80))

successes = []
failures = []

{successes, failures} = Enum.reduce(mib_files, {[], []}, fn file, {successes_acc, failures_acc} ->
  file_path = Path.join(mibs_dir, file)
  
  case File.read(file_path) do
    {:ok, content} ->
      case SnmpLib.MIB.LexerErlangPort.tokenize(content) do
        {:ok, tokens} ->
          case SnmpLib.MIB.Parser.parse_tokens(tokens) do
            {:ok, _mib} ->
              IO.puts("✓ #{file} - SUCCESS (#{length(tokens)} tokens)")
              {[file | successes_acc], failures_acc}
            {:error, reason} ->
              IO.puts("✗ #{file} - PARSE FAILED: #{inspect(reason)}")
              {successes_acc, [file | failures_acc]}
          end
        {:error, reason} ->
          IO.puts("✗ #{file} - TOKENIZE FAILED: #{reason}")
          {successes_acc, [file | failures_acc]}
      end
    {:error, reason} ->
      IO.puts("✗ #{file} - READ FAILED: #{reason}")
      {successes_acc, [file | failures_acc]}
  end
end)

IO.puts("\n" <> String.duplicate("=", 80))
IO.puts("RESULTS:")
IO.puts("  Successes: #{length(successes)}")
IO.puts("  Failures: #{length(failures)}")
IO.puts("  Success Rate: #{Float.round(length(successes) / length(mib_files) * 100, 1)}%")

if length(failures) > 0 do
  IO.puts("\nFailed files:")
  Enum.each(failures, fn file -> IO.puts("  - #{file}") end)
end

if length(successes) > 0 do
  IO.puts("\nSuccessful files:")
  Enum.each(successes, fn file -> IO.puts("  + #{file}") end)
end