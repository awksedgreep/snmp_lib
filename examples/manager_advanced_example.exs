#!/usr/bin/env elixir

# Configure logger to be quiet for clean output
Logger.configure(level: :warn)

IO.puts("🚀 SNMP MANAGER ADVANCED OPERATIONS EXAMPLE")
IO.puts("===========================================")

# Example devices (replace with your actual devices)
devices = [
  %{host: "192.168.1.1", community: "public", name: "Router"},
  %{host: "192.168.1.10", community: "public", name: "Switch"},
  %{host: "192.168.1.20", community: "monitoring", name: "Server"}
]

IO.puts("\n🌐 MULTI-DEVICE MONITORING:")
IO.puts("===========================")

# Function to safely get SNMP value with type information
safe_snmp_get = fn host, oid, opts ->
  case SnmpLib.Manager.get(host, oid, opts) do
    {:ok, {type, value}} -> {:ok, type, value}
    {:error, reason} -> {:error, reason}
  end
end

# Example 1: Monitor system information across multiple devices
IO.puts("\n1. System Information Survey:")

system_oids = %{
  description: [1, 3, 6, 1, 2, 1, 1, 1, 0],
  uptime: [1, 3, 6, 1, 2, 1, 1, 3, 0],
  name: [1, 3, 6, 1, 2, 1, 1, 5, 0],
  location: [1, 3, 6, 1, 2, 1, 1, 6, 0]
}

Enum.each(devices, fn device ->
  IO.puts("\n   📱 #{device.name} (#{device.host}):")
  
  Enum.each(system_oids, fn {field, oid} ->
    case safe_snmp_get.(device.host, oid, community: device.community, timeout: 3000) do
      {:ok, type, value} ->
        formatted_value = case {field, type} do
          {:uptime, :timeticks} ->
            seconds = div(value, 100)
            days = div(seconds, 86400)
            hours = div(rem(seconds, 86400), 3600)
            "#{days}d #{hours}h (#{value} ticks)"
          {:description, :octet_string} ->
            String.slice(to_string(value), 0, 50) <> "..."
          {_, :octet_string} ->
            "\"#{value}\""
          _ ->
            "#{inspect(value)} (#{type})"
        end
        IO.puts("      #{field}: #{formatted_value}")
      {:error, reason} ->
        IO.puts("      #{field}: ❌ #{inspect(reason)}")
    end
  end)
end)

IO.puts("\n📊 INTERFACE STATISTICS COLLECTION:")
IO.puts("===================================")

# Example 2: Collect interface statistics with type awareness
IO.puts("\n2. Interface Statistics (with type preservation):")

interface_oids = %{
  if_descr: [1, 3, 6, 1, 2, 1, 2, 2, 1, 2],      # ifDescr
  if_in_octets: [1, 3, 6, 1, 2, 1, 2, 2, 1, 10], # ifInOctets (Counter32)
  if_out_octets: [1, 3, 6, 1, 2, 1, 2, 2, 1, 16], # ifOutOctets (Counter32)
  if_speed: [1, 3, 6, 1, 2, 1, 2, 2, 1, 5]        # ifSpeed (Gauge32)
}

# Function to format interface statistics based on type
format_interface_stat = fn type, value ->
  case type do
    :counter32 ->
      if value > 1_000_000_000 do
        "#{Float.round(value / 1_000_000_000, 2)} GB"
      else
        "#{Float.round(value / 1_000_000, 2)} MB"
      end
    :gauge32 ->
      if value > 1_000_000 do
        "#{div(value, 1_000_000)} Mbps"
      else
        "#{div(value, 1000)} Kbps"
      end
    :octet_string ->
      to_string(value)
    _ ->
      inspect(value)
  end
end

Enum.take(devices, 1) |> Enum.each(fn device ->
  IO.puts("\n   🔌 Interface Stats for #{device.name}:")
  
  # Get first few interfaces using bulk operation
  case SnmpLib.Manager.get_bulk(device.host, interface_oids.if_descr, 
                                 max_repetitions: 3, community: device.community) do
    {:ok, results} ->
      IO.puts("      Found #{length(results)} interfaces:")
      
      # Each result is {oid, type, value}
      Enum.with_index(results, 1) |> Enum.each(fn {{oid, type, value}, index} ->
        interface_index = List.last(oid)
        description = format_interface_stat.(type, value)
        
        IO.puts("      #{index}. Interface #{interface_index}: #{description}")
        
        # Get statistics for this interface
        Enum.each([:if_in_octets, :if_out_octets, :if_speed], fn stat_type ->
          base_oid = interface_oids[stat_type]
          stat_oid = base_oid ++ [interface_index]
          
          case safe_snmp_get.(device.host, stat_oid, community: device.community) do
            {:ok, stat_value_type, stat_value} ->
              formatted = format_interface_stat.(stat_value_type, stat_value)
              IO.puts("         #{stat_type}: #{formatted} (#{stat_value_type})")
            {:error, _reason} ->
              IO.puts("         #{stat_type}: N/A")
          end
        end)
      end)
    {:error, reason} ->
      IO.puts("      ❌ Failed to get interfaces: #{inspect(reason)}")
  end
end)

IO.puts("\n🔄 SNMP WALKING WITH TYPE PRESERVATION:")
IO.puts("======================================")

# Example 3: SNMP table walking with proper type handling
IO.puts("\n3. System Services Table Walk:")

services_oid = [1, 3, 6, 1, 2, 1, 1, 7]  # sysServices subtree

Enum.take(devices, 1) |> Enum.each(fn device ->
  IO.puts("\n   🚶 Walking #{device.name} system services:")
  
  # Use get_next to walk the tree
  current_oid = services_oid
  walk_count = 0
  max_walks = 5
  
  walk_results = Enum.reduce_while(1..max_walks, {current_oid, []}, fn _step, {oid, results} ->
    case SnmpLib.Manager.get_next(device.host, oid, community: device.community) do
      {:ok, {next_oid, {type, value}}} ->
        # Check if we're still in the same subtree
        if List.starts_with?(next_oid, services_oid) do
          result = {next_oid, type, value}
          {:cont, {next_oid, [result | results]}}
        else
          {:halt, {oid, results}}
        end
      {:error, _reason} ->
        {:halt, {oid, results}}
    end
  end)
  
  {_final_oid, walk_results_list} = walk_results
  results = Enum.reverse(walk_results_list)
  
  if length(results) > 0 do
    IO.puts("      Found #{length(results)} entries:")
    Enum.each(results, fn {oid, type, value} ->
      oid_str = Enum.join(oid, ".")
      IO.puts("      • #{oid_str}: #{inspect(value)} (#{type})")
    end)
  else
    IO.puts("      No results found (device may not support this MIB)")
  end
end)

IO.puts("\n⚡ PERFORMANCE MONITORING:")
IO.puts("=========================")

# Example 4: Performance monitoring with type-aware calculations
IO.puts("\n4. CPU and Memory Monitoring (with proper type handling):")

# Common performance OIDs (may not be available on all devices)
perf_oids = %{
  cpu_usage: [1, 3, 6, 1, 4, 1, 9, 2, 1, 56, 0],    # Cisco CPU (example)
  memory_used: [1, 3, 6, 1, 4, 1, 9, 2, 1, 8, 0],   # Cisco Memory Used
  memory_free: [1, 3, 6, 1, 4, 1, 9, 2, 1, 9, 0]    # Cisco Memory Free
}

Enum.take(devices, 1) |> Enum.each(fn device ->
  IO.puts("\n   📈 Performance metrics for #{device.name}:")
  
  Enum.each(perf_oids, fn {metric, oid} ->
    case safe_snmp_get.(device.host, oid, community: device.community, timeout: 2000) do
      {:ok, type, value} ->
        formatted = case {metric, type} do
          {:cpu_usage, :gauge32} -> "#{value}%"
          {:memory_used, :gauge32} -> "#{Float.round(value / 1024 / 1024, 1)} MB"
          {:memory_free, :gauge32} -> "#{Float.round(value / 1024 / 1024, 1)} MB"
          _ -> "#{value} (#{type})"
        end
        IO.puts("      #{metric}: #{formatted}")
      {:error, reason} ->
        IO.puts("      #{metric}: ❌ #{inspect(reason)}")
    end
  end)
end)

IO.puts("\n🛠️ ERROR HANDLING PATTERNS:")
IO.puts("============================")

# Example 5: Robust error handling with type information
IO.puts("\n5. Error Handling Best Practices:")

robust_snmp_operation = fn host, oid, opts ->
  case SnmpLib.Manager.get(host, oid, opts) do
    {:ok, {type, value}} ->
      # Success - we have type information
      {:success, type, value}
    
    {:error, :timeout} ->
      {:retry_later, "Device not responding"}
    
    {:error, :no_such_name} ->
      {:unsupported, "OID not supported by device"}
    
    {:error, {:snmp_error, :no_such_object}} ->
      {:missing, "Object does not exist"}
    
    {:error, reason} ->
      {:failed, "Unknown error: #{inspect(reason)}"}
  end
end

# Test error handling
test_oids = [
  {[1, 3, 6, 1, 2, 1, 1, 1, 0], "System Description (should work)"},
  {[1, 3, 6, 1, 2, 1, 99, 99, 0], "Non-existent OID (should fail)"},
  {[1, 3, 6, 1, 4, 1, 99999, 1, 0], "Vendor-specific OID (may fail)"}
]

Enum.each(test_oids, fn {oid, description} ->
  IO.puts("\n   Testing: #{description}")
  
  case robust_snmp_operation.( "192.168.1.1", oid, timeout: 1000) do
    {:success, type, value} ->
      IO.puts("      ✅ Success: #{inspect(value)} (#{type})")
    {:retry_later, message} ->
      IO.puts("      🔄 Retry: #{message}")
    {:unsupported, message} ->
      IO.puts("      ⚠️  Unsupported: #{message}")
    {:missing, message} ->
      IO.puts("      ❓ Missing: #{message}")
    {:failed, message} ->
      IO.puts("      ❌ Failed: #{message}")
  end
end)

IO.puts("\n🎯 SUMMARY:")
IO.puts("===========")
IO.puts("This example demonstrates:")
IO.puts("• New return format: {:ok, {type, value}} for GET operations")
IO.puts("• Bulk operations return: {:ok, [{oid, type, value}, ...]}")
IO.puts("• GET NEXT returns: {:ok, {next_oid, {type, value}}}")
IO.puts("• Type-aware value processing and formatting")
IO.puts("• Robust error handling patterns")
IO.puts("• Multi-device monitoring strategies")
IO.puts("\n🎉 Advanced example complete!")
IO.puts("\nNOTE: Replace device IPs and communities with your actual SNMP devices.")
