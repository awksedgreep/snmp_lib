#!/usr/bin/env elixir

# Configure logger to be quiet for clean output
Logger.configure(level: :warn)

IO.puts("🎯 MIBDIRS HELPER FUNCTION EXAMPLE")
IO.puts("=================================")

# Define the directories containing MIB files
dirs = [
  "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working",
  "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/docsis"
]

# Compile all MIBs in the specified directories
results = SnmpLib.MIB.Parser.mibdirs(dirs)

IO.puts("\n📋 DETAILED RESULTS:")
IO.puts("===================")

# Access results by directory
Enum.each(results, fn {dir, result} ->
  dir_name = Path.basename(dir)
  IO.puts("\n📂 #{dir_name} Directory:")
  IO.puts("   Total files: #{result.total}")
  IO.puts("   Successful: #{result.success_count}")
  IO.puts("   Failed: #{result.failure_count}")
  
  # Show first 3 successful MIBs
  if result.success_count > 0 do
    IO.puts("   ✅ Sample successful MIBs:")
    result.success
    |> Enum.take(3)
    |> Enum.each(fn mib ->
      IO.puts("      • #{mib.name} (#{length(mib.definitions)} definitions) - #{mib.source_file}")
    end)
    
    if result.success_count > 3 do
      IO.puts("      • ... and #{result.success_count - 3} more")
    end
  end
  
  # Show failures if any
  if result.failure_count > 0 do
    IO.puts("   ❌ Failed files:")
    result.failures
    |> Enum.take(3)
    |> Enum.each(fn failure ->
      IO.puts("      • #{failure.file}")
    end)
    
    if result.failure_count > 3 do
      IO.puts("      • ... and #{result.failure_count - 3} more")
    end
  end
end)

# Example: Get all successful MIBs across all directories
all_mibs = Enum.flat_map(results, fn {_dir, result} -> result.success end)
IO.puts("\n🌟 SUMMARY:")
IO.puts("Total successful MIBs across all directories: #{length(all_mibs)}")

# Example: Find specific MIBs
smux_mib = Enum.find(all_mibs, fn mib -> mib.name == "SMUX-MIB" end)
if smux_mib do
  IO.puts("Found SMUX-MIB with #{length(smux_mib.definitions)} definitions")
end

# Example: Get MIBs by type
object_type_counts = Enum.map(all_mibs, fn mib ->
  object_types = Enum.count(mib.definitions, fn def -> def.__type__ == :object_type end)
  {mib.name, object_types}
end)

top_mibs = object_type_counts 
|> Enum.sort_by(&elem(&1, 1), :desc)
|> Enum.take(5)

IO.puts("\n🏆 Top 5 MIBs by object type count:")
Enum.each(top_mibs, fn {name, count} ->
  IO.puts("   #{name}: #{count} object types")
end)