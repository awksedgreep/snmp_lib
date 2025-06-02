#!/usr/bin/env elixir

# Debug function clause issues in SNMP MIB parser
# Specifically look for "Expected OID element, but found integer" pattern

Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser_port.ex")

defmodule FunctionClauseDebugger do
  alias SnmpLib.MIB.Lexer
  alias SnmpLib.MIB.ParserPort

  def run do
    # Let's check if there might be a parse function that expects identifiers but gets integers
    IO.puts("=== Checking function clause issues ===")

    # Create test tokens that might cause function clause errors
    problematic_patterns = [
      # Pattern: integer where identifier expected
      [{:integer, 123, %{line: 1}}, {:symbol, :assign, %{line: 1}}],
      
      # Pattern: identifier where specific keyword expected  
      [{:identifier, "someId", %{line: 1}}, {:keyword, :object, %{line: 1}}],
      
      # Pattern: Malformed OID with integer first
      [{:integer, 1, %{line: 1}}, {:symbol, :open_brace, %{line: 1}}, {:identifier, "test", %{line: 1}}, {:symbol, :close_brace, %{line: 1}}],
      
      # Pattern: OID with unexpected token
      [{:symbol, :open_brace, %{line: 1}}, {:keyword, :integer, %{line: 1}}, {:integer, 1, %{line: 1}}, {:symbol, :close_brace, %{line: 1}}],
    ]

    Enum.with_index(problematic_patterns, 1)
    |> Enum.each(fn {tokens, index} ->
      IO.puts("\n--- Test Pattern #{index} ---")
      IO.puts("Tokens: #{inspect(tokens)}")
      
      # Try calling parse_oid_elements with these tokens
      try do
        # Replicate the parse_oid_elements function call
        result = test_parse_oid_elements(tokens)
        IO.puts("parse_oid_elements result: #{inspect(result)}")
      rescue
        e in FunctionClauseError ->
          IO.puts("✗ FunctionClauseError: #{Exception.message(e)}")
          IO.puts("This could be the source of 'Expected OID element, but found integer'")
        e ->
          IO.puts("✗ Other error: #{Exception.message(e)}")
      end
    end)

    test_docsis_patterns()
  end

  # Helper function that replicates parse_oid_elements
  def test_parse_oid_elements(tokens) do
    parse_oid_elements(tokens, [])
  end

  defp parse_oid_elements([{:symbol, :close_brace, _} | tokens], acc) do
    {:ok, {Enum.reverse(acc), tokens}}
  end

  defp parse_oid_elements([{:identifier, name, _} | tokens], acc) do
    case tokens do
      [{:symbol, :open_paren, _}, {:integer, value, _}, {:symbol, :close_paren, _} | rest] ->
        element = %{name: name, value: value}
        parse_oid_elements(rest, [element | acc])
      _ ->
        element = %{name: name}
        parse_oid_elements(tokens, [element | acc])
    end
  end

  defp parse_oid_elements([{:integer, value, _} | tokens], acc) do
    element = %{value: value}
    parse_oid_elements(tokens, [element | acc])
  end

  defp parse_oid_elements(tokens, _acc) do
    {:error, "Invalid OID element: #{inspect(hd(tokens))}"}
  end

  defp test_docsis_patterns do
    # Now let's look for parsing contexts where integers might be wrongly expected as OID elements
    IO.puts("\n=== Testing real DOCSIS MIB parsing contexts ===")

    # Test various DOCSIS MIB constructs to see where the error might occur
    docsis_patterns = [
      # Simple OID assignment
      "docsDevBase OBJECT IDENTIFIER ::= { docsDevMIBObjects 1 }",
      
      # OBJECT-TYPE with OID (simplified)
      "docsDevRole OBJECT-TYPE ::= { docsDevBase 1 }",
      
      # MODULE-IDENTITY (simplified)
      "docsDev MODULE-IDENTITY ::= { mib-2 69 }",
    ]

    Enum.with_index(docsis_patterns, 1)
    |> Enum.each(fn {pattern, index} ->
      IO.puts("\n--- DOCSIS Pattern #{index} ---")
      IO.puts("Input: #{pattern}")
      
      case Lexer.tokenize(pattern) do
        {:ok, tokens} ->
          IO.puts("✓ Tokenized successfully (#{length(tokens)} tokens)")
          
          # Look for potential issues with integer/identifier confusion
          integer_positions = Enum.with_index(tokens)
          |> Enum.filter(fn {token, _} -> 
            case token do
              {:integer, _, _} -> true
              _ -> false
            end
          end)
          |> Enum.map(fn {token, pos} -> {pos, token} end)
          
          identifier_positions = Enum.with_index(tokens)
          |> Enum.filter(fn {token, _} -> 
            case token do
              {:identifier, _, _} -> true
              _ -> false
            end
          end)
          |> Enum.map(fn {token, pos} -> {pos, token} end)
          
          IO.puts("Integer tokens at positions: #{inspect(integer_positions)}")
          IO.puts("Identifier tokens at positions: #{inspect(identifier_positions)}")
          
          # Check for potential parsing issues around assignment operators
          assign_positions = Enum.with_index(tokens)
          |> Enum.filter(fn {token, _} -> 
            case token do
              {:symbol, :assign, _} -> true
              _ -> false
            end
          end)
          |> Enum.map(fn {_, pos} -> pos end)
          
          Enum.each(assign_positions, fn pos ->
            IO.puts("\nAssignment at position #{pos}:")
            start_pos = max(0, pos - 2)
            end_pos = min(length(tokens) - 1, pos + 8)
            context = Enum.slice(tokens, start_pos, end_pos - start_pos + 1)
            
            Enum.with_index(context, start_pos)
            |> Enum.each(fn {token, idx} ->
              marker = if idx == pos, do: " <-- ASSIGN", else: ""
              IO.puts("  #{idx}: #{inspect(token)}#{marker}")
            end)
            
            # Try to extract and parse the OID part
            if pos + 1 < length(tokens) do
              remaining_tokens = Enum.drop(tokens, pos + 1)
              case remaining_tokens do
                [{:symbol, :open_brace, _} | oid_tokens] ->
                  IO.puts("Found OID tokens starting after assignment:")
                  oid_content = Enum.take_while(oid_tokens, fn token ->
                    case token do
                      {:symbol, :close_brace, _} -> false
                      _ -> true
                    end
                  end)
                  
                  IO.puts("OID content: #{inspect(oid_content)}")
                  
                  try do
                    result = test_parse_oid_elements(oid_content ++ [{:symbol, :close_brace, %{line: 1}}])
                    case result do
                      {:ok, {elements, _}} ->
                        IO.puts("✓ OID parsed: #{inspect(elements)}")
                      {:error, reason} ->
                        IO.puts("✗ OID parse failed: #{reason}")
                    end
                  rescue
                    e ->
                      IO.puts("✗ OID parse exception: #{Exception.message(e)}")
                  end
                _ ->
                  IO.puts("No OID brace found after assignment")
              end
            end
          end)
          
        {:error, reason} ->
          IO.puts("✗ Tokenization failed: #{reason}")
      end
    end)
  end
end

# Run the debugger
FunctionClauseDebugger.run()