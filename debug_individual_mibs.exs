# Script to test individual MIB files and get accurate error information
# This helps isolate issues that might be confused in batch testing
# Run with: mix run debug_individual_mibs.exs

defmodule IndividualMibTester do
  @mib_files [
    "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/DISMAN-SCHEDULE-MIB.mib",
    "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/IANA-ADDRESS-FAMILY-NUMBERS-MIB.mib",
    "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/IANAifType-MIB.mib",
    "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/RFC1155-SMI.mib",
    "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/RFC1213-MIB.mib"
  ]

  def run do
    IO.puts(String.duplicate("=", 80))
    IO.puts("INDIVIDUAL MIB FILE TESTING")
    IO.puts(String.duplicate("=", 80))
    IO.puts("")

    Enum.each(@mib_files, &test_individual_mib/1)

    IO.puts("")
    IO.puts(String.duplicate("=", 80))
    IO.puts("TESTING COMPLETE")
    IO.puts(String.duplicate("=", 80))
  end

  defp test_individual_mib(file_path) do
    filename = Path.basename(file_path)
    IO.puts("Testing: #{filename}")
    IO.puts(String.duplicate("-", 60))

    case File.read(file_path) do
      {:ok, content} ->
        IO.puts("File read successfully (#{byte_size(content)} bytes)")
        
        try do
          case SnmpLib.MIB.Parser.parse(content) do
            {:ok, result} ->
              IO.puts("✓ PARSING SUCCESS")
              IO.puts("  Result type: #{inspect(result)}")
              if is_map(result) and Map.has_key?(result, :module_name) do
                IO.puts("  Module name: #{result.module_name}")
              end

            {:error, error} ->
              IO.puts("✗ PARSING FAILED")
              IO.puts("  Error: #{inspect(error)}")
              print_detailed_error(error)

            other ->
              IO.puts("✗ UNEXPECTED RESULT")
              IO.puts("  Result: #{inspect(other)}")
          end
        rescue
          exception ->
            IO.puts("✗ EXCEPTION RAISED")
            IO.puts("  Exception: #{inspect(exception)}")
            IO.puts("  Message: #{Exception.message(exception)}")
            if Exception.format_stacktrace(__STACKTRACE__) |> String.length() < 1000 do
              IO.puts("  Stacktrace:")
              IO.puts(Exception.format_stacktrace(__STACKTRACE__) |> String.slice(0, 800))
            end
        end

      {:error, reason} ->
        IO.puts("✗ FILE READ FAILED")
        IO.puts("  Reason: #{inspect(reason)}")
    end

    IO.puts("")
  end

  defp print_detailed_error(error) when is_binary(error) do
    IO.puts("  Error details: #{error}")
  end

  defp print_detailed_error({:parse_error, details}) do
    IO.puts("  Parse error details:")
    case details do
      %{line: line, message: message} ->
        IO.puts("    Line: #{line}")
        IO.puts("    Message: #{message}")
      %{line: line, column: col, message: message} ->
        IO.puts("    Line: #{line}, Column: #{col}")
        IO.puts("    Message: #{message}")
      other ->
        IO.puts("    Details: #{inspect(other)}")
    end
  end

  defp print_detailed_error({:lexer_error, details}) do
    IO.puts("  Lexer error details:")
    case details do
      %{line: line, message: message} ->
        IO.puts("    Line: #{line}")
        IO.puts("    Message: #{message}")
      other ->
        IO.puts("    Details: #{inspect(other)}")
    end
  end

  defp print_detailed_error(error) when is_tuple(error) do
    IO.puts("  Error tuple: #{inspect(error)}")
  end

  defp print_detailed_error(error) do
    IO.puts("  Error (other): #{inspect(error)}")
  end
end

# Run the test
IndividualMibTester.run()