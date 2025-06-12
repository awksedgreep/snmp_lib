#!/usr/bin/env elixir

# Configure logger to be quiet for clean output
Logger.configure(level: :warn)

IO.puts("🔧 SNMP TYPE HANDLING AND ENCODING EXAMPLE")
IO.puts("==========================================")

IO.puts("\n📋 SNMP TYPE SYSTEM:")
IO.puts("===================")

# Demonstrate all SNMP types supported by the library
snmp_types = [
  # Basic ASN.1 types
  {:integer, 42, "Standard integer value"},
  {:octet_string, "Hello SNMP", "Text string data"},
  {:null, nil, "Null/empty value"},
  {:object_identifier, [1, 3, 6, 1, 2, 1, 1, 1, 0], "OID as integer list"},
  
  # SNMP application types (RFC 1155)
  {:counter32, 1234567, "32-bit counter (monotonic)"},
  {:gauge32, 85, "32-bit gauge (current value)"},
  {:timeticks, 12345600, "Time in 1/100th seconds"},
  {:counter64, 9876543210, "64-bit counter"},
  {:ip_address, <<192, 168, 1, 1>>, "IPv4 address as 4 bytes"},
  {:opaque, <<0x01, 0x02, 0x03>>, "Opaque binary data"},
  
  # SNMPv2c exception values
  {:no_such_object, nil, "Object doesn't exist"},
  {:no_such_instance, nil, "Instance doesn't exist"},
  {:end_of_mib_view, nil, "End of MIB tree"}
]

IO.puts("\n1. Supported SNMP Types:")
Enum.with_index(snmp_types, 1) |> Enum.each(fn {{type, value, description}, index} ->
  IO.puts("   #{index}. #{type}")
  IO.puts("      Value: #{inspect(value)}")
  IO.puts("      Description: #{description}")
  IO.puts("")
end)

IO.puts("\n🔄 ENCODING AND DECODING:")
IO.puts("========================")

# Example 2: Demonstrate encoding/decoding with type preservation
IO.puts("\n2. Type Preservation Through Encode/Decode Cycle:")

# Create a sample PDU with various types
sample_varbinds = [
  {[1, 3, 6, 1, 2, 1, 1, 1, 0], :octet_string, "Cisco IOS Software"},
  {[1, 3, 6, 1, 2, 1, 1, 3, 0], :timeticks, 12345600},
  {[1, 3, 6, 1, 2, 1, 2, 2, 1, 10, 1], :counter32, 987654321},
  {[1, 3, 6, 1, 2, 1, 2, 2, 1, 5, 1], :gauge32, 100000000},
  {[1, 3, 6, 1, 2, 1, 1, 2, 0], :object_identifier, [1, 3, 6, 1, 4, 1, 9]}
]

# Build a GET response PDU
pdu = %{
  type: :get_response,
  request_id: 12345,
  error_status: 0,
  error_index: 0,
  varbinds: sample_varbinds
}

message = %{
  version: 1,  # SNMPv2c
  community: "public",
  pdu: pdu
}

IO.puts("Original varbinds:")
Enum.with_index(sample_varbinds, 1) |> Enum.each(fn {{oid, type, value}, index} ->
  oid_str = Enum.join(oid, ".")
  IO.puts("   #{index}. #{oid_str}: #{inspect(value)} (#{type})")
end)

# Encode the message
case SnmpLib.PDU.encode_message(message) do
  {:ok, encoded_data} ->
    IO.puts("\n✅ Encoding successful: #{byte_size(encoded_data)} bytes")
    
    # Decode it back
    case SnmpLib.PDU.decode_message(encoded_data) do
      {:ok, decoded_message} ->
        IO.puts("✅ Decoding successful")
        
        decoded_varbinds = decoded_message.pdu.varbinds
        IO.puts("\nDecoded varbinds (type preservation check):")
        
        Enum.with_index(decoded_varbinds, 1) |> Enum.each(fn {{oid, type, value}, index} ->
          oid_str = Enum.join(oid, ".")
          IO.puts("   #{index}. #{oid_str}: #{inspect(value)} (#{type})")
        end)
        
        # Verify type preservation
        types_match = Enum.zip(sample_varbinds, decoded_varbinds)
        |> Enum.all?(fn {{_oid1, type1, _val1}, {_oid2, type2, _val2}} ->
          type1 == type2
        end)
        
        if types_match do
          IO.puts("\n🎉 Type preservation: PERFECT - All types preserved!")
        else
          IO.puts("\n⚠️  Type preservation: Some types were lost or changed")
        end
        
      {:error, reason} ->
        IO.puts("❌ Decoding failed: #{inspect(reason)}")
    end
    
  {:error, reason} ->
    IO.puts("❌ Encoding failed: #{inspect(reason)}")
end

IO.puts("\n🎯 TYPE-AWARE VALUE FORMATTING:")
IO.puts("===============================")

# Example 3: Smart formatting based on SNMP type
IO.puts("\n3. Type-Aware Value Formatting:")

format_snmp_value = fn type, value ->
  case type do
    :octet_string ->
      # Handle both string and binary data
      if String.printable?(to_string(value)) do
        "\"#{value}\""
      else
        "Binary: #{inspect(value)}"
      end
    
    :integer ->
      "#{value}"
    
    :counter32 ->
      # Format large counters with units
      cond do
        value > 1_000_000_000 -> "#{Float.round(value / 1_000_000_000, 2)}G"
        value > 1_000_000 -> "#{Float.round(value / 1_000_000, 2)}M"
        value > 1_000 -> "#{Float.round(value / 1_000, 2)}K"
        true -> "#{value}"
      end
    
    :gauge32 ->
      "#{value} (current)"
    
    :timeticks ->
      # Convert to human readable time
      seconds = div(value, 100)
      days = div(seconds, 86400)
      hours = div(rem(seconds, 86400), 3600)
      minutes = div(rem(seconds, 3600), 60)
      secs = rem(seconds, 60)
      
      if days > 0 do
        "#{days}d #{hours}h #{minutes}m #{secs}s"
      else
        "#{hours}h #{minutes}m #{secs}s"
      end
    
    :counter64 ->
      # Format very large counters
      cond do
        value > 1_000_000_000_000 -> "#{Float.round(value / 1_000_000_000_000, 2)}T"
        value > 1_000_000_000 -> "#{Float.round(value / 1_000_000_000, 2)}G"
        value > 1_000_000 -> "#{Float.round(value / 1_000_000, 2)}M"
        true -> "#{value}"
      end
    
    :ip_address ->
      # Convert 4-byte binary to dotted decimal
      case value do
        <<a, b, c, d>> -> "#{a}.#{b}.#{c}.#{d}"
        _ -> inspect(value)
      end
    
    :object_identifier ->
      # Convert OID list to dotted string
      if is_list(value) do
        Enum.join(value, ".")
      else
        inspect(value)
      end
    
    :opaque ->
      "Opaque[#{byte_size(value)} bytes]: #{Base.encode16(value)}"
    
    :no_such_object ->
      "No Such Object"
    
    :no_such_instance ->
      "No Such Instance"
    
    :end_of_mib_view ->
      "End of MIB View"
    
    :null ->
      "NULL"
    
    _ ->
      "#{inspect(value)} (#{type})"
  end
end

# Test formatting with sample data
sample_formatted_data = [
  {:octet_string, "Cisco Catalyst 3560", "System description"},
  {:timeticks, 432000000, "System uptime"},
  {:counter32, 2147483647, "Interface bytes in"},
  {:gauge32, 95, "CPU utilization percentage"},
  {:ip_address, <<10, 0, 0, 1>>, "Management IP"},
  {:object_identifier, [1, 3, 6, 1, 4, 1, 9, 1, 45], "System object ID"},
  {:counter64, 18446744073709551615, "High capacity counter"},
  {:opaque, <<0xDE, 0xAD, 0xBE, 0xEF>>, "Vendor specific data"},
  {:no_such_object, nil, "Missing object"},
  {:null, nil, "Empty value"}
]

Enum.with_index(sample_formatted_data, 1) |> Enum.each(fn {{type, value, description}, index} ->
  formatted = format_snmp_value.(type, value)
  IO.puts("   #{index}. #{description}")
  IO.puts("      Raw: #{inspect(value)} (#{type})")
  IO.puts("      Formatted: #{formatted}")
  IO.puts("")
end)

IO.puts("\n🔍 TYPE DETECTION AND VALIDATION:")
IO.puts("=================================")

# Example 4: Type detection and validation
IO.puts("\n4. Automatic Type Detection:")

detect_snmp_type = fn value ->
  case value do
    v when is_integer(v) and v >= 0 and v <= 2147483647 -> :integer
    v when is_integer(v) and v > 2147483647 -> :counter64
    v when is_binary(v) -> :octet_string
    v when is_list(v) -> 
      if Enum.all?(v, &is_integer/1), do: :object_identifier, else: :unknown
    nil -> :null
    <<_, _, _, _>> -> :ip_address  # 4-byte binary could be IP
    _ -> :unknown
  end
end

test_values = [
  42,
  "Hello World",
  [1, 3, 6, 1, 2, 1, 1, 1, 0],
  nil,
  <<192, 168, 1, 1>>,
  9876543210,
  "Multi-line\nString\nData"
]

IO.puts("Auto-detected types:")
Enum.with_index(test_values, 1) |> Enum.each(fn {value, index} ->
  detected_type = detect_snmp_type.(value)
  IO.puts("   #{index}. #{inspect(value)} → #{detected_type}")
end)

IO.puts("\n🎉 TYPE HANDLING EXAMPLE COMPLETE!")
IO.puts("\n📚 Key Takeaways:")
IO.puts("• SNMP types preserve semantic meaning of data")
IO.puts("• Type information is preserved through encode/decode cycles")
IO.puts("• Different types require different formatting approaches")
IO.puts("• Type-aware processing enables better data presentation")
IO.puts("• The library supports all standard SNMP types including SNMPv2c exceptions")
IO.puts("\n✨ Use this knowledge to build robust SNMP applications!")
