#!/usr/bin/env elixir

# Script to clean up PDU.ex file by removing unused functions and adding missing ones

defmodule PDUCleanup do
  def run do
    file_path = "/Users/mcotner/Documents/elixir/snmp_lib/lib/snmp_lib/pdu.ex"
    
    content = File.read!(file_path)
    
    # Add the missing encode_oid_fast function after parse_ber_length functions
    missing_functions = """
  
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
"""
    
    # Find the insertion point (after parse_ber_length functions)
    insertion_point = ~r/defp parse_ber_length\(_\), do: \{:error, :invalid_length_format\}/
    
    new_content = Regex.replace(insertion_point, content, fn match ->
      match <> missing_functions
    end)
    
    # Remove unused functions
    unused_functions = [
      ~r/\s*defp validate_pdu_type.*?end\n/s,
      ~r/\s*defp validate_pdu_request_id.*?end\n/s,
      ~r/\s*defp validate_pdu_varbinds.*?end\n/s,
      ~r/\s*defp validate_pdu_bulk_fields.*?end\n/s,
      ~r/\s*defp pdu_type_to_tag.*?end\n/s,
      ~r/\s*defp tag_to_pdu_type.*?end\n/s,
      ~r/\s*defp convert_varbinds_to_legacy.*?end\n/s,
      ~r/\s*defp convert_legacy_varbinds.*?end\n/s,
      ~r/\s*defp normalize_oid_for_legacy.*?end\n/s
    ]
    
    cleaned_content = Enum.reduce(unused_functions, new_content, fn regex, acc ->
      Regex.replace(regex, acc, "")
    end)
    
    # Write the cleaned content back
    File.write!(file_path, cleaned_content)
    
    IO.puts("✅ PDU cleanup completed!")
    IO.puts("- Added missing encode_oid_fast function and helpers")
    IO.puts("- Removed 9 unused legacy functions")
  end
end

PDUCleanup.run()
