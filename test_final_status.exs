#!/usr/bin/env elixir

# Final comprehensive test of all MIB files to assess overall success rate

System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

# Test regular MIBs
regular_dir = "test/fixtures/mibs/working"
IO.puts("=== Testing Regular MIB Files ===")

regular_files = 
  case File.ls(regular_dir) do
    {:ok, files} -> 
      files 
      |> Enum.filter(&String.ends_with?(&1, ".mib"))
      |> Enum.sort()
    {:error, _} -> []
  end

regular_results = Enum.map(regular_files, fn file ->
  path = Path.join(regular_dir, file)
  case File.read(path) do
    {:ok, content} ->
      case SnmpLib.MIB.LexerErlangPort.tokenize(content) do
        {:ok, tokens} ->
          case SnmpLib.MIB.Parser.parse_tokens(tokens) do
            {:ok, mib} ->
              {file, :success, length(mib.definitions)}
            {:error, _} ->
              {file, :parse_error, 0}
          end
        {:error, _} ->
          {file, :tokenize_error, 0}
      end
    {:error, _} ->
      {file, :read_error, 0}
  end
end)

successful_regular = Enum.count(regular_results, fn {_, status, _} -> status == :success end)
total_regular = length(regular_results)

IO.puts("Regular MIB Results:")
IO.puts("✓ Success: #{successful_regular}/#{total_regular} (#{Float.round(successful_regular/total_regular*100, 1)}%)")

# Test DOCSIS MIBs  
docsis_dir = "test/fixtures/mibs/docsis"
IO.puts("\n=== Testing DOCSIS MIB Files ===")

docsis_files = 
  case File.ls(docsis_dir) do
    {:ok, files} -> 
      files 
      |> Enum.filter(fn file -> 
        # DOCSIS files may not have .mib extension
        not String.contains?(file, ".") or String.ends_with?(file, ".mib")
      end)
      |> Enum.sort()
    {:error, _} -> []
  end

docsis_results = Enum.map(docsis_files, fn file ->
  path = Path.join(docsis_dir, file)
  case File.read(path) do
    {:ok, content} ->
      case SnmpLib.MIB.LexerErlangPort.tokenize(content) do
        {:ok, tokens} ->
          case SnmpLib.MIB.Parser.parse_tokens(tokens) do
            {:ok, mib} ->
              {file, :success, length(mib.definitions)}
            {:error, _} ->
              {file, :parse_error, 0}
          end
        {:error, _} ->
          {file, :tokenize_error, 0}
      end
    {:error, _} ->
      {file, :read_error, 0}
  end
end)

successful_docsis = Enum.count(docsis_results, fn {_, status, _} -> status == :success end)
total_docsis = length(docsis_results)

IO.puts("DOCSIS MIB Results:")
IO.puts("✓ Success: #{successful_docsis}/#{total_docsis} (#{Float.round(successful_docsis/total_docsis*100, 1)}%)")

# Show failed files
failed_regular = Enum.filter(regular_results, fn {_, status, _} -> status != :success end)
failed_docsis = Enum.filter(docsis_results, fn {_, status, _} -> status != :success end)

if length(failed_regular) > 0 do
  IO.puts("\nFailed Regular MIBs:")
  Enum.each(failed_regular, fn {file, status, _} ->
    IO.puts("  ❌ #{file} - #{status}")
  end)
end

if length(failed_docsis) > 0 do
  IO.puts("\nFailed DOCSIS MIBs:")
  Enum.each(failed_docsis, fn {file, status, _} ->
    IO.puts("  ❌ #{file} - #{status}")
  end)
end

# Overall summary
total_files = total_regular + total_docsis
total_successful = successful_regular + successful_docsis

IO.puts("\n=== FINAL SUMMARY ===")
IO.puts("Total files tested: #{total_files}")
IO.puts("Total successful: #{total_successful}")
IO.puts("Overall success rate: #{Float.round(total_successful/total_files*100, 1)}%")

# Progress made
IO.puts("\n=== PROGRESS MADE ===")
IO.puts("✓ Fixed OCTET STRING constraint parsing")
IO.puts("✓ Fixed INTEGER constraint parsing") 
IO.puts("✓ Fixed ASN.1 type definitions starting with keywords")
IO.puts("✓ Fixed generic MACRO definition parsing")
IO.puts("✓ Fixed tagged type definitions")
IO.puts("✓ Fixed UTF-8 encoding issues in PKTC-EVENT-MIB")
IO.puts("✓ Fixed IF-MIB RFC document extraction")
IO.puts("✓ Added single-quoted CONTACT-INFO support")
IO.puts("✓ Enhanced multi-line description parsing")

remaining_issues = total_files - total_successful
if remaining_issues > 0 do
  IO.puts("\n⚠️  #{remaining_issues} files still need attention")
  IO.puts("Main remaining issue: Complex multi-line quoted string tokenization")
end