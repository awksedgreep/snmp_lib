#!/usr/bin/env elixir

# Debug script to isolate OID parsing issues in SNMP MIB parser
# Focus on reproducing "Expected OID element, but found integer" error

# Load the modules we need
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser_port.ex")

defmodule OidDebugger do
  alias SnmpLib.MIB.Lexer
  alias SnmpLib.MIB.ParserPort

  # Simple test cases from DOCSIS MIBs
  @test_cases [
    # Simple OID assignment
    "docsDev ::= { mib-2 69 }",
    
    # Nested OID assignment  
    "docsDevMIBObjects ::= { docsDev 1 }",
    
    # Basic OID with named parent
    "docsDevBase ::= { docsDevMIBObjects 1 }",
    
    # Mixed named and numeric
    "docsDevRole ::= { docsDevBase 1 }"
  ]

  def run do
    IO.puts("=== OID Parsing Debug Script ===\n")

    Enum.with_index(@test_cases, 1)
    |> Enum.each(fn {test_case, index} ->
      test_single_case(test_case, index)
    end)
    
    test_docsis_snippet()
  end

  defp test_single_case(test_case, index) do
    IO.puts("Test Case #{index}: #{test_case}")
    IO.puts("=" <> String.duplicate("=", String.length(test_case) + 12))
    
    # Step 1: Tokenize
    IO.puts("1. Tokenizing...")
    case Lexer.tokenize(test_case) do
      {:ok, tokens} ->
        IO.puts("   Tokens: #{inspect(tokens, pretty: true)}")
        
        # Step 2: Try to parse OID assignment
        IO.puts("\n2. Parsing OID assignment...")
        
        # Look for the ::= pattern and extract OID value
        case find_oid_assignment(tokens) do
          {:ok, oid_tokens} ->
            IO.puts("   OID tokens found: #{inspect(oid_tokens)}")
            
            # Step 3: Try to parse the OID elements
            IO.puts("\n3. Parsing OID elements...")
            result = parse_oid_elements_debug(oid_tokens)
            IO.puts("   Result: #{inspect(result)}")
            
          {:error, reason} ->
            IO.puts("   Error finding OID assignment: #{reason}")
        end
        
      {:error, reason} ->
        IO.puts("   Tokenization failed: #{reason}")
    end
    
    IO.puts("\n" <> String.duplicate("-", 80) <> "\n")
  end

  # Helper function to find OID assignment pattern
  defp find_oid_assignment(tokens) do
    case find_assignment_operator(tokens) do
      {:ok, remaining_tokens} ->
        case remaining_tokens do
          [{:symbol, :open_brace, _} | rest] ->
            extract_until_close_brace(rest, [])
          _ ->
            {:error, "Expected { after ::= but got #{inspect(hd(remaining_tokens))}"}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp find_assignment_operator([{:symbol, :assign, _} | rest]), do: {:ok, rest}
  defp find_assignment_operator([_ | rest]), do: find_assignment_operator(rest)
  defp find_assignment_operator([]), do: {:error, "No assignment operator found"}

  defp extract_until_close_brace([{:symbol, :close_brace, _} | _], acc) do
    {:ok, Enum.reverse(acc)}
  end
  defp extract_until_close_brace([token | rest], acc) do
    extract_until_close_brace(rest, [token | acc])
  end
  defp extract_until_close_brace([], _acc) do
    {:error, "No closing brace found"}
  end

  # Debug version of parse_oid_elements that shows each step
  defp parse_oid_elements_debug(tokens) do
    IO.puts("   Starting OID element parsing with tokens: #{inspect(tokens)}")
    parse_oid_elements_step(tokens, [], 1)
  end

  defp parse_oid_elements_step([], acc, _step) do
    IO.puts("   Step end: Reached end of tokens")
    {:ok, Enum.reverse(acc)}
  end

  defp parse_oid_elements_step([{:identifier, name, line_info} | tokens], acc, step) do
    line = if is_map(line_info), do: line_info.line, else: line_info
    IO.puts("   Step #{step}: Found identifier '#{name}' at line #{line}")
    
    case tokens do
      [{:symbol, :open_paren, _}, {:integer, value, _}, {:symbol, :close_paren, _} | rest] ->
        element = %{name: name, value: value}
        IO.puts("   Step #{step}: Created named element with value: #{inspect(element)}")
        parse_oid_elements_step(rest, [element | acc], step + 1)
      _ ->
        element = %{name: name}
        IO.puts("   Step #{step}: Created named element: #{inspect(element)}")
        parse_oid_elements_step(tokens, [element | acc], step + 1)
    end
  end

  defp parse_oid_elements_step([{:integer, value, line_info} | tokens], acc, step) do
    line = if is_map(line_info), do: line_info.line, else: line_info
    IO.puts("   Step #{step}: Found integer #{value} at line #{line}")
    element = %{value: value}
    IO.puts("   Step #{step}: Created numeric element: #{inspect(element)}")
    parse_oid_elements_step(tokens, [element | acc], step + 1)
  end

  defp parse_oid_elements_step([token | _], _acc, step) do
    IO.puts("   Step #{step}: Unexpected token: #{inspect(token)}")
    {:error, "Invalid OID element at step #{step}: #{inspect(token)}"}
  end

  defp test_docsis_snippet do
    IO.puts("=== Testing with actual DOCSIS MIB snippet ===\n")

    # Test with a real snippet from DOCS-CABLE-DEVICE-MIB
    docsis_snippet = """
    docsDev MODULE-IDENTITY
            LAST-UPDATED    "200612200000Z" -- December 20, 2006
            ORGANIZATION    "IETF IP over Cable Data Network Working Group"
            CONTACT-INFO
                "        Rich Woundy"
            DESCRIPTION
                "This is the MIB Module for DOCSIS-compliant cable modems"
            ::= { mib-2 69 }
    """

    IO.puts("Testing DOCSIS MIB snippet:")
    IO.puts(docsis_snippet)

    case Lexer.tokenize(docsis_snippet) do
      {:ok, tokens} ->
        IO.puts("Tokenization successful!")
        IO.puts("Token count: #{length(tokens)}")
        
        # Show last few tokens to see the OID assignment
        last_tokens = Enum.take(tokens, -10)
        IO.puts("Last 10 tokens: #{inspect(last_tokens, pretty: true)}")
        
        case find_oid_assignment(tokens) do
          {:ok, oid_tokens} ->
            IO.puts("OID tokens: #{inspect(oid_tokens)}")
            result = parse_oid_elements_debug(oid_tokens)
            IO.puts("Parse result: #{inspect(result)}")
          {:error, reason} ->
            IO.puts("Error: #{reason}")
        end
        
      {:error, reason} ->
        IO.puts("Tokenization failed: #{reason}")
    end
  end
end

# Run the debugger
OidDebugger.run()