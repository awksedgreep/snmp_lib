#!/usr/bin/env elixir

# Test real OID parsing issue with DOCSIS MIBs

Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser_port.ex")

alias SnmpLib.MIB.Lexer
alias SnmpLib.MIB.ParserPort

# Read the actual DOCSIS MIB
mib_content = File.read!("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
lines = String.split(mib_content, "\n")

# Find lines around the OID assignment
oid_lines = Enum.with_index(lines, 1)
|> Enum.filter(fn {line, _num} -> String.contains?(line, "::=") end)
|> Enum.take(5)

IO.puts("=== Found OID assignment lines ===")
Enum.each(oid_lines, fn {line, num} ->
  IO.puts("Line #{num}: #{String.trim(line)}")
end)

# Test each OID assignment
Enum.each(oid_lines, fn {line, line_num} ->
  IO.puts("\n" <> String.duplicate("=", 80))
  IO.puts("Testing line #{line_num}: #{String.trim(line)}")
  IO.puts(String.duplicate("=", 80))
  
  case Lexer.tokenize(line) do
    {:ok, tokens} ->
      IO.puts("Tokens: #{inspect(tokens, pretty: true)}")
      
      # Try to parse using ParserPort functions
      try do
        # Check if there's a parse_oid_assignment function
        if function_exported?(ParserPort, :parse_oid_assignment, 1) do
          case ParserPort.parse_oid_assignment(tokens) do
            {:ok, result} ->
              IO.puts("✓ Parse successful: #{inspect(result)}")
            {:error, reason} ->
              IO.puts("✗ Parse error: #{reason}")
          end
        else
          IO.puts("No parse_oid_assignment function found")
        end
      rescue
        e ->
          IO.puts("✗ Exception: #{Exception.message(e)}")
      end
      
    {:error, reason} ->
      IO.puts("✗ Tokenization failed: #{reason}")
  end
end)

# Test a complex snippet with multiple constructs
IO.puts("\n" <> String.duplicate("=", 80))
IO.puts("Testing complex MIB snippet")
IO.puts(String.duplicate("=", 80))

complex_snippet = """
docsDev MODULE-IDENTITY
        LAST-UPDATED    "200612200000Z" -- December 20, 2006
        ORGANIZATION    "IETF IP over Cable Data Network Working Group"
        CONTACT-INFO
            "Rich Woundy"
        DESCRIPTION
            "This is the MIB Module for DOCSIS-compliant cable modems"
        ::= { mib-2 69 }

docsDevMIBObjects  OBJECT IDENTIFIER ::= { docsDev 1 }

docsDevBase OBJECT IDENTIFIER ::= { docsDevMIBObjects 1 }
"""

case Lexer.tokenize(complex_snippet) do
  {:ok, tokens} ->
    IO.puts("Complex snippet tokenized successfully!")
    IO.puts("Token count: #{length(tokens)}")
    
    # Show tokens around ::= assignments
    assignment_indices = Enum.with_index(tokens)
    |> Enum.filter(fn {token, _} -> 
      case token do
        {:symbol, :assign, _} -> true
        _ -> false
      end
    end)
    |> Enum.map(fn {_, index} -> index end)
    
    IO.puts("Found #{length(assignment_indices)} assignment operators")
    
    Enum.each(assignment_indices, fn index ->
      context_start = max(0, index - 2)
      context_end = min(length(tokens) - 1, index + 5)
      context_tokens = Enum.slice(tokens, context_start, context_end - context_start + 1)
      
      IO.puts("\nAssignment context around index #{index}:")
      IO.puts("#{inspect(context_tokens, pretty: true)}")
    end)
    
  {:error, reason} ->
    IO.puts("Complex snippet tokenization failed: #{reason}")
end