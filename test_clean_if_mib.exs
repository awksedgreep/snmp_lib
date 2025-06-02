#!/usr/bin/env elixir

# Test the clean IF-MIB file

System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

docsis_dir = "test/fixtures/mibs/docsis"
clean_mib_path = Path.join(docsis_dir, "IF-MIB.clean")

IO.puts("=== Testing Clean IF-MIB File ==")

case File.read(clean_mib_path) do
  {:ok, content} ->
    IO.puts("✓ File read: #{byte_size(content)} bytes")
    
    case SnmpLib.MIB.LexerErlangPort.tokenize(content) do
      {:ok, tokens} ->
        IO.puts("✓ Tokenization successful: #{length(tokens)} tokens")
        
        case SnmpLib.MIB.Parser.parse_tokens(tokens) do
          {:ok, mib} ->
            IO.puts("✓ Parsing successful: #{length(mib.definitions)} definitions")
            IO.puts("MIB name: #{mib.name}")
            IO.puts("MIB type: #{mib.__type__}")
            
            # Show a few definitions
            IO.puts("\nFirst 5 definitions:")
            mib.definitions
            |> Enum.take(5)
            |> Enum.each(fn def ->
              IO.puts("  - #{def.name} (#{def.__type__})")
            end)
            
          {:error, reason} ->
            IO.puts("❌ Parsing failed: #{inspect(reason)}")
        end
        
      {:error, reason} ->
        IO.puts("❌ Tokenization failed: #{reason}")
    end
    
  {:error, reason} ->
    IO.puts("❌ File read failed: #{reason}")
end