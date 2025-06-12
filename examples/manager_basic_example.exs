#!/usr/bin/env elixir

# Configure logger to be quiet for clean output
Logger.configure(level: :warn)

IO.puts("🎯 SNMP MANAGER BASIC OPERATIONS EXAMPLE")
IO.puts("=======================================")

# Example SNMP device (replace with your device's IP)
host = "192.168.1.1"

# Standard SNMP OIDs for demonstration
system_descr_oid = [1, 3, 6, 1, 2, 1, 1, 1, 0]  # sysDescr.0
system_uptime_oid = [1, 3, 6, 1, 2, 1, 1, 3, 0] # sysUpTime.0
system_name_oid = [1, 3, 6, 1, 2, 1, 1, 5, 0]   # sysName.0

IO.puts("\n📋 BASIC GET OPERATIONS:")
IO.puts("=======================")

# Example 1: Basic GET operation with new return format
IO.puts("\n1. System Description:")
case SnmpLib.Manager.get(host, system_descr_oid) do
  {:ok, {type, value}} ->
    IO.puts("   Type: #{inspect(type)}")
    IO.puts("   Value: #{inspect(value)}")
    IO.puts("   ✅ GET successful - received #{type} data")
  {:error, reason} ->
    IO.puts("   ❌ GET failed: #{inspect(reason)}")
    IO.puts("   (This is expected if no SNMP device at #{host})")
end

# Example 2: GET with string OID format
IO.puts("\n2. System Uptime (using string OID):")
case SnmpLib.Manager.get(host, "1.3.6.1.2.1.1.3.0") do
  {:ok, {type, value}} ->
    IO.puts("   Type: #{inspect(type)}")
    IO.puts("   Value: #{inspect(value)}")
    
    # Handle different uptime formats
    case type do
      :timeticks ->
        seconds = div(value, 100)
        days = div(seconds, 86400)
        hours = div(rem(seconds, 86400), 3600)
        minutes = div(rem(seconds, 3600), 60)
        IO.puts("   Uptime: #{days} days, #{hours} hours, #{minutes} minutes")
      _ ->
        IO.puts("   Raw uptime value: #{value}")
    end
  {:error, reason} ->
    IO.puts("   ❌ GET failed: #{inspect(reason)}")
end

# Example 3: GET with custom options
IO.puts("\n3. System Name (with custom community and timeout):")
case SnmpLib.Manager.get(host, system_name_oid, community: "public", timeout: 10_000) do
  {:ok, {type, value}} ->
    IO.puts("   Type: #{inspect(type)}")
    IO.puts("   Value: #{inspect(value)}")
    
    # Handle string values specifically
    if type == :octet_string do
      IO.puts("   System Name: \"#{value}\"")
    end
  {:error, reason} ->
    IO.puts("   ❌ GET failed: #{inspect(reason)}")
end

IO.puts("\n📊 BULK OPERATIONS:")
IO.puts("==================")

# Example 4: GET BULK operation with new return format
IO.puts("\n4. Interface Table Bulk Walk:")
interfaces_oid = [1, 3, 6, 1, 2, 1, 2, 2, 1, 2]  # ifDescr table

case SnmpLib.Manager.get_bulk(host, interfaces_oid, max_repetitions: 5) do
  {:ok, results} ->
    IO.puts("   ✅ BULK GET successful - received #{length(results)} results")
    
    # Each result is now {oid, type, value} format
    Enum.with_index(results, 1) |> Enum.each(fn {{oid, type, value}, index} ->
      IO.puts("   #{index}. OID: #{Enum.join(oid, ".")}")
      IO.puts("      Type: #{inspect(type)}")
      IO.puts("      Value: #{inspect(value)}")
    end)
  {:error, reason} ->
    IO.puts("   ❌ BULK GET failed: #{inspect(reason)}")
end

IO.puts("\n🔄 GET NEXT OPERATIONS:")
IO.puts("======================")

# Example 5: GET NEXT operation
IO.puts("\n5. Get Next from System Table:")
case SnmpLib.Manager.get_next(host, [1, 3, 6, 1, 2, 1, 1]) do
  {:ok, {next_oid, {type, value}}} ->
    IO.puts("   ✅ GET NEXT successful")
    IO.puts("   Next OID: #{Enum.join(next_oid, ".")}")
    IO.puts("   Type: #{inspect(type)}")
    IO.puts("   Value: #{inspect(value)}")
  {:error, reason} ->
    IO.puts("   ❌ GET NEXT failed: #{inspect(reason)}")
end

IO.puts("\n🔧 SET OPERATIONS:")
IO.puts("=================")

# Example 6: SET operation (be careful with this!)
IO.puts("\n6. Set System Contact (demonstration):")
contact_oid = [1, 3, 6, 1, 2, 1, 1, 4, 0]  # sysContact.0

# Note: This will likely fail on most devices due to read-only community
case SnmpLib.Manager.set(host, contact_oid, {:octet_string, "admin@example.com"}) do
  {:ok, :success} ->
    IO.puts("   ✅ SET successful")
  {:error, reason} ->
    IO.puts("   ❌ SET failed: #{inspect(reason)}")
    IO.puts("   (This is expected - most devices use read-only communities)")
end

IO.puts("\n📈 MULTIPLE OPERATIONS:")
IO.puts("======================")

# Example 7: Multiple GET operations
IO.puts("\n7. Get Multiple System Values:")
oids = [
  system_descr_oid,
  system_uptime_oid, 
  system_name_oid
]

case SnmpLib.Manager.get_multi(host, oids) do
  {:ok, results} ->
    IO.puts("   ✅ MULTI GET successful - received #{length(results)} results")
    
    # Each result is {oid, type, value} format
    Enum.each(results, fn {oid, type, value} ->
      oid_str = Enum.join(oid, ".")
      IO.puts("   • #{oid_str}: #{inspect(type)} = #{inspect(value)}")
    end)
  {:error, reason} ->
    IO.puts("   ❌ MULTI GET failed: #{inspect(reason)}")
end

IO.puts("\n✨ TYPE-AWARE PROCESSING:")
IO.puts("========================")

# Example 8: Processing different SNMP types
IO.puts("\n8. Type-aware value processing:")

sample_values = [
  {:octet_string, "Cisco IOS Software"},
  {:integer, 42},
  {:counter32, 1234567},
  {:gauge32, 85},
  {:timeticks, 12345600},
  {:ip_address, <<192, 168, 1, 1>>},
  {:object_identifier, [1, 3, 6, 1, 4, 1, 9]}
]

Enum.each(sample_values, fn {type, value} ->
  formatted = case type do
    :octet_string -> "\"#{value}\""
    :integer -> "#{value}"
    :counter32 -> "#{value} (counter)"
    :gauge32 -> "#{value}%"
    :timeticks -> 
      seconds = div(value, 100)
      "#{seconds} seconds (#{value} timeticks)"
    :ip_address -> 
      <<a, b, c, d>> = value
      "#{a}.#{b}.#{c}.#{d}"
    :object_identifier -> Enum.join(value, ".")
    _ -> inspect(value)
  end
  
  IO.puts("   #{type}: #{formatted}")
end)

IO.puts("\n🎉 Example complete!")
IO.puts("\nNOTE: Most operations will fail unless you have an SNMP-enabled device")
IO.puts("at #{host}. Replace the host variable with your device's IP address.")
