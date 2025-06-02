#!/usr/bin/env elixir

# Test edge cases that might cause "Expected OID element, but found integer" error

Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser_port.ex")

defmodule OidElementTester do
  # Replicate the exact parse_oid_elements function from parser_port.ex
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

  def run_tests do
    IO.puts("=== Testing OID Element Edge Cases ===\n")

    test_cases = [
      # Normal cases
      {[{:identifier, "mib-2", %{line: 1}}, {:integer, 69, %{line: 1}}, {:symbol, :close_brace, %{line: 1}}], "Normal: identifier + integer"},
      
      {[{:integer, 1, %{line: 1}}, {:integer, 2, %{line: 1}}, {:symbol, :close_brace, %{line: 1}}], "Normal: two integers"},
      
      {[{:identifier, "parent", %{line: 1}}, {:symbol, :open_paren, %{line: 1}}, {:integer, 5, %{line: 1}}, {:symbol, :close_paren, %{line: 1}}, {:symbol, :close_brace, %{line: 1}}], "Normal: named with value"},
      
      # Edge cases that might cause issues
      {[{:keyword, :integer, %{line: 1}}, {:symbol, :close_brace, %{line: 1}}], "Edge: keyword 'integer' token"},
      
      {[{:string, "some string", %{line: 1}}, {:symbol, :close_brace, %{line: 1}}], "Edge: string token"},
      
      {[{:symbol, :open_paren, %{line: 1}}, {:symbol, :close_brace, %{line: 1}}], "Edge: unexpected symbol"},
      
      {[{:identifier, "name", %{line: 1}}, {:symbol, :open_paren, %{line: 1}}, {:string, "not-integer", %{line: 1}}, {:symbol, :close_paren, %{line: 1}}, {:symbol, :close_brace, %{line: 1}}], "Edge: name with string in parens"},
      
      {[{:identifier, "name", %{line: 1}}, {:symbol, :open_paren, %{line: 1}}, {:symbol, :close_brace, %{line: 1}}], "Edge: name with incomplete parens"},
      
      # Token pattern that might be interpreted wrong
      {[{:integer, 1, %{line: 1}}, {:identifier, "unexpected", %{line: 1}}, {:symbol, :close_brace, %{line: 1}}], "Edge: integer followed by identifier"},
    ]

    Enum.with_index(test_cases, 1)
    |> Enum.each(fn {{tokens, description}, index} ->
      IO.puts("Test #{index}: #{description}")
      IO.puts("Input tokens: #{inspect(tokens)}")
      
      result = test_parse_oid_elements(tokens)
      case result do
        {:ok, {elements, remaining}} ->
          IO.puts("✓ Success: #{inspect(elements)}")
          IO.puts("  Remaining: #{inspect(remaining)}")
        {:error, reason} ->
          IO.puts("✗ Error: #{reason}")
      end
      
      IO.puts(String.duplicate("-", 60))
    end)
  end
end

OidElementTester.run_tests()

# Now test with actual DOCSIS MIB patterns
IO.puts("\n=== Testing with actual DOCSIS MIB tokens ===")

alias SnmpLib.MIB.Lexer

# Test the specific patterns we found in the MIB
test_strings = [
  "{ mib-2 69 }",
  "{ docsDev 1 }",
  "{ docsDevMIBObjects 1 }",
  "{ iso(1) org(3) dod(6) internet(1) mgmt(2) 1 }",  # A more complex OID
]

Enum.each(test_strings, fn test_string ->
  IO.puts("\nTesting string: #{test_string}")
  
  case Lexer.tokenize(test_string) do
    {:ok, tokens} ->
      IO.puts("Tokens: #{inspect(tokens)}")
      
      # Extract the tokens between braces
      case tokens do
        [{:symbol, :open_brace, _} | rest] ->
          # Find the close brace and extract elements
          brace_content = Enum.take_while(rest, fn token ->
            case token do
              {:symbol, :close_brace, _} -> false
              _ -> true
            end
          end)
          
          IO.puts("OID elements: #{inspect(brace_content)}")
          result = OidElementTester.test_parse_oid_elements(brace_content ++ [{:symbol, :close_brace, %{line: 1}}])
          
          case result do
            {:ok, {elements, _}} ->
              IO.puts("✓ Parsed successfully: #{inspect(elements)}")
            {:error, reason} ->
              IO.puts("✗ Parse failed: #{reason}")
          end
        _ ->
          IO.puts("No opening brace found")
      end
      
    {:error, reason} ->
      IO.puts("Tokenization failed: #{reason}")
  end
end)