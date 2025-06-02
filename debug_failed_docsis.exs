#!/usr/bin/env elixir

# Debug the two failing DOCSIS MIBs

System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

docsis_dir = "test/fixtures/mibs/docsis"
failed_files = ["IF-MIB", "PKTC-EVENT-MIB"]

IO.puts("=== Debugging Failed DOCSIS MIBs ===")

Enum.each(failed_files, fn filename ->
  IO.puts("\n=== #{filename} ===")
  mib_path = Path.join(docsis_dir, filename)
  
  case File.read(mib_path) do
    {:ok, content} ->
      IO.puts("✓ File read successful: #{byte_size(content)} bytes")
      
      # Check if it looks like a MIB
      if String.contains?(content, "DEFINITIONS") do
        IO.puts("✓ Contains DEFINITIONS - looks like a MIB")
        
        # Show first few lines to understand structure
        lines = String.split(content, "\n")
        IO.puts("\nFirst 10 lines:")
        lines
        |> Enum.take(10)
        |> Enum.with_index(1)
        |> Enum.each(fn {line, idx} ->
          IO.puts("#{String.pad_leading(to_string(idx), 3)}: #{line}")
        end)
        
        # Try tokenization and see what error we get
        IO.puts("\n=== Tokenization attempt ===")
        case SnmpLib.MIB.LexerErlangPort.tokenize(content) do
          {:ok, tokens} ->
            IO.puts("✓ Tokenization successful: #{length(tokens)} tokens")
          {:error, reason} ->
            IO.puts("✗ Tokenization failed: #{reason}")
            
            # Let's try to find problematic content
            IO.puts("\nSearching for potential issues...")
            
            # Check for unusual characters
            if String.contains?(content, <<0>>) do
              IO.puts("⚠️  Contains null bytes - might be binary content")
            end
            
            # Check for very long lines
            long_lines = lines
            |> Enum.with_index(1)
            |> Enum.filter(fn {line, _idx} -> String.length(line) > 200 end)
            
            if length(long_lines) > 0 do
              IO.puts("⚠️  Found #{length(long_lines)} very long lines (>200 chars)")
              Enum.take(long_lines, 3) |> Enum.each(fn {line, idx} ->
                IO.puts("Line #{idx}: #{String.length(line)} chars - #{String.slice(line, 0, 100)}...")
              end)
            end
            
            # Look for problematic patterns
            problematic_patterns = [
              {~r/[^\x20-\x7E\n\r\t]/, "non-printable characters"},
              {~r/--.*?--.*?--/, "multiple comment markers"},
              {~r/\r\n/, "Windows line endings"},
              {~r/"[^"]*$/, "unclosed quotes"}
            ]
            
            Enum.each(problematic_patterns, fn {pattern, description} ->
              if Regex.match?(pattern, content) do
                IO.puts("⚠️  Found #{description}")
              end
            end)
        end
      else
        IO.puts("✗ Does not contain DEFINITIONS - not a MIB file")
      end
      
    {:error, reason} ->
      IO.puts("✗ File read failed: #{reason}")
  end
end)