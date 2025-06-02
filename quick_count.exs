#!/usr/bin/env elixir

# Quick count of regular MIB parsing results from previous run

failed_files = [
  "RFC-1215.mib",
  "RFC1155-SMI.mib", 
  "SMUX-MIB.mib",
  "SNMPv2-SMI.mib",
  "UDP-MIB.mib"
]

# Count total files
{mib_files_output, 0} = System.cmd("find", ["test/fixtures/mibs", "-name", "*.mib", "-not", "-path", "*/docsis/*"])
total_files = mib_files_output |> String.trim() |> String.split("\n") |> Enum.reject(&(&1 == "")) |> length()

successful = total_files - length(failed_files)

IO.puts("=== REGULAR MIB PARSING SUMMARY ===")
IO.puts("Total regular MIB files: #{total_files}")
IO.puts("✅ Successful: #{successful}/#{total_files} (#{Float.round(successful / total_files * 100, 1)}%)")
IO.puts("❌ Failed: #{length(failed_files)}/#{total_files}")
IO.puts("")
IO.puts("=== FAILED FILES ===")
Enum.each(failed_files, fn file ->
  IO.puts("- #{file}")
end)