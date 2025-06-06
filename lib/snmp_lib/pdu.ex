defmodule SnmpLib.PDU do
  @moduledoc """
  SNMP PDU (Protocol Data Unit) encoding and decoding with RFC compliance.
  
  Provides comprehensive SNMP PDU functionality combining the best features from
  multiple SNMP implementations. Supports SNMPv1 and SNMPv2c protocols with
  high-performance encoding/decoding, robust error handling, and full RFC compliance.
  
  ## API Documentation
  
  ### PDU Structure
  
  All PDU functions in this library use a **consistent map structure** with these fields:
  
  ```elixir
  %{
    type: :get_request | :get_next_request | :get_response | :set_request | :get_bulk_request,
    request_id: non_neg_integer(),
    error_status: 0..5,
    error_index: non_neg_integer(),
    varbinds: [varbind()],
    # GETBULK only:
    non_repeaters: non_neg_integer(),      # Optional, GETBULK requests only
    max_repetitions: non_neg_integer()     # Optional, GETBULK requests only
  }
  ```
  
  **IMPORTANT**: Always use the `:type` field (not `:pdu_type`) with atom values.
  
  ### Variable Bindings Format
  
  Variable bindings (`varbinds`) support two formats:
  
  - **2-tuple format**: `{oid, value}` - Used for responses and simple cases
  - **3-tuple format**: `{oid, type, value}` - Used for requests with explicit type info
  
  ```elixir
  # Request varbinds (3-tuple with type information)
  [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :null, :null}]
  
  # Response varbinds (2-tuple format)  
  [{[1, 3, 6, 1, 2, 1, 1, 1, 0], "Linux server"}]
  
  # Response varbinds (3-tuple format also supported)
  [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :octet_string, "Linux server"}]
  ```
  
  ### Message Structure
  
  SNMP messages have this structure:
  
  ```elixir
  %{
    version: 0 | 1,                    # 0 = SNMPv1, 1 = SNMPv2c
    community: binary(),               # Community string as binary
    pdu: pdu()                        # PDU map as defined above
  }
  ```
  
  ### Function Usage Patterns
  
  ```elixir
  # 1. Build a PDU
  pdu = SnmpLib.PDU.build_get_request([1, 3, 6, 1, 2, 1, 1, 1, 0], 12345)
  
  # 2. Build a complete message
  message = SnmpLib.PDU.build_message(pdu, "public", :v2c)
  
  # 3. Encode to binary
  {:ok, binary} = SnmpLib.PDU.encode_message(message)
  
  # 4. Decode from binary
  {:ok, decoded_message} = SnmpLib.PDU.decode_message(binary)
  ```
  
  ## Features
  
  - Pure Elixir ASN.1 BER encoding/decoding
  - Support for all standard SNMP operations (GET, GETNEXT, GETBULK, SET)
  - Community string validation
  - Error response generation  
  - Performance-optimized fast paths
  - Comprehensive SNMP data type support
  - **SNMPv2c exception values** (noSuchObject, noSuchInstance, endOfMibView)
  - **RFC-compliant OID encoding** with proper multibyte support
  
  ## Protocol Versions
  
  - **SNMPv1**: Original SNMP with basic GET/SET operations
  - **SNMPv2c**: Enhanced version with GETBULK and exception values
  
  ## SNMPv2c Exception Values
  
  The library properly handles SNMPv2c exception values that indicate
  special conditions during SNMP operations:
  
  - `noSuchObject` (0x80): Requested object does not exist
  - `noSuchInstance` (0x81): Object exists but instance does not
  - `endOfMibView` (0x82): End of MIB tree reached during walks
  
  ## Examples
  
      # Build and encode a GET request
      iex> pdu = SnmpLib.PDU.build_get_request([1, 3, 6, 1, 2, 1, 1, 1, 0], 12345)
      iex> pdu.type
      :get_request
      iex> pdu.request_id
      12345
      iex> length(pdu.varbinds)
      1
      
      # Build message and encode
      iex> pdu = SnmpLib.PDU.build_get_request([1, 3, 6, 1, 2, 1, 1, 1, 0], 99)
      iex> message = SnmpLib.PDU.build_message(pdu, "public", :v2c)
      iex> {:ok, encoded} = SnmpLib.PDU.encode_message(message)
      iex> is_binary(encoded)
      true
      
      # Build GETBULK request (SNMPv2c only)
      iex> bulk_pdu = SnmpLib.PDU.build_get_bulk_request([1, 3, 6, 1, 2, 1, 2, 2], 123, 0, 10)
      iex> bulk_pdu.type
      :get_bulk_request
      iex> bulk_pdu.max_repetitions
      10
      
      # Build response with exception values
      iex> {:ok, exception_val} = SnmpLib.Types.coerce_value(:no_such_object, nil)
      iex> varbinds = [{[1, 3, 6, 1, 2, 1, 1, 1, 0], :no_such_object, exception_val}]
      iex> response_pdu = SnmpLib.PDU.build_response(1, 0, 0, varbinds)
      iex> response_message = SnmpLib.PDU.build_message(response_pdu, "public", :v2c)
      iex> {:ok, encoded} = SnmpLib.PDU.encode_message(response_message)
      iex> {:ok, decoded} = SnmpLib.PDU.decode_message(encoded)
      iex> {_oid, _type, decoded_val} = hd(decoded.pdu.varbinds)
      iex> decoded_val == exception_val
      true
  """

  import Bitwise

  # SNMP PDU Types
  @get_request 0xA0
  @getnext_request 0xA1
  @get_response 0xA2
  @set_request 0xA3
  @getbulk_request 0xA5

  # SNMP Data Types
  @integer 0x02
  @octet_string 0x04
  @null 0x05
  @object_identifier 0x06
  @counter32 0x41
  @gauge32 0x42
  @timeticks 0x43
  @counter64 0x46
  @ip_address 0x40
  @opaque_type 0x44
  @no_such_object 0x80
  @no_such_instance 0x81
  @end_of_mib_view 0x82

  # SNMP Error Status Codes
  @no_error 0
  @too_big 1
  @no_such_name 2
  @bad_value 3
  @read_only 4
  @gen_err 5

  @type snmp_version :: :v1 | :v2c | :v2 | :v3 | 0 | 1 | 3
  @type pdu_type :: :get_request | :get_next_request | :get_response | :set_request | :get_bulk_request
  @type error_status :: 0..5
  @type oid :: [non_neg_integer()] | binary()
  @type snmp_value :: any()
  @type varbind :: {oid(), snmp_value()} | {oid(), atom(), snmp_value()}

  # Error status code accessors
  def no_error, do: @no_error
  def too_big, do: @too_big
  def no_such_name, do: @no_such_name
  def bad_value, do: @bad_value
  def read_only, do: @read_only
  def gen_err, do: @gen_err

  @type pdu :: %{
    type: pdu_type(),
    request_id: non_neg_integer(),
    error_status: error_status(),
    error_index: non_neg_integer(),
    varbinds: [varbind()],
    non_repeaters: non_neg_integer(),
    max_repetitions: non_neg_integer()
  }

  @type message :: %{
    version: snmp_version() | non_neg_integer(),
    community: binary(),
    pdu: pdu()
  }

  # IMPORTANT: This module does NOT define a struct. All functions work with plain maps.
  # The canonical PDU format uses the :type field (not :pdu_type) with atom values.
  # 
  # If you need backward compatibility with code expecting :pdu_type field,
  # you can convert using: Map.put(pdu, :pdu_type, pdu.type)
  #
  # Canonical PDU map structure:
  # %{
  #   type: :get_request | :get_next_request | :get_response | :set_request | :get_bulk_request,
  #   request_id: integer(),
  #   error_status: integer(),  
  #   error_index: integer(),
  #   varbinds: [varbind()]
  # }

  ## Public API

  @doc """
  Builds a GET request PDU for retrieving a single SNMP object.
  
  Creates a PDU structure for an SNMP GET operation that can be encoded
  and sent to an SNMP agent to retrieve the value of a specific OID.
  
  ## Parameters
  
  - `oid_list`: OID as list of integers (e.g., `[1, 3, 6, 1, 2, 1, 1, 1, 0]`)
  - `request_id`: Unique request identifier (0-2147483647)
  
  ## Returns
  
  A PDU map structure with:
  - `type`: `:get_request`
  - `request_id`: The provided request ID
  - `error_status`: 0 (no error)
  - `error_index`: 0
  - `varbinds`: Single varbind with the OID and null value
  
  ## Examples
  
      # Build GET request for sysDescr.0
      iex> pdu = SnmpLib.PDU.build_get_request([1, 3, 6, 1, 2, 1, 1, 1, 0], 12345)
      iex> pdu.type
      :get_request
      iex> pdu.request_id
      12345
      iex> length(pdu.varbinds)
      1
      
      # Build message and encode
      iex> pdu = SnmpLib.PDU.build_get_request([1, 3, 6, 1, 2, 1, 1, 1, 0], 99)
      iex> message = SnmpLib.PDU.build_message(pdu, "public", :v2c)
      iex> {:ok, encoded} = SnmpLib.PDU.encode_message(message)
      iex> is_binary(encoded)
      true
  """
  @spec build_get_request(oid(), pos_integer()) :: pdu()
  def build_get_request(oid_list, request_id) do
    validate_request_id!(request_id)
    normalized_oid = normalize_oid(oid_list)
    
    %{
      type: :get_request,
      request_id: request_id,
      error_status: @no_error,
      error_index: 0,
      varbinds: [{normalized_oid, :null, :null}]
    }
  end

  @doc """
  Builds a GETNEXT request PDU.
  """
  @spec build_get_next_request(oid(), pos_integer()) :: pdu()
  def build_get_next_request(oid_list, request_id) do
    validate_request_id!(request_id)
    normalized_oid = normalize_oid(oid_list)
    
    %{
      type: :get_next_request,
      request_id: request_id,
      error_status: @no_error,
      error_index: 0,
      varbinds: [{normalized_oid, :null, :null}]
    }
  end

  @doc """
  Builds a SET request PDU.
  """
  @spec build_set_request(oid(), {atom(), any()}, pos_integer()) :: pdu()
  def build_set_request(oid_list, {type, value}, request_id) do
    validate_request_id!(request_id)
    normalized_oid = normalize_oid(oid_list)
    
    %{
      type: :set_request,
      request_id: request_id,
      error_status: @no_error,
      error_index: 0,
      varbinds: [{normalized_oid, type, value}]
    }
  end

  @doc """
  Builds a GETBULK request PDU for SNMPv2c.
  
  ## Parameters
  
  - `oid_list`: Starting OID
  - `request_id`: Request identifier
  - `non_repeaters`: Number of non-repeating variables (default: 0)
  - `max_repetitions`: Maximum repetitions (default: 10)
  """
  @spec build_get_bulk_request(oid(), pos_integer(), non_neg_integer(), pos_integer()) :: pdu()
  def build_get_bulk_request(oid_list, request_id, non_repeaters \\ 0, max_repetitions \\ 10) do
    validate_request_id!(request_id)
    validate_bulk_params!(non_repeaters, max_repetitions)
    normalized_oid = normalize_oid(oid_list)
    
    %{
      type: :get_bulk_request,
      request_id: request_id,
      non_repeaters: non_repeaters,
      max_repetitions: max_repetitions,
      varbinds: [{normalized_oid, :null, :null}]
    }
  end

  @doc """
  Builds a GET request PDU with multiple OID/value pairs.
  """
  @spec build_get_request_multi([varbind()], pos_integer()) :: {:ok, pdu()} | {:error, atom()}
  def build_get_request_multi(varbinds, request_id) when is_list(varbinds) and length(varbinds) > 0 do
    validate_request_id!(request_id)
    
    case validate_varbinds_format(varbinds) do
      :ok ->
        {:ok, %{
          type: :get_request,
          request_id: request_id,
          error_status: @no_error,
          error_index: 0,
          varbinds: varbinds
        }}
      {:error, reason} ->
        {:error, reason}
    end
  end
  def build_get_request_multi([], _request_id) do
    {:error, :empty_varbinds}
  end
  def build_get_request_multi(_varbinds, _request_id) do
    {:error, :invalid_varbinds_format}
  end

  @doc """
  Builds a response PDU.
  """
  @spec build_response(pos_integer(), error_status(), non_neg_integer(), [varbind()]) :: pdu()
  def build_response(request_id, error_status, error_index, varbinds \\ []) do
    validate_request_id!(request_id)
    
    %{
      type: :get_response,
      request_id: request_id,
      error_status: error_status,
      error_index: error_index,
      varbinds: varbinds
    }
  end

  @doc """
  Builds an SNMP message structure.
  
  ## Parameters
  
  - `pdu`: The PDU to include in the message
  - `community`: Community string
  - `version`: SNMP version (:v1, :v2c, etc.)
  """
  @spec build_message(pdu(), binary(), snmp_version()) :: message()
  def build_message(pdu, community, version \\ :v1) do
    validate_community!(community)
    validate_bulk_version!(pdu, version)
    
    version_number = normalize_version(version)
    
    %{
      version: version_number,
      community: community,
      pdu: pdu
    }
  end

  @doc """
  Encodes an SNMP message to binary format.
  """
  @spec encode_message(message()) :: {:ok, binary()} | {:error, atom()}
  def encode_message(%{version: version, community: community, pdu: pdu}) do
    try do
      encode_snmp_message_fast(version, community, pdu)
    rescue
      error -> {:error, {:encoding_error, error}}
    catch
      error -> {:error, {:encoding_error, error}}
    end
  end
  def encode_message(_), do: {:error, :invalid_message_format}

  @doc """
  Decodes an SNMP message from binary format.
  """
  @spec decode_message(binary()) :: {:ok, message()} | {:error, atom()}
  def decode_message(binary) when is_binary(binary) do
    try do
      decode_snmp_message_comprehensive(binary)
    rescue
      error -> {:error, {:decoding_error, error}}
    catch
      error -> {:error, {:decoding_error, error}}
    end
  end
  def decode_message(_), do: {:error, :invalid_input}

  @doc """
  Validates community string in an SNMP packet.
  
  ## Examples
  
      :ok = SnmpLib.PDU.validate_community(packet, "public")
      {:error, :invalid_community} = SnmpLib.PDU.validate_community(packet, "wrong")
  """
  @spec validate_community(binary(), binary()) :: :ok | {:error, atom()}
  def validate_community(packet, expected_community) when is_binary(packet) and is_binary(expected_community) do
    case decode_message(packet) do
      {:ok, %{community: ^expected_community}} -> :ok
      {:ok, %{community: _other}} -> {:error, :invalid_community}
      {:error, reason} -> {:error, reason}
    end
  end
  def validate_community(_packet, _community), do: {:error, :invalid_parameters}

  @doc """
  Creates an error response PDU from a request PDU.
  
  ## Examples
  
      error_pdu = SnmpLib.PDU.create_error_response(request_pdu, 2, 1)
  """
  @spec create_error_response(pdu(), error_status(), non_neg_integer()) :: pdu()
  def create_error_response(request_pdu, error_status, error_index \\ 0) do
    # Handle PDU map format - all PDUs are maps with :type field
    case request_pdu do
      %{type: _type, request_id: request_id, varbinds: varbinds} ->
        %{
          type: :get_response,
          request_id: request_id,
          error_status: error_status,
          error_index: error_index,
          varbinds: varbinds
        }
      _ ->
        # Legacy map format for backward compatibility
        %{
          type: :get_response,
          request_id: Map.get(request_pdu, :request_id, 1),
          error_status: error_status,
          error_index: error_index,
          varbinds: Map.get(request_pdu, :varbinds, [])
        }
    end
  end

  @doc """
  Validates a PDU structure.
  """
  @spec validate(pdu()) :: {:ok, pdu()} | {:error, atom()}
  def validate(pdu) when is_map(pdu) do
    # First check if we have a type field
    case Map.get(pdu, :type) do
      nil -> {:error, :missing_required_fields}
      type ->
        # Validate the type first
        case validate_pdu_type_only(type) do
          :ok ->
            # Now check required fields based on type
            basic_fields = [:request_id, :varbinds]
            case Enum.all?(basic_fields, &Map.has_key?(pdu, &1)) do
              false -> {:error, :missing_required_fields}
              true ->
                case type do
                  :get_bulk_request ->
                    bulk_fields = [:non_repeaters, :max_repetitions]
                    case Enum.all?(bulk_fields, &Map.has_key?(pdu, &1)) do
                      true -> {:ok, pdu}
                      false -> {:error, :missing_bulk_fields}
                    end
                  _ ->
                    # Standard PDUs need error_status and error_index
                    standard_fields = [:error_status, :error_index]
                    case Enum.all?(standard_fields, &Map.has_key?(pdu, &1)) do
                      true -> {:ok, pdu}
                      false -> {:error, :missing_required_fields}
                    end
                end
            end
          :error -> {:error, :invalid_pdu_type}
        end
    end
  end
  def validate(_), do: {:error, :invalid_pdu_format}

  # Helper function to validate PDU type
  defp validate_pdu_type_only(type) do
    case type do
      :get_request -> :ok
      :get_next_request -> :ok
      :get_response -> :ok
      :set_request -> :ok
      :get_bulk_request -> :ok
      :inform_request -> :ok
      :snmpv2_trap -> :ok
      :report -> :ok
      _ -> :error
    end
  end

  @doc """
  Decodes an SNMP packet (alias for decode_message/1).
  
  Returns the canonical map format, not a struct.
  """
  @spec decode(binary()) :: {:ok, message()} | {:error, atom()}
  def decode(binary_packet) when is_binary(binary_packet) do
    decode_message(binary_packet)
  end

  @doc """
  Encodes an SNMP message to binary format (alias for encode_message/1).
  """
  @spec encode(message()) :: {:ok, binary()} | {:error, atom()}
  def encode(message) when is_map(message) do
    encode_message(message)
  end

  @doc """
  Alias for decode/1.
  """
  @spec decode_snmp_packet(binary()) :: {:ok, message()} | {:error, atom()}
  def decode_snmp_packet(binary_packet), do: decode(binary_packet)

  @doc """
  Alias for encode/1.
  """
  @spec encode_snmp_packet(message()) :: {:ok, binary()} | {:error, atom()}
  def encode_snmp_packet(message), do: encode(message)

  ## Private Implementation

  # Validation helpers
  defp validate_request_id!(request_id) do
    unless is_integer(request_id) and request_id >= 0 and request_id <= 2_147_483_647 do
      raise ArgumentError, "Request ID must be a valid integer (0-2147483647), got: #{inspect(request_id)}"
    end
  end

  defp validate_bulk_params!(non_repeaters, max_repetitions) do
    unless is_integer(non_repeaters) and non_repeaters >= 0 do
      raise ArgumentError, "non_repeaters must be a non-negative integer, got: #{inspect(non_repeaters)}"
    end
    unless is_integer(max_repetitions) and max_repetitions >= 0 do
      raise ArgumentError, "max_repetitions must be a non-negative integer, got: #{inspect(max_repetitions)}"
    end
  end

  defp validate_community!(community) do
    unless is_binary(community) do
      raise ArgumentError, "Community must be a binary string, got: #{inspect(community)}"
    end
  end

  defp validate_bulk_version!(pdu, version) do
    if Map.get(pdu, :type) == :get_bulk_request and version == :v1 do
      raise ArgumentError, "GETBULK requests require SNMPv2c or higher, cannot use v1"
    end
  end

  defp validate_varbinds_format(varbinds) do
    valid = Enum.all?(varbinds, fn
      {oid, _type, _value} when is_list(oid) -> Enum.all?(oid, &is_integer/1)
      _ -> false
    end)
    
    if valid, do: :ok, else: {:error, :invalid_varbind_format}
  end

  # PDU validation helpers
  defp normalize_oid(oid) when is_list(oid), do: oid
  defp normalize_oid(oid) when is_binary(oid) do
    case SnmpLib.OID.string_to_list(oid) do
      {:ok, oid_list} -> oid_list
      {:error, _} -> [1, 3, 6, 1]  # Safe default only on parse error
    end
  end
  defp normalize_oid(_), do: [1, 3, 6, 1]  # Safe default for invalid types

  defp normalize_version(:v1), do: 0
  defp normalize_version(:v2c), do: 1
  defp normalize_version(:v2), do: 1
  defp normalize_version(:v3), do: 3
  defp normalize_version(v) when is_integer(v), do: v
  defp normalize_version(_), do: 0

  # Legacy conversion helpers
  defp encode_snmp_message_fast(version, community, pdu) when is_integer(version) and is_binary(community) and is_map(pdu) do
    case encode_pdu_fast(pdu) do
      {:ok, pdu_encoded} ->
        iodata = [
          encode_integer_fast(version),
          encode_octet_string_fast(community),
          pdu_encoded
        ]
        
        content = :erlang.iolist_to_binary(iodata)
        {:ok, encode_sequence_ber(content)}
        
      {:error, reason} -> {:error, reason}
    end
  end
  defp encode_snmp_message_fast(_, _, _), do: {:error, :invalid_message_format}

  defp encode_pdu_fast(%{type: :get_request} = pdu), do: encode_standard_pdu_fast(pdu, @get_request)
  defp encode_pdu_fast(%{type: :get_next_request} = pdu), do: encode_standard_pdu_fast(pdu, @getnext_request)
  defp encode_pdu_fast(%{type: :get_response} = pdu), do: encode_standard_pdu_fast(pdu, @get_response)
  defp encode_pdu_fast(%{type: :set_request} = pdu), do: encode_standard_pdu_fast(pdu, @set_request)
  defp encode_pdu_fast(%{type: :get_bulk_request} = pdu), do: encode_bulk_pdu_fast(pdu)
  defp encode_pdu_fast(_), do: {:error, :unsupported_pdu_type}

  defp encode_standard_pdu_fast(pdu, tag) do
    %{
      request_id: request_id,
      error_status: error_status,
      error_index: error_index,
      varbinds: varbinds
    } = pdu
    
    case encode_varbinds_fast(varbinds) do
      {:ok, varbinds_encoded} ->
        iodata = [
          encode_integer_fast(request_id),
          encode_integer_fast(error_status),
          encode_integer_fast(error_index),
          varbinds_encoded
        ]
        
        content = :erlang.iolist_to_binary(iodata)
        {:ok, encode_tag_length_value(tag, byte_size(content), content)}
        
      {:error, reason} -> {:error, reason}
    end
  end

  defp encode_bulk_pdu_fast(pdu) do
    %{
      request_id: request_id,
      non_repeaters: non_repeaters,
      max_repetitions: max_repetitions,
      varbinds: varbinds
    } = pdu
    
    case encode_varbinds_fast(varbinds) do
      {:ok, varbinds_encoded} ->
        iodata = [
          encode_integer_fast(request_id),
          encode_integer_fast(non_repeaters),
          encode_integer_fast(max_repetitions),
          varbinds_encoded
        ]
        
        content = :erlang.iolist_to_binary(iodata)
        {:ok, encode_tag_length_value(@getbulk_request, byte_size(content), content)}
        
      {:error, reason} -> {:error, reason}
    end
  end

  defp encode_varbinds_fast(varbinds) when is_list(varbinds) do
    case encode_varbinds_acc(varbinds, []) do
      {:ok, iodata} ->
        content = :erlang.iolist_to_binary(iodata)
        {:ok, encode_sequence_ber(content)}
      error -> error
    end
  end

  defp encode_varbinds_acc([], acc), do: {:ok, Enum.reverse(acc)}
  defp encode_varbinds_acc([varbind | rest], acc) do
    case encode_varbind_fast(varbind) do
      {:ok, encoded} -> encode_varbinds_acc(rest, [encoded | acc])
      error -> error
    end
  end

  defp encode_varbind_fast({oid, type, value}) when is_list(oid) do
    case encode_oid_fast(oid) do
      {:ok, oid_encoded} ->
        value_encoded = encode_snmp_value_fast(type, value)
        content = :erlang.iolist_to_binary([oid_encoded, value_encoded])
        {:ok, encode_sequence_ber(content)}
      error -> error
    end
  end
  defp encode_varbind_fast({oid, value}) when is_list(oid) do
    encode_varbind_fast({oid, :auto, value})
  end
  defp encode_varbind_fast(_), do: {:error, :invalid_varbind_format}

  # Fast integer encoder
  defp encode_integer_fast(0), do: <<@integer, 0x01, 0x00>>
  defp encode_integer_fast(value) when value > 0 and value < 128 do
    <<@integer, 0x01, value>>
  end
  defp encode_integer_fast(value) when is_integer(value) do
    encode_integer_ber(value)
  end

  defp encode_octet_string_fast(value) when is_binary(value) do
    length = byte_size(value)
    length_bytes = encode_length_ber(length)
    [<<@octet_string>>, length_bytes, value]
  end

  defp encode_snmp_value_fast(:null, _), do: <<@null, 0x00>>
  defp encode_snmp_value_fast(:auto, nil), do: <<@null, 0x00>>
  defp encode_snmp_value_fast(:auto, :null), do: <<@null, 0x00>>
  defp encode_snmp_value_fast(:integer, value) when is_integer(value), do: encode_integer_fast(value)
  defp encode_snmp_value_fast(:string, value) when is_binary(value), do: encode_octet_string_fast(value)
  defp encode_snmp_value_fast(:counter32, value) when is_integer(value) and value >= 0 do
    encode_unsigned_integer(@counter32, value)
  end
  defp encode_snmp_value_fast(:gauge32, value) when is_integer(value) and value >= 0 do
    encode_unsigned_integer(@gauge32, value)
  end
  defp encode_snmp_value_fast(:timeticks, value) when is_integer(value) and value >= 0 do
    encode_unsigned_integer(@timeticks, value)
  end
  defp encode_snmp_value_fast(:counter64, value) when is_integer(value) and value >= 0 do
    encode_counter64(@counter64, value)
  end
  defp encode_snmp_value_fast(:object_identifier, value) when is_list(value) do
    case encode_oid_fast(value) do
      {:ok, encoded} -> encoded
      {:error, _} -> <<@null, 0x00>>
    end
  end
  defp encode_snmp_value_fast(:object_identifier, value) when is_binary(value) do
    try do
      case String.split(value, ".") |> Enum.map(&String.to_integer/1) do
        oid_list when is_list(oid_list) ->
          case encode_oid_fast(oid_list) do
            {:ok, encoded} -> encoded
            {:error, _} -> <<@null, 0x00>>
          end
        _ -> <<@null, 0x00>>
      end
    rescue
      _ -> <<@null, 0x00>>
    end
  end
  defp encode_snmp_value_fast(:auto, value) when is_integer(value), do: encode_integer_fast(value)
  defp encode_snmp_value_fast(:auto, value) when is_binary(value), do: encode_octet_string_fast(value)
  defp encode_snmp_value_fast(:auto, value) when is_list(value) do
    # Assume it's an OID if it's a list of non-negative integers
    if Enum.all?(value, &(is_integer(&1) and &1 >= 0)) do
      case encode_oid_fast(value) do
        {:ok, encoded} -> encoded
        {:error, _} -> <<@null, 0x00>>
      end
    else
      <<@null, 0x00>>
    end
  end
  
  # Handle tuple formats from decoder
  defp encode_snmp_value_fast(:auto, {:counter32, value}) when is_integer(value) and value >= 0 do
    encode_unsigned_integer(@counter32, value)
  end
  defp encode_snmp_value_fast(:auto, {:gauge32, value}) when is_integer(value) and value >= 0 do
    encode_unsigned_integer(@gauge32, value)
  end
  defp encode_snmp_value_fast(:auto, {:timeticks, value}) when is_integer(value) and value >= 0 do
    encode_unsigned_integer(@timeticks, value)
  end
  defp encode_snmp_value_fast(:auto, {:counter64, value}) when is_integer(value) and value >= 0 do
    encode_counter64(@counter64, value)
  end
  defp encode_snmp_value_fast(:auto, {:ip_address, value}) when is_binary(value) and byte_size(value) == 4 do
    encode_tag_length_value(@ip_address, 4, value)
  end
  defp encode_snmp_value_fast(:auto, {:opaque, value}) when is_binary(value) do
    length = byte_size(value)
    encode_tag_length_value(@opaque_type, length, value)
  end
  defp encode_snmp_value_fast(:auto, {:no_such_object, _}), do: <<@no_such_object, 0x00>>
  defp encode_snmp_value_fast(:auto, {:no_such_instance, _}), do: <<@no_such_instance, 0x00>>
  defp encode_snmp_value_fast(:auto, {:end_of_mib_view, _}), do: <<@end_of_mib_view, 0x00>>
  defp encode_snmp_value_fast(:auto, {:object_identifier, oid}) when is_list(oid) do
    case encode_oid_fast(oid) do
      {:ok, encoded} -> encoded
      {:error, _} -> <<@null, 0x00>>
    end
  end
  defp encode_snmp_value_fast(:auto, {:object_identifier, oid}) when is_binary(oid) do
    try do
      case String.split(oid, ".") |> Enum.map(&String.to_integer/1) do
        oid_list when is_list(oid_list) ->
          case encode_oid_fast(oid_list) do
            {:ok, encoded} -> encoded
            {:error, _} -> <<@null, 0x00>>
          end
        _ -> <<@null, 0x00>>
      end
    rescue
      _ -> <<@null, 0x00>>
    end
  end
  defp encode_snmp_value_fast(:no_such_object, _), do: <<@no_such_object, 0x00>>
  defp encode_snmp_value_fast(:no_such_instance, _), do: <<@no_such_instance, 0x00>>
  defp encode_snmp_value_fast(:end_of_mib_view, _), do: <<@end_of_mib_view, 0x00>>
  
  # Complex SNMP types
  defp encode_snmp_value_fast({:object_identifier, oid}, _) when is_list(oid) do
    case encode_oid_fast(oid) do
      {:ok, encoded} -> encoded
      {:error, _} -> <<@null, 0x00>>
    end
  end
  defp encode_snmp_value_fast({:object_identifier, oid}, _) when is_binary(oid) do
    case String.split(oid, ".") |> Enum.map(&String.to_integer/1) do
      oid_list when is_list(oid_list) ->
        case encode_oid_fast(oid_list) do
          {:ok, encoded} -> encoded
          {:error, _} -> <<@null, 0x00>>
        end
      _ -> <<@null, 0x00>>
    end
  rescue
    _ -> <<@null, 0x00>>
  end
  defp encode_snmp_value_fast({:counter32, value}, _) when is_integer(value) and value >= 0 do
    encode_unsigned_integer(@counter32, value)
  end
  defp encode_snmp_value_fast({:gauge32, value}, _) when is_integer(value) and value >= 0 do
    encode_unsigned_integer(@gauge32, value)
  end
  defp encode_snmp_value_fast({:timeticks, value}, _) when is_integer(value) and value >= 0 do
    encode_unsigned_integer(@timeticks, value)
  end
  defp encode_snmp_value_fast({:counter64, value}, _) when is_integer(value) and value >= 0 do
    encode_counter64(@counter64, value)
  end
  
  defp encode_snmp_value_fast(_, :null), do: <<@null, 0x00>>
  defp encode_snmp_value_fast(_, _), do: <<@null, 0x00>>

  # ASN.1 BER encoding helpers
  defp encode_integer_ber(value) when is_integer(value) do
    bytes = integer_to_bytes(value)
    length = byte_size(bytes)
    encode_tag_length_value(@integer, length, bytes)
  end

  defp integer_to_bytes(0), do: <<0>>
  defp integer_to_bytes(value) when value > 0 do
    bytes = :binary.encode_unsigned(value, :big)
    case bytes do
      <<bit::1, _::bitstring>> when bit == 1 ->
        <<0>> <> bytes
      _ ->
        bytes
    end
  end
  defp integer_to_bytes(value) when value < 0 do
    positive = abs(value)
    bit_length = bit_length_for_integer(positive) + 1
    byte_length = div(bit_length + 7, 8)
    max_value = 1 <<< (byte_length * 8)
    twos_comp = max_value + value
    <<twos_comp::size(byte_length)-unit(8)-big>>
  end

  defp bit_length_for_integer(0), do: 1
  defp bit_length_for_integer(n) when n > 0 do
    :math.log2(n) |> :math.ceil() |> trunc()
  end

  defp encode_sequence_ber(content) when is_binary(content) do
    length = byte_size(content)
    encode_tag_length_value(0x30, length, content)
  end

  defp encode_tag_length_value(tag, length, content) do
    length_bytes = encode_length_ber(length)
    <<tag>> <> length_bytes <> content
  end

  defp encode_length_ber(length) when length < 128 do
    <<length>>
  end
  defp encode_length_ber(length) when length < 256 do
    <<0x81, length>>
  end
  defp encode_length_ber(length) when length < 65536 do
    <<0x82, length::16>>
  end
  defp encode_length_ber(length) when length < 16777216 do
    <<0x83, length::24>>
  end
  defp encode_length_ber(length) do
    <<0x84, length::32>>
  end

  # Helper functions for encoding unsigned integers and counter64
  defp encode_unsigned_integer(tag, value) when is_integer(value) and value >= 0 do
    bytes = encode_unsigned_bytes(value)
    length = byte_size(bytes)
    encode_tag_length_value(tag, length, bytes)
  end

  defp encode_counter64(tag, value) when is_integer(value) and value >= 0 do
    bytes = <<value::64>>
    length = byte_size(bytes)
    encode_tag_length_value(tag, length, bytes)
  end

  defp encode_unsigned_bytes(0), do: <<0>>
  defp encode_unsigned_bytes(value) when value > 0 do
    bytes = :binary.encode_unsigned(value, :big)
    # Ensure the most significant bit is 0 for unsigned integers
    case bytes do
      <<bit::1, _::bitstring>> when bit == 1 ->
        <<0>> <> bytes
      _ ->
        bytes
    end
  end

  # Comprehensive decoding implementation (from SnmpSim)
  defp decode_snmp_message_comprehensive(<<0x30, rest::binary>>) do
    case parse_ber_length(rest) do
      {:ok, {_content_length, content}} ->
        case parse_snmp_message_fields(content) do
          {:ok, {version, community, pdu_data}} ->
            case parse_pdu_comprehensive(pdu_data) do
              {:ok, pdu} -> 
                {:ok, %{
                  version: version,
                  community: community,
                  pdu: pdu
                }}
              {:error, reason} -> {:error, {:pdu_parse_error, reason}}
            end
          {:error, reason} -> {:error, {:message_parse_error, reason}}
        end
      {:error, reason} -> {:error, {:message_parse_error, reason}}
    end
  end
  defp decode_snmp_message_comprehensive(_), do: {:error, :invalid_message_format}

  defp parse_ber_length(<<length, rest::binary>>) when length < 128 do
    if byte_size(rest) >= length do
      content = binary_part(rest, 0, length)
      {:ok, {length, content}}
    else
      {:error, :insufficient_data}
    end
  end
  defp parse_ber_length(<<length_of_length, rest::binary>>) when length_of_length >= 128 do
    num_length_bytes = length_of_length - 128
    if num_length_bytes > 0 and num_length_bytes <= 4 and byte_size(rest) >= num_length_bytes do
      <<length_bytes::binary-size(num_length_bytes), remaining::binary>> = rest
      actual_length = :binary.decode_unsigned(length_bytes, :big)
      
      if byte_size(remaining) >= actual_length do
        content = binary_part(remaining, 0, actual_length)
        {:ok, {actual_length, content}}
      else
        {:error, :insufficient_data}
      end
    else
      {:error, :invalid_length_encoding}
    end
  end
  defp parse_ber_length(_), do: {:error, :invalid_length_format}  
  defp encode_oid_fast(oid_list) when is_list(oid_list) and length(oid_list) >= 2 do
    [first, second | rest] = oid_list
    
    if first < 3 and second < 40 do
      first_encoded = first * 40 + second
      
      case encode_oid_subids_fast([first_encoded | rest], []) do
        {:ok, content} ->
          {:ok, encode_tag_length_value(@object_identifier, byte_size(content), content)}
        error -> error
      end
    else
      {:error, :invalid_oid_format}
    end
  end
  defp encode_oid_fast(_), do: {:error, :invalid_oid_format}

  defp encode_oid_subids_fast([], acc), do: {:ok, :erlang.iolist_to_binary(Enum.reverse(acc))}
  defp encode_oid_subids_fast([subid | rest], acc) when subid >= 0 and subid < 128 do
    encode_oid_subids_fast(rest, [<<subid>> | acc])
  end
  defp encode_oid_subids_fast([subid | rest], acc) when subid >= 128 do
    bytes = encode_subid_multibyte(subid, [])
    encode_oid_subids_fast(rest, [bytes | acc])
  end
  defp encode_oid_subids_fast(_, _), do: {:error, :invalid_subidentifier}

  # Encode a subidentifier using ASN.1 BER multibyte encoding
  defp encode_subid_multibyte(subid, _acc) do
    encode_subid_multibyte_correct(subid)
  end
  
  # Correct implementation: build bytes from most significant to least significant
  defp encode_subid_multibyte_correct(subid) when subid < 128 do
    <<subid>>
  end
  defp encode_subid_multibyte_correct(subid) do
    # Build list of 7-bit groups from least to most significant
    bytes = build_multibyte_list(subid, [])
    # Convert to binary with high bits set correctly
    bytes_with_high_bits = set_high_bits(bytes)
    :erlang.iolist_to_binary(bytes_with_high_bits)
  end
  
  # Build list of 7-bit values from least to most significant
  defp build_multibyte_list(subid, acc) when subid < 128 do
    [subid | acc]  # Most significant byte (no more bits)
  end
  defp build_multibyte_list(subid, acc) do
    lower_7_bits = subid &&& 0x7F
    build_multibyte_list(subid >>> 7, [lower_7_bits | acc])
  end
  
  # Set high bits: all bytes except the last one get the high bit set
  defp set_high_bits([last]), do: [last]  # Last byte has no high bit
  defp set_high_bits([first | rest]) do
    [first ||| 0x80 | set_high_bits(rest)]  # Set high bit on all but last
  end


  defp parse_snmp_message_fields(data) do
    with {:ok, {version, rest1}} <- parse_integer(data),
         {:ok, {community, rest2}} <- parse_octet_string(rest1),
         {:ok, pdu_data} <- {:ok, rest2} do
      {:ok, {version, community, pdu_data}}
    end
  end

  defp parse_integer(<<@integer, rest::binary>>) do
    case parse_ber_length_and_remaining(rest) do
      {:ok, {_length, value_bytes, remaining}} ->
        if byte_size(value_bytes) > 0 do
          value = decode_integer_value(value_bytes)
          {:ok, {value, remaining}}
        else
          {:error, :invalid_integer_length}
        end
      {:error, reason} -> {:error, reason}
    end
  end
  defp parse_integer(_), do: {:error, :invalid_integer}

  defp parse_octet_string(<<@octet_string, rest::binary>>) do
    case parse_ber_length_and_remaining(rest) do
      {:ok, {_length, value_bytes, remaining}} ->
        {:ok, {value_bytes, remaining}}
      {:error, reason} -> {:error, reason}
    end
  end
  defp parse_octet_string(_), do: {:error, :invalid_octet_string}

  defp parse_ber_length_and_remaining(<<length, rest::binary>>) when length < 128 do
    if byte_size(rest) >= length do
      content = binary_part(rest, 0, length)
      remaining = binary_part(rest, length, byte_size(rest) - length)
      {:ok, {length, content, remaining}}
    else
      {:error, :insufficient_data}
    end
  end
  defp parse_ber_length_and_remaining(<<length_of_length, rest::binary>>) when length_of_length >= 128 do
    num_length_bytes = length_of_length - 128
    if num_length_bytes > 0 and num_length_bytes <= 4 and byte_size(rest) >= num_length_bytes do
      <<length_bytes::binary-size(num_length_bytes), remaining_with_content::binary>> = rest
      actual_length = :binary.decode_unsigned(length_bytes, :big)
      
      if byte_size(remaining_with_content) >= actual_length do
        content = binary_part(remaining_with_content, 0, actual_length)
        remaining = binary_part(remaining_with_content, actual_length, byte_size(remaining_with_content) - actual_length)
        {:ok, {actual_length, content, remaining}}
      else
        {:error, :insufficient_data}
      end
    else
      {:error, :invalid_length_encoding}
    end
  end
  defp parse_ber_length_and_remaining(_), do: {:error, :invalid_length_format}

  defp parse_pdu_comprehensive(<<tag, rest::binary>>) when tag in [0xA0, 0xA1, 0xA2, 0xA3, 0xA5] do
    pdu_type = case tag do
      0xA0 -> :get_request
      0xA1 -> :get_next_request  
      0xA2 -> :get_response
      0xA3 -> :set_request
      0xA5 -> :get_bulk_request
    end
    
    case parse_ber_length_and_remaining(rest) do
      {:ok, {_length, pdu_content, _remaining}} ->
        case pdu_type do
          :get_bulk_request ->
            case parse_bulk_pdu_fields(pdu_content) do
              {:ok, {request_id, non_repeaters, max_repetitions, varbinds}} ->
                {:ok, %{
                  type: pdu_type, 
                  request_id: request_id,
                  non_repeaters: non_repeaters, 
                  max_repetitions: max_repetitions,
                  varbinds: varbinds
                }}
              {:error, _reason} ->
                {:ok, %{type: pdu_type, varbinds: [], non_repeaters: 0, max_repetitions: 0}}
            end
          _ ->
            case parse_standard_pdu_fields(pdu_content) do
              {:ok, {request_id, error_status, error_index, varbinds}} ->
                {:ok, %{
                  type: pdu_type, 
                  request_id: request_id,
                  error_status: error_status, 
                  error_index: error_index,
                  varbinds: varbinds
                }}
              {:error, _reason} ->
                {:ok, %{type: pdu_type, varbinds: [], error_status: 0, error_index: 0}}
            end
        end
      {:error, _reason} ->
        case pdu_type do
          :get_bulk_request ->
            {:ok, %{type: pdu_type, varbinds: [], non_repeaters: 0, max_repetitions: 0}}
          _ ->
            {:ok, %{type: pdu_type, varbinds: [], error_status: 0, error_index: 0}}
        end
    end
  end
  defp parse_pdu_comprehensive(_), do: {:error, :invalid_pdu}

  defp parse_standard_pdu_fields(data) do
    with {:ok, {request_id, rest1}} <- parse_integer(data),
         {:ok, {error_status, rest2}} <- parse_integer(rest1),
         {:ok, {error_index, rest3}} <- parse_integer(rest2),
         {:ok, varbinds} <- parse_varbinds(rest3) do
      {:ok, {request_id, error_status, error_index, varbinds}}
    end
  end

  defp parse_bulk_pdu_fields(data) do
    with {:ok, {request_id, rest1}} <- parse_integer(data),
         {:ok, {non_repeaters, rest2}} <- parse_integer(rest1),
         {:ok, {max_repetitions, rest3}} <- parse_integer(rest2),
         {:ok, varbinds} <- parse_varbinds(rest3) do
      {:ok, {request_id, non_repeaters, max_repetitions, varbinds}}
    end
  end

  defp parse_varbinds(data) do
    case parse_sequence(data) do
      {:ok, {varbind_data, _rest}} -> parse_varbind_list(varbind_data, [])
      {:error, _} -> {:ok, []}
    end
  end

  defp parse_sequence(<<0x30, rest::binary>>) do
    case parse_ber_length_and_remaining(rest) do
      {:ok, {_length, data, remaining}} ->
        {:ok, {data, remaining}}
      {:error, reason} -> {:error, reason}
    end
  end
  defp parse_sequence(_), do: {:error, :not_sequence}

  defp parse_varbind_list(<<>>, acc), do: {:ok, Enum.reverse(acc)}
  defp parse_varbind_list(data, acc) do
    case parse_sequence(data) do
      {:ok, {varbind_data, rest}} ->
        case parse_single_varbind(varbind_data) do
          {:ok, varbind} -> parse_varbind_list(rest, [varbind | acc])
          {:error, _} -> parse_varbind_list(rest, acc)
        end
      {:error, _} -> {:ok, Enum.reverse(acc)}
    end
  end

  defp parse_single_varbind(data) do
    with {:ok, {oid, rest1}} <- parse_oid(data),
         {:ok, {value, _rest2}} <- parse_value(rest1) do
      {:ok, {oid, :auto, value}}
    else
      _ -> {:error, :invalid_varbind}
    end
  end

  defp parse_oid(<<@object_identifier, length, oid_data::binary-size(length), rest::binary>>) do
    case decode_oid_data(oid_data) do
      {:ok, oid} -> {:ok, {oid, rest}}
      error -> error
    end
  end
  defp parse_oid(_), do: {:error, :invalid_oid}

  defp decode_oid_data(<<first, rest::binary>>) do
    first_subid = div(first, 40)
    second_subid = rem(first, 40)
    
    case decode_oid_subids(rest, [second_subid, first_subid]) do
      {:ok, subids} -> {:ok, Enum.reverse(subids)}
      error -> error
    end
  end
  defp decode_oid_data(_), do: {:error, :invalid_oid_data}

  defp decode_oid_subids(<<>>, acc), do: {:ok, acc}
  defp decode_oid_subids(data, acc) do
    case decode_oid_subid(data, 0) do
      {:ok, {subid, rest}} -> decode_oid_subids(rest, [subid | acc])
      error -> error
    end
  end

  defp decode_oid_subid(<<byte, rest::binary>>, acc) do
    new_acc = (acc <<< 7) + (byte &&& 0x7F)
    if (byte &&& 0x80) == 0 do
      {:ok, {new_acc, rest}}
    else
      decode_oid_subid(rest, new_acc)
    end
  end
  defp decode_oid_subid(<<>>, _), do: {:error, :incomplete_oid}

  defp parse_value(<<@octet_string, length, value::binary-size(length), rest::binary>>) do
    {:ok, {value, rest}}
  end
  defp parse_value(<<@integer, length, value_data::binary-size(length), rest::binary>>) do
    int_value = decode_integer_value(value_data)
    {:ok, {int_value, rest}}
  end
  defp parse_value(<<@null, 0, rest::binary>>) do
    {:ok, {:null, rest}}
  end
  defp parse_value(<<@object_identifier, length, oid_data::binary-size(length), rest::binary>>) do
    case decode_oid_data(oid_data) do
      {:ok, oid_list} -> 
        # Convert list back to string format for consistency
        oid_string = Enum.join(oid_list, ".")
        {:ok, {{:object_identifier, oid_string}, rest}}
      {:error, _} -> {:ok, {{:unknown, oid_data}, rest}}
    end
  end
  defp parse_value(<<tag, length, value::binary-size(length), rest::binary>>) do
    decoded_value = case tag do
      @counter32 -> {:counter32, decode_unsigned_integer(value)}
      @gauge32 -> {:gauge32, decode_unsigned_integer(value)}
      @timeticks -> {:timeticks, decode_unsigned_integer(value)}
      @counter64 -> {:counter64, decode_counter64(value)}
      @ip_address -> {:ip_address, value}
      @opaque_type -> {:opaque, value}
      @no_such_object -> {:no_such_object, nil}
      @no_such_instance -> {:no_such_instance, nil}
      @end_of_mib_view -> {:end_of_mib_view, nil}
      _ -> {:unknown, value}
    end
    {:ok, {decoded_value, rest}}
  end
  defp parse_value(_), do: {:error, :invalid_value}

  defp decode_integer_value(<<byte>>) when byte < 128, do: byte
  defp decode_integer_value(<<byte>>) when byte >= 128, do: byte - 256
  defp decode_integer_value(data) do
    case :binary.decode_unsigned(data, :big) do
      value ->
        bit_size = byte_size(data) * 8
        if value >= (1 <<< (bit_size - 1)) do
          value - (1 <<< bit_size)
        else
          value
        end
    end
  end

  defp decode_unsigned_integer(data) when byte_size(data) <= 4 do
    :binary.decode_unsigned(data, :big)
  end
  defp decode_unsigned_integer(data) when byte_size(data) == 5 do
    # Handle 5-byte case for large 32-bit unsigned values that require leading zero padding
    case data do
      <<0, rest::binary-size(4)>> ->
        # Leading zero byte for unsigned representation, decode the remaining 4 bytes
        :binary.decode_unsigned(rest, :big)
      _ ->
        # If first byte is not zero, this exceeds 32-bit range
        0
    end
  end
  defp decode_unsigned_integer(_), do: 0

  defp decode_counter64(data) when byte_size(data) == 8 do
    :binary.decode_unsigned(data, :big)
  end
  defp decode_counter64(_), do: 0
end