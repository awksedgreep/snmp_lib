defmodule SnmpLib.Utils do
  @moduledoc """
  Common utilities for SNMP operations including pretty printing, data formatting, 
  timing utilities, and validation functions.
  
  This module provides helpful utilities for debugging, logging, monitoring, and
  general SNMP data manipulation that are commonly needed across SNMP applications.
  
  ## Pretty Printing
  
  Format SNMP data structures for human-readable display in logs, CLI tools,
  and debugging output.
  
  ## Data Formatting  
  
  Convert between different representations of SNMP data, format numeric values,
  and handle common data transformations.
  
  ## Timing Utilities
  
  Measure and format timing information for SNMP operations, useful for
  performance monitoring and debugging.
  
  ## Validation
  
  Common validation functions for SNMP-related data.
  
  ## Usage Examples
  
  ### Pretty Printing
  
      # Format PDU for logging
      pdu = %{type: :get_request, request_id: 123, varbinds: [...]}
      Logger.info(SnmpLib.Utils.pretty_print_pdu(pdu))
      
      # Format individual values
      value = {:counter32, 12345}
      IO.puts(SnmpLib.Utils.pretty_print_value(value))
      
  ### Data Formatting
  
      # Format large numbers with separators
      SnmpLib.Utils.format_bytes(1048576)
      # => "1.0 MB"
      
      # Format hex strings for MAC addresses
      SnmpLib.Utils.format_hex(<<0x00, 0x1B, 0x21, 0x3C, 0x92, 0xEB>>)
      # => "00:1B:21:3C:92:EB"
      
  ### Timing
  
      # Time an operation
      {result, time_us} = SnmpLib.Utils.measure_request_time(fn ->
        SnmpLib.PDU.encode_message(pdu)
      end)
      
      formatted_time = SnmpLib.Utils.format_response_time(time_us)
  """
  
  require Logger
  
  @type oid :: [non_neg_integer()]
  @type snmp_value :: any()
  @type varbind :: {oid(), snmp_value()}
  @type varbinds :: [varbind()]
  @type pdu :: map()
  
  ## Pretty Printing Functions
  
  @doc """
  Pretty prints an SNMP PDU for human-readable display.
  
  Formats the PDU structure with proper indentation and readable field names,
  suitable for logging, debugging, or CLI display.
  
  ## Parameters
  
  - `pdu`: SNMP PDU map containing type, request_id, error_status, etc.
  
  ## Returns
  
  Formatted string representation of the PDU.
  
  ## Examples
  
      iex> pdu = %{type: :get_request, request_id: 123, varbinds: [{[1,3,6,1,2,1,1,1,0], :null}]}
      iex> result = SnmpLib.Utils.pretty_print_pdu(pdu)
      iex> String.contains?(result, "GET Request")
      true
  """
  @spec pretty_print_pdu(pdu()) :: String.t()
  def pretty_print_pdu(pdu) when is_map(pdu) do
    type_str = format_pdu_type(Map.get(pdu, :type, :unknown))
    request_id = Map.get(pdu, :request_id, 0)
    
    lines = [
      "#{type_str} (ID: #{request_id})"
    ]
    
    lines = add_error_info(lines, pdu)
    lines = add_bulk_info(lines, pdu)
    lines = add_varbinds(lines, Map.get(pdu, :varbinds, []))
    
    Enum.join(lines, "\n")
  end
  def pretty_print_pdu(_), do: "Invalid PDU"
  
  @doc """
  Pretty prints a list of varbinds for display.
  
  ## Examples
  
      iex> varbinds = [{[1,3,6,1,2,1,1,1,0], "Linux server"}]
      iex> result = SnmpLib.Utils.pretty_print_varbinds(varbinds)
      iex> String.contains?(result, "1.3.6.1.2.1.1.1.0")
      true
  """
  @spec pretty_print_varbinds(varbinds()) :: String.t()
  def pretty_print_varbinds(varbinds) when is_list(varbinds) do
    if length(varbinds) == 0 do
      "  (no varbinds)"
    else
      varbinds
      |> Enum.with_index(1)
      |> Enum.map(fn {{oid, value}, index} ->
        "  #{index}. #{pretty_print_oid(oid)} = #{pretty_print_value(value)}"
      end)
      |> Enum.join("\n")
    end
  end
  def pretty_print_varbinds(_), do: "Invalid varbinds"
  
  @doc """
  Pretty prints an OID for display.
  
  ## Examples
  
      iex> SnmpLib.Utils.pretty_print_oid([1,3,6,1,2,1,1,1,0])
      "1.3.6.1.2.1.1.1.0"
      
      iex> SnmpLib.Utils.pretty_print_oid("1.3.6.1.2.1.1.1.0")
      "1.3.6.1.2.1.1.1.0"
  """
  @spec pretty_print_oid(oid() | String.t()) :: String.t()
  def pretty_print_oid(oid) when is_list(oid) do
    Enum.join(oid, ".")
  end
  def pretty_print_oid(oid) when is_binary(oid) do
    oid
  end
  def pretty_print_oid(_), do: "invalid-oid"
  
  @doc """
  Pretty prints an SNMP value for display.
  
  Formats SNMP values with appropriate type information and human-readable
  representations.
  
  ## Examples
  
      iex> SnmpLib.Utils.pretty_print_value({:counter32, 12345})
      "Counter32: 12,345"
      
      iex> SnmpLib.Utils.pretty_print_value({:octet_string, "Hello"})
      "OCTET STRING: \\"Hello\\""
      
      iex> SnmpLib.Utils.pretty_print_value(:null)
      "NULL"
  """
  @spec pretty_print_value(snmp_value()) :: String.t()
  def pretty_print_value(:null), do: "NULL"
  def pretty_print_value({:integer, value}), do: "INTEGER: #{value}"
  def pretty_print_value({:octet_string, value}) when is_binary(value) do
    if String.printable?(value) do
      ~s(OCTET STRING: "#{value}")
    else
      hex_str = format_hex(value, " ")
      "OCTET STRING: #{hex_str}"
    end
  end
  def pretty_print_value({:object_identifier, oid}), do: "OID: #{pretty_print_oid(oid)}"
  def pretty_print_value({:counter32, value}), do: "Counter32: #{format_number(value)}"
  def pretty_print_value({:gauge32, value}), do: "Gauge32: #{format_number(value)}"
  def pretty_print_value({:timeticks, value}), do: "TimeTicks: #{format_timeticks(value)}"
  def pretty_print_value({:counter64, value}), do: "Counter64: #{format_number(value)}"
  def pretty_print_value({:ip_address, <<a, b, c, d>>}), do: "IpAddress: #{a}.#{b}.#{c}.#{d}"
  def pretty_print_value({:opaque, data}), do: "Opaque: #{format_hex(data, " ")}"
  def pretty_print_value({:no_such_object, _}), do: "noSuchObject"
  def pretty_print_value({:no_such_instance, _}), do: "noSuchInstance"
  def pretty_print_value({:end_of_mib_view, _}), do: "endOfMibView"
  def pretty_print_value(value) when is_integer(value), do: "INTEGER: #{value}"
  def pretty_print_value(value) when is_binary(value) do
    if String.printable?(value) do
      ~s("#{value}")
    else
      format_hex(value, " ")
    end
  end
  def pretty_print_value(value), do: "#{inspect(value)}"
  
  ## Data Formatting Functions
  
  @doc """
  Formats byte counts in human-readable units.
  
  ## Examples
  
      iex> SnmpLib.Utils.format_bytes(1024)
      "1.0 KB"
      
      iex> SnmpLib.Utils.format_bytes(1048576)
      "1.0 MB"
      
      iex> SnmpLib.Utils.format_bytes(512)
      "512 B"
  """
  @spec format_bytes(non_neg_integer()) :: String.t()
  def format_bytes(bytes) when is_integer(bytes) and bytes >= 0 do
    cond do
      bytes >= 1_073_741_824 -> "#{Float.round(bytes / 1_073_741_824, 1)} GB"
      bytes >= 1_048_576 -> "#{Float.round(bytes / 1_048_576, 1)} MB"
      bytes >= 1_024 -> "#{Float.round(bytes / 1_024, 1)} KB"
      true -> "#{bytes} B"
    end
  end
  def format_bytes(_), do: "Invalid byte count"
  
  @doc """
  Formats rates with units.
  
  ## Examples
  
      iex> SnmpLib.Utils.format_rate(1500, "bps")
      "1.5 Kbps"
      
      iex> SnmpLib.Utils.format_rate(45, "pps")
      "45 pps"
  """
  @spec format_rate(number(), String.t()) :: String.t()
  def format_rate(value, unit) when is_number(value) and is_binary(unit) do
    cond do
      value >= 1_000_000_000 -> "#{Float.round(value / 1_000_000_000, 1)} G#{unit}"
      value >= 1_000_000 -> "#{Float.round(value / 1_000_000, 1)} M#{unit}"
      value >= 1_000 -> "#{Float.round(value / 1_000, 1)} K#{unit}"
      true -> "#{value} #{unit}"
    end
  end
  def format_rate(_, _), do: "Invalid rate"
  
  @doc """
  Truncates a string to maximum length with ellipsis.
  
  ## Examples
  
      iex> SnmpLib.Utils.truncate_string("Hello, World!", 10)
      "Hello, ..."
      
      iex> SnmpLib.Utils.truncate_string("Short", 10)
      "Short"
  """
  @spec truncate_string(String.t(), pos_integer()) :: String.t()
  def truncate_string(string, max_length) when is_binary(string) and is_integer(max_length) and max_length > 3 do
    if String.length(string) <= max_length do
      string
    else
      String.slice(string, 0, max_length - 3) <> "..."
    end
  end
  def truncate_string(string, _) when is_binary(string), do: string
  def truncate_string(_, _), do: ""
  
  @doc """
  Formats binary data as hexadecimal string.
  
  ## Parameters
  
  - `data`: Binary data to format
  - `separator`: String to use between hex bytes (default: ":")
  
  ## Examples
  
      iex> SnmpLib.Utils.format_hex(<<0x00, 0x1B, 0x21>>)
      "00:1B:21"
      
      iex> SnmpLib.Utils.format_hex(<<0xDE, 0xAD, 0xBE, 0xEF>>, " ")
      "DE AD BE EF"
  """
  @spec format_hex(binary(), String.t()) :: String.t()
  def format_hex(data, separator \\ ":") when is_binary(data) and is_binary(separator) do
    data
    |> :binary.bin_to_list()
    |> Enum.map(&String.upcase(Integer.to_string(&1, 16) |> String.pad_leading(2, "0")))
    |> Enum.join(separator)
  end
  def format_hex(data, _) when not is_binary(data), do: "Invalid binary data"
  def format_hex(_, separator) when not is_binary(separator), do: "Invalid binary data"
  
  @doc """
  Formats large numbers with thousand separators.
  
  ## Examples
  
      iex> SnmpLib.Utils.format_number(1234567)
      "1,234,567"
      
      iex> SnmpLib.Utils.format_number(42)
      "42"
  """
  @spec format_number(integer()) :: String.t()
  def format_number(number) when is_integer(number) do
    number
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end
  def format_number(_), do: "Invalid number"
  
  ## Timing Utilities
  
  @doc """
  Measures the execution time of a function in microseconds.
  
  ## Parameters
  
  - `fun`: Function to execute and time
  
  ## Returns
  
  Tuple of `{result, time_microseconds}` where result is the function's
  return value and time_microseconds is the execution time.
  
  ## Examples
  
      iex> {result, time} = SnmpLib.Utils.measure_request_time(fn -> :timer.sleep(100); :ok end)
      iex> result
      :ok
      iex> time > 100_000
      true
  """
  @spec measure_request_time(function()) :: {any(), non_neg_integer()}
  def measure_request_time(fun) when is_function(fun) do
    start_time = System.monotonic_time(:microsecond)
    result = fun.()
    end_time = System.monotonic_time(:microsecond)
    {result, end_time - start_time}
  end
  
  @doc """
  Formats response time in human-readable units.
  
  ## Parameters
  
  - `microseconds`: Time in microseconds
  
  ## Examples
  
      iex> SnmpLib.Utils.format_response_time(1500)
      "1.50ms"
      
      iex> SnmpLib.Utils.format_response_time(2_500_000)
      "2.50s"
      
      iex> SnmpLib.Utils.format_response_time(500)
      "500μs"
  """
  @spec format_response_time(non_neg_integer()) :: String.t()
  def format_response_time(microseconds) when is_integer(microseconds) and microseconds >= 0 do
    cond do
      microseconds >= 1_000_000 -> "#{:erlang.float_to_binary(microseconds / 1_000_000, [{:decimals, 2}])}s"
      microseconds >= 1_000 -> "#{:erlang.float_to_binary(microseconds / 1_000, [{:decimals, 2}])}ms"
      true -> "#{microseconds}μs"
    end
  end
  def format_response_time(_), do: "Invalid time"
  
  ## Validation Functions
  
  @doc """
  Validates an SNMP version number.
  
  ## Examples
  
      iex> SnmpLib.Utils.valid_snmp_version?(1)
      true
      
      iex> SnmpLib.Utils.valid_snmp_version?(5)
      false
  """
  @spec valid_snmp_version?(any()) :: boolean()
  def valid_snmp_version?(version) when version in [0, 1, 2, 3], do: true
  def valid_snmp_version?(:v1), do: true
  def valid_snmp_version?(:v2c), do: true
  def valid_snmp_version?(:v3), do: true
  def valid_snmp_version?(_), do: false
  
  @doc """
  Validates an SNMP community string.
  
  Community strings should be non-empty and contain only printable characters.
  
  ## Examples
  
      iex> SnmpLib.Utils.valid_community_string?("public")
      true
      
      iex> SnmpLib.Utils.valid_community_string?("")
      false
  """
  @spec valid_community_string?(any()) :: boolean()
  def valid_community_string?(community) when is_binary(community) do
    byte_size(community) > 0 and String.printable?(community)
  end
  def valid_community_string?(_), do: false
  
  @doc """
  Sanitizes a community string for safe logging.
  
  Replaces community strings with asterisks to prevent credential leakage
  in logs while preserving length information.
  
  ## Examples
  
      iex> SnmpLib.Utils.sanitize_community("secret123")
      "*********"
      
      iex> SnmpLib.Utils.sanitize_community("")
      "<empty>"
  """
  @spec sanitize_community(String.t()) :: String.t()
  def sanitize_community(community) when is_binary(community) do
    case byte_size(community) do
      0 -> "<empty>"
      size -> String.duplicate("*", size)
    end
  end
  def sanitize_community(_), do: "<invalid>"
  
  ## Private Helper Functions
  
  defp format_pdu_type(:get_request), do: "GET Request"
  defp format_pdu_type(:get_next_request), do: "GET-NEXT Request"
  defp format_pdu_type(:get_bulk_request), do: "GET-BULK Request"
  defp format_pdu_type(:set_request), do: "SET Request"
  defp format_pdu_type(:get_response), do: "Response"
  defp format_pdu_type(:trap), do: "Trap"
  defp format_pdu_type(:inform_request), do: "Inform Request"
  defp format_pdu_type(:snmpv2_trap), do: "SNMPv2 Trap"
  defp format_pdu_type(:report), do: "Report"
  defp format_pdu_type(type), do: "#{type}"
  
  defp add_error_info(lines, pdu) do
    error_status = Map.get(pdu, :error_status, 0)
    error_index = Map.get(pdu, :error_index, 0)
    
    if error_status != 0 do
      error_name = if function_exported?(SnmpLib.Error, :error_name, 1) do
        SnmpLib.Error.error_name(error_status)
      else
        "error_#{error_status}"
      end
      
      lines ++ ["  Error: #{error_name} (#{error_status}) at index #{error_index}"]
    else
      lines
    end
  end
  
  defp add_bulk_info(lines, pdu) do
    case Map.get(pdu, :type) do
      :get_bulk_request ->
        non_repeaters = Map.get(pdu, :non_repeaters, 0)
        max_repetitions = Map.get(pdu, :max_repetitions, 0)
        lines ++ ["  Non-repeaters: #{non_repeaters}, Max-repetitions: #{max_repetitions}"]
      _ ->
        lines
    end
  end
  
  defp add_varbinds(lines, varbinds) do
    varbind_str = pretty_print_varbinds(varbinds)
    lines ++ ["Varbinds:", varbind_str]
  end
  
  defp format_timeticks(ticks) when is_integer(ticks) do
    # Convert centiseconds to readable time format
    total_seconds = div(ticks, 100)
    days = div(total_seconds, 86400)
    hours = div(rem(total_seconds, 86400), 3600)
    minutes = div(rem(total_seconds, 3600), 60)
    seconds = rem(total_seconds, 60)
    
    time_parts = []
    time_parts = if days > 0, do: time_parts ++ ["#{days}d"], else: time_parts
    time_parts = if hours > 0, do: time_parts ++ ["#{hours}h"], else: time_parts
    time_parts = if minutes > 0, do: time_parts ++ ["#{minutes}m"], else: time_parts
    time_parts = if seconds > 0 or time_parts == [], do: time_parts ++ ["#{seconds}s"], else: time_parts
    
    "#{format_number(ticks)} (#{Enum.join(time_parts, " ")})"
  end
  defp format_timeticks(_), do: "Invalid timeticks"
end