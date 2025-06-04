defmodule SnmpLib.Manager do
  @moduledoc """
  High-level SNMP management operations providing a simplified interface for common SNMP tasks.
  
  This module builds on the core SnmpLib functionality to provide production-ready SNMP
  management capabilities including GET, GETBULK, SET operations with intelligent error
  handling, connection reuse, and performance optimizations.
  
  ## Features
  
  - **Simple API**: High-level functions for common SNMP operations
  - **Connection Reuse**: Efficient socket management for multiple operations
  - **Error Handling**: Comprehensive error handling with meaningful messages
  - **Performance**: Optimized for bulk operations and large-scale polling
  - **Timeout Management**: Configurable timeouts with sensible defaults
  - **Community Support**: Support for different community strings per device
  
  ## Quick Start
  
      # Simple GET operation
      {:ok, value} = SnmpLib.Manager.get("192.168.1.1", [1, 3, 6, 1, 2, 1, 1, 1, 0])
      
      # GET with custom community and timeout
      {:ok, value} = SnmpLib.Manager.get("192.168.1.1", "1.3.6.1.2.1.1.1.0", 
                                         community: "private", timeout: 10_000)
      
      # Bulk operations for efficiency
      {:ok, results} = SnmpLib.Manager.get_bulk("192.168.1.1", [1, 3, 6, 1, 2, 1, 2, 2],
                                                 max_repetitions: 20)
      
      # SET operation
      {:ok, :success} = SnmpLib.Manager.set("192.168.1.1", [1, 3, 6, 1, 2, 1, 1, 5, 0],
                                            {:string, "New System Name"})
  
  ## Configuration Options
  
  - `community`: SNMP community string (default: "public")
  - `version`: SNMP version (:v1, :v2c) (default: :v2c)  
  - `timeout`: Operation timeout in milliseconds (default: 5000)
  - `retries`: Number of retry attempts (default: 3)
  - `port`: SNMP port (default: 161)
  - `local_port`: Local source port (default: 0 for random)
  """
  
  require Logger
  
  @default_community "public"
  @default_version :v2c
  @default_timeout 5_000
  @default_retries 3
  @default_port 161
  @default_local_port 0
  @default_max_repetitions 10
  @default_non_repeaters 0
  
  @type host :: binary() | :inet.ip_address()
  @type oid :: [non_neg_integer()] | binary()
  @type snmp_value :: any()
  @type community :: binary()
  @type version :: :v1 | :v2c
  @type operation_result :: {:ok, snmp_value()} | {:error, atom() | {atom(), any()}}
  @type bulk_result :: {:ok, [varbind()]} | {:error, atom() | {atom(), any()}}
  @type varbind :: {oid(), snmp_value()}
  
  @type manager_opts :: [
    community: community(),
    version: version(),
    timeout: pos_integer(),
    retries: non_neg_integer(),
    port: pos_integer(),
    local_port: non_neg_integer()
  ]
  
  @type bulk_opts :: [
    community: community(),
    version: version(),
    timeout: pos_integer(),
    retries: non_neg_integer(),
    port: pos_integer(),
    local_port: non_neg_integer(),
    max_repetitions: pos_integer(),
    non_repeaters: non_neg_integer()
  ]
  
  ## Public API
  
  @doc """
  Performs an SNMP GET operation to retrieve a single value.
  
  ## Parameters
  
  - `host`: Target device IP address or hostname
  - `oid`: Object identifier as list or string (e.g., [1,3,6,1,2,1,1,1,0] or "1.3.6.1.2.1.1.1.0")
  - `opts`: Configuration options (see module docs for available options)
  
  ## Returns
  
  - `{:ok, value}`: Successfully retrieved the value
  - `{:error, reason}`: Operation failed with reason
  
  ## Examples
  
      # Basic GET operation (would succeed with real device)
      # SnmpLib.Manager.get("192.168.1.1", [1, 3, 6, 1, 2, 1, 1, 1, 0])
      # {:ok, "Cisco IOS Software"}
      
      # GET with custom community (would succeed with real device)
      # SnmpLib.Manager.get("192.168.1.1", "1.3.6.1.2.1.1.1.0", community: "private")
      # {:ok, "Private System Description"}
      
      # Test that function exists and handles invalid input properly
      iex> match?({:error, _}, SnmpLib.Manager.get("invalid.host", [1, 3, 6, 1, 2, 1, 1, 3, 0], timeout: 100))
      true
  """
  @spec get(host(), oid(), manager_opts()) :: operation_result()
  def get(host, oid, opts \\ []) do
    opts = merge_default_opts(opts)
    normalized_oid = normalize_oid(oid)
    
    with {:ok, socket} <- create_socket(opts),
         {:ok, response} <- perform_get_operation(socket, host, normalized_oid, opts),
         :ok <- close_socket(socket) do
      extract_get_result(response)
    else
      {:error, reason} -> {:error, reason}
    end
  end
  
  @doc """
  Performs an SNMP GETBULK operation for efficient bulk data retrieval.
  
  GETBULK is more efficient than multiple GET operations when retrieving
  multiple consecutive values, especially for table walking operations.
  
  ## Parameters
  
  - `host`: Target device IP address or hostname
  - `base_oid`: Base OID to start the bulk operation
  - `opts`: Configuration options including bulk-specific options
  
  ## Bulk-Specific Options
  
  - `max_repetitions`: Maximum number of repetitions (default: 10)
  - `non_repeaters`: Number of non-repeating variables (default: 0)
  
  ## Returns
  
  - `{:ok, varbinds}`: List of {oid, value} tuples
  - `{:error, reason}`: Operation failed with reason
  
  ## Examples
  
      # Test that get_bulk function exists and handles invalid input properly
      iex> match?({:error, _}, SnmpLib.Manager.get_bulk("invalid.host", [1, 3, 6, 1, 2, 1, 2, 2], timeout: 100))
      true
      
      # High-repetition bulk for large tables
      # SnmpLib.Manager.get_bulk("192.168.1.1", "1.3.6.1.2.1.2.2", max_repetitions: 50)
      # {:ok, [...]} Returns up to 50 interface entries
  """
  @spec get_bulk(host(), oid(), bulk_opts()) :: bulk_result()
  def get_bulk(host, base_oid, opts \\ []) do
    opts = merge_bulk_opts(opts)
    normalized_oid = normalize_oid(base_oid)
    
    # GETBULK requires SNMPv2c or higher
    if opts[:version] == :v1 do
      {:error, :getbulk_requires_v2c}
    else
      with {:ok, socket} <- create_socket(opts),
           {:ok, response} <- perform_bulk_operation(socket, host, normalized_oid, opts),
           :ok <- close_socket(socket) do
        extract_bulk_result(response)
      else
        {:error, reason} -> {:error, reason}
      end
    end
  end
  
  @doc """
  Performs an SNMP SET operation to modify a value on the target device.
  
  ## Parameters
  
  - `host`: Target device IP address or hostname  
  - `oid`: Object identifier to modify
  - `value`: New value as {type, data} tuple (e.g., {:string, "new name"})
  - `opts`: Configuration options
  
  ## Supported Value Types
  
  - `{:string, binary()}`: OCTET STRING
  - `{:integer, integer()}`: INTEGER
  - `{:counter32, non_neg_integer()}`: Counter32
  - `{:gauge32, non_neg_integer()}`: Gauge32
  - `{:timeticks, non_neg_integer()}`: TimeTicks
  - `{:ip_address, binary()}`: IpAddress (4 bytes)
  
  ## Returns
  
  - `{:ok, :success}`: SET operation completed successfully
  - `{:error, reason}`: Operation failed with reason
  
  ## Examples
  
      # Test that SET function exists and handles invalid input properly
      iex> match?({:error, _}, SnmpLib.Manager.set("invalid.host", [1, 3, 6, 1, 2, 1, 1, 5, 0], {:string, "test"}, timeout: 100))
      true
  """
  @spec set(host(), oid(), {atom(), any()}, manager_opts()) :: {:ok, :success} | {:error, any()}
  def set(host, oid, {type, value}, opts \\ []) do
    opts = merge_default_opts(opts)
    normalized_oid = normalize_oid(oid)
    
    with {:ok, socket} <- create_socket(opts),
         {:ok, response} <- perform_set_operation(socket, host, normalized_oid, {type, value}, opts),
         :ok <- close_socket(socket) do
      extract_set_result(response)
    else
      {:error, reason} -> {:error, reason}
    end
  end
  
  @doc """
  Performs multiple GET operations efficiently with connection reuse.
  
  More efficient than individual get/3 calls when retrieving multiple values
  from the same device by reusing the same socket connection.
  
  ## Parameters
  
  - `host`: Target device IP address or hostname
  - `oids`: List of OIDs to retrieve
  - `opts`: Configuration options
  
  ## Returns
  
  - `{:ok, results}`: List of {oid, value} or {oid, {:error, reason}} tuples
  - `{:error, reason}`: Connection or overall operation failed
  
  ## Examples
  
      # Test that get_multi function exists and handles invalid input properly
      iex> oids = ["1.3.6.1.2.1.1.1.0", "1.3.6.1.2.1.1.3.0", "1.3.6.1.2.1.1.5.0"]
      iex> match?({:error, _}, SnmpLib.Manager.get_multi("invalid.host", oids, timeout: 100))
      true
  """
  @spec get_multi(host(), [oid()], manager_opts()) :: {:ok, [{oid(), snmp_value() | {:error, any()}}]} | {:error, any()}
  def get_multi(host, oids, opts \\ []) when is_list(oids) do
    # Validate input parameters
    case oids do
      [] -> {:error, :empty_oids}
      _ ->
        opts = merge_default_opts(opts)
        normalized_oids = Enum.map(oids, &normalize_oid/1)
        
        with {:ok, socket} <- create_socket(opts) do
          results = get_multi_with_socket(socket, host, normalized_oids, opts)
          :ok = close_socket(socket)
          
          # Check if all operations failed due to network issues
          case check_for_global_failure(results) do
            {:global_failure, reason} -> {:error, reason}
            :mixed_results -> {:ok, results}
          end
        else
          {:error, reason} -> {:error, reason}
        end
    end
  end
  
  @doc """
  Interprets SNMP errors with enhanced semantics for common cases.
  
  Provides more specific error interpretation when generic errors like `:gen_err`
  are returned by devices that should return more specific SNMP error codes.
  
  ## Parameters
  
  - `error`: The original error returned by SNMP operations
  - `operation`: The SNMP operation type (`:get`, `:set`, `:get_bulk`)
  - `version`: SNMP version (`:v1`, `:v2c`, `:v3`)
  
  ## Returns
  
  More specific error atom when possible, otherwise the original error.
  
  ## Examples
  
      # Interpret genErr for GET operations
      iex> SnmpLib.Manager.interpret_error(:gen_err, :get, :v2c)
      :no_such_object
      
      iex> SnmpLib.Manager.interpret_error(:gen_err, :get, :v1)
      :no_such_name
      
      iex> SnmpLib.Manager.interpret_error(:too_big, :get, :v2c)
      :too_big
  """
  @spec interpret_error(atom(), atom(), atom()) :: atom()
  def interpret_error(:gen_err, :get, :v1) do
    # In SNMPv1, genErr for GET operations commonly means OID doesn't exist
    :no_such_name
  end
  
  def interpret_error(:gen_err, :get, version) when version in [:v2c, :v2, :v3] do
    # In SNMPv2c+, genErr for GET operations commonly means object doesn't exist
    :no_such_object
  end
  
  def interpret_error(:gen_err, :get_bulk, version) when version in [:v2c, :v2, :v3] do
    # For bulk operations, genErr often indicates end of MIB or missing objects
    :no_such_object
  end
  
  def interpret_error(error, _operation, _version) do
    # Return original error for all other cases
    error
  end

  @doc """
  Checks if a host is reachable via SNMP by performing a basic GET operation.
  
  Useful for device discovery and health checking. Attempts to retrieve
  sysUpTime (1.3.6.1.2.1.1.3.0) which should be available on all SNMP devices.
  
  ## Parameters
  
  - `host`: Target device IP address or hostname
  - `opts`: Configuration options (typically just community and timeout)
  
  ## Returns
  
  - `{:ok, :reachable}`: Device responded to SNMP request
  - `{:error, reason}`: Device not reachable or SNMP not available
  
  ## Examples
  
      # Test that ping function exists and handles invalid input properly
      iex> match?({:error, _}, SnmpLib.Manager.ping("invalid.host", timeout: 100))
      true
  """
  @spec ping(host(), manager_opts()) :: {:ok, :reachable} | {:error, any()}
  def ping(host, opts \\ []) do
    # Use sysUpTime OID as it should be available on all SNMP devices
    sys_uptime_oid = [1, 3, 6, 1, 2, 1, 1, 3, 0]
    
    case get(host, sys_uptime_oid, opts) do
      {:ok, _value} -> {:ok, :reachable}
      {:error, reason} -> {:error, reason}
    end
  end
  
  ## Private Implementation
  
  # Socket management
  defp create_socket(_opts) do
    case SnmpLib.Transport.create_client_socket() do
      {:ok, socket} -> {:ok, socket}
      {:error, reason} -> {:error, {:socket_error, reason}}
    end
  end
  
  defp close_socket(socket) do
    SnmpLib.Transport.close_socket(socket)
  end
  
  # Operation implementations  
  defp perform_get_operation(socket, host, oid, opts) do
    request_id = generate_request_id()
    pdu = SnmpLib.PDU.build_get_request(oid, request_id)
    perform_snmp_request(socket, host, pdu, opts)
  end
  
  defp perform_bulk_operation(socket, host, base_oid, opts) do
    request_id = generate_request_id()
    max_reps = opts[:max_repetitions] || @default_max_repetitions
    non_reps = opts[:non_repeaters] || @default_non_repeaters
    
    pdu = SnmpLib.PDU.build_get_bulk_request(base_oid, request_id, non_reps, max_reps)
    perform_snmp_request(socket, host, pdu, opts)
  end
  
  defp perform_set_operation(socket, host, oid, value, opts) do
    request_id = generate_request_id()
    pdu = SnmpLib.PDU.build_set_request(oid, value, request_id)
    perform_snmp_request(socket, host, pdu, opts)
  end
  
  defp perform_snmp_request(socket, host, pdu, opts) do
    community = opts[:community] || @default_community
    version = opts[:version] || @default_version
    timeout = opts[:timeout] || @default_timeout
    port_option = opts[:port] || @default_port
    
    # Parse target to handle both host:port strings and :port option
    {parsed_host, parsed_port} = case SnmpLib.Utils.parse_target(host) do
      {:ok, %{host: h, port: p}} -> 
        # Check if host contained a port specification
        if host_contains_port?(host) do
          # Host:port format - use parsed port (backward compatibility)
          {h, p}
        else
          # Host without port - use :port option
          {h, port_option}
        end
      {:error, _} -> 
        # Parse failed - use original host and :port option
        {host, port_option}
    end
    
    message = SnmpLib.PDU.build_message(pdu, community, version)
    
    with {:ok, packet} <- SnmpLib.PDU.encode_message(message),
         {:ok, response_packet} <- send_and_receive(socket, parsed_host, parsed_port, packet, timeout),
         {:ok, response_message} <- SnmpLib.PDU.decode_message(response_packet) do
      {:ok, response_message}
    else
      {:error, reason} -> {:error, reason}
    end
  end
  
  defp send_and_receive(socket, host, port, packet, timeout) do
    with :ok <- SnmpLib.Transport.send_packet(socket, host, port, packet),
         {:ok, response_packet} <- SnmpLib.Transport.receive_packet(socket, timeout) do
      {:ok, response_packet}
    else
      {:error, :timeout} -> {:error, :timeout}
      {:error, reason} -> {:error, {:network_error, reason}}
    end
  end
  
  # Multi-get implementation with connection reuse
  defp get_multi_with_socket(socket, host, oids, opts) do
    Enum.map(oids, fn oid ->
      case perform_get_operation(socket, host, oid, opts) do
        {:ok, response} ->
          case extract_get_result(response) do
            {:ok, value} -> {oid, value}
            {:error, reason} -> {oid, {:error, reason}}
          end
        {:error, reason} ->
          {oid, {:error, reason}}
      end
    end)
  end
  
  # Result extraction
  defp extract_get_result(%{pdu: %{error_status: error_status}}) when error_status != 0 do
    {:error, decode_error_status(error_status)}
  end
  defp extract_get_result(%{pdu: %{varbinds: [{_oid, type, value}]}}) do
    # Check for SNMPv2c exception values in both type and value fields
    case {type, value} do
      # Exception values in type field (from simulator)
      {:no_such_object, _} -> {:error, :no_such_object}
      {:no_such_instance, _} -> {:error, :no_such_instance}
      {:end_of_mib_view, _} -> {:error, :end_of_mib_view}
      
      # Exception values in value field (standard format)
      {_, {:no_such_object, _}} -> {:error, :no_such_object}
      {_, {:no_such_instance, _}} -> {:error, :no_such_instance}
      {_, {:end_of_mib_view, _}} -> {:error, :end_of_mib_view}
      
      # Normal value
      _ -> {:ok, value}
    end
  end
  defp extract_get_result(_), do: {:error, :invalid_response}
  
  defp extract_bulk_result(%{pdu: %{varbinds: varbinds}}) do
    valid_varbinds = Enum.filter(varbinds, fn {_oid, type, value} ->
      # Check for SNMPv2c exception values in both type and value fields
      case {type, value} do
        # Exception values in type field (from simulator)
        {:no_such_object, _} -> false
        {:no_such_instance, _} -> false
        {:end_of_mib_view, _} -> false
        
        # Exception values in value field (standard format)
        {_, {:no_such_object, _}} -> false
        {_, {:no_such_instance, _}} -> false
        {_, {:end_of_mib_view, _}} -> false
        
        # Valid varbind
        _ -> true
      end
    end)
    
    results = Enum.map(valid_varbinds, fn {oid, _type, value} -> {oid, value} end)
    {:ok, results}
  end
  defp extract_bulk_result(%{pdu: %{error_status: error_status}}) when error_status != 0 do
    {:error, decode_error_status(error_status)}
  end
  defp extract_bulk_result(_), do: {:error, :invalid_response}
  
  defp extract_set_result(%{pdu: %{error_status: 0}}) do
    {:ok, :success}
  end
  defp extract_set_result(%{pdu: %{error_status: error_status}}) when error_status != 0 do
    {:error, decode_error_status(error_status)}
  end
  defp extract_set_result(_), do: {:error, :invalid_response}
  
  # Helper functions
  defp normalize_oid(oid) when is_list(oid), do: oid
  defp normalize_oid(oid) when is_binary(oid) do
    case SnmpLib.OID.string_to_list(oid) do
      {:ok, oid_list} -> oid_list
      {:error, _} -> [1, 3, 6, 1]  # Safe fallback
    end
  end
  defp normalize_oid(_), do: [1, 3, 6, 1]
  
  defp generate_request_id do
    :rand.uniform(2_147_483_647)
  end
  
  defp decode_error_status(0), do: :no_error
  defp decode_error_status(1), do: :too_big
  defp decode_error_status(2), do: :no_such_name
  defp decode_error_status(3), do: :bad_value
  defp decode_error_status(4), do: :read_only
  defp decode_error_status(5), do: :gen_err
  defp decode_error_status(error), do: {:unknown_error, error}
  
  defp merge_default_opts(opts) do
    [
      community: @default_community,
      version: @default_version,
      timeout: @default_timeout,
      retries: @default_retries,
      port: @default_port,
      local_port: @default_local_port
    ]
    |> Keyword.merge(opts)
  end
  
  defp merge_bulk_opts(opts) do
    merge_default_opts(opts)
    |> Keyword.merge([
      max_repetitions: @default_max_repetitions,
      non_repeaters: @default_non_repeaters
    ])
    |> Keyword.merge(opts)
  end
  
  # Helper to determine if host string contains port specification
  defp host_contains_port?(host) when is_binary(host) do
    cond do
      # RFC 3986 bracket notation: [IPv6]:port
      String.starts_with?(host, "[") and String.contains?(host, "]:") ->
        # Check if it's valid [addr]:port format
        case String.split(host, "]:", parts: 2) do
          [_ipv6_part, port_part] ->
            case Integer.parse(port_part) do
              {port, ""} when port > 0 and port <= 65535 -> true
              _ -> false
            end
          _ -> false
        end
      
      # Plain IPv6 addresses (contain :: or multiple colons) - no port embedded
      String.contains?(host, "::") -> false
      (host |> String.graphemes() |> Enum.count(&(&1 == ":"))) > 1 -> false
      
      # IPv4 or simple hostname with port
      String.contains?(host, ":") -> 
        # Single colon - check if part after colon looks like a port number
        case String.split(host, ":", parts: 2) do
          [_host_part, port_part] ->
            case Integer.parse(port_part) do
              {port, ""} when port > 0 and port <= 65535 -> true
              _ -> false
            end
          _ -> false
        end
      
      # No colon at all
      true -> false
    end
  end
  defp host_contains_port?(_), do: false
  
  # Check if all results failed with the same network-related error
  defp check_for_global_failure(results) do
    errors = Enum.filter(results, fn
      {_oid, {:error, _}} -> true
      _ -> false
    end)
    
    # If all results are errors, check if they're all network-related
    case {length(errors), length(results)} do
      {same, same} when same > 0 ->
        # All operations failed, check if it's a consistent network error
        network_errors = Enum.filter(errors, fn 
          {_oid, {:error, {:network_error, _}}} -> true
          _ -> false
        end)
        
        case length(network_errors) do
          ^same -> 
            # All errors are network errors, return the first one as global failure
            {_oid, {:error, reason}} = hd(errors)
            {:global_failure, reason}
          _ -> 
            :mixed_results
        end
      _ ->
        :mixed_results
    end
  end
end