#!/usr/bin/env elixir

# Configure logger to be quiet for clean output
Logger.configure(level: :warn)

IO.puts("🎯 SIMPLE MIBDIRS EXAMPLE")
IO.puts("========================")

# Define directories to compile  
dirs = [
  "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working",
  "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/docsis"
]

# Compile all MIBs - this returns a map with results by directory
results = SnmpLib.MIB.Parser.mibdirs(dirs)

# Access results for a specific directory
working_results = results["/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working"] 
docsis_results = results["/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/docsis"]

IO.puts("\n✨ EXAMPLE USAGE:")
IO.puts("Working directory: #{working_results.success_count}/#{working_results.total} successful")
IO.puts("DOCSIS directory: #{docsis_results.success_count}/#{docsis_results.total} successful")

# Get all MIBs across directories
all_mibs = Enum.flat_map(results, fn {_dir, result} -> result.success end)
IO.puts("Total MIBs compiled: #{length(all_mibs)}")

# Find specific MIBs
smux = Enum.find(all_mibs, &(&1.name == "SMUX-MIB"))
if smux, do: IO.puts("Found SMUX-MIB: #{length(smux.definitions)} definitions")

# Show sample MIB data structure
if length(all_mibs) > 0 do
  sample = List.first(all_mibs)
  IO.puts("\n📋 Sample MIB structure:")
  IO.puts("  Name: #{sample.name}")
  IO.puts("  Type: #{sample.__type__}")
  IO.puts("  Definitions: #{length(sample.definitions)}")
  IO.puts("  Imports: #{length(sample.imports)}")
  IO.puts("  Source file: #{sample.source_file}")
end