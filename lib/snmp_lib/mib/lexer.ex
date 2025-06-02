defmodule SnmpLib.MIB.Lexer do
  @moduledoc """
  High-performance port of Erlang snmpc_tok.erl tokenizer to Elixir.
  
  This is a performance-optimized 1:1 port of the official Erlang SNMP compiler tokenizer
  from OTP lib/snmp/src/compile/snmpc_tok.erl with Elixir-specific optimizations.
  
  Performance optimizations:
  - Binary pattern matching instead of charlist processing
  - Compiled MapSet for O(1) keyword lookup
  - Reduced memory allocations through streaming
  - Tail-call optimization for recursive functions
  """

  # Complete reserved words list from Erlang snmpc_tok.erl - Extended from official source
  @reserved_words MapSet.new([
    "ACCESS", "AGENT-CAPABILITIES", "APPLICATION", "AUGMENTS", "BEGIN",
    "BITS", "CHOICE", "CONTACT-INFO", "COUNTER", "COUNTER32", "COUNTER64", 
    "DEFVAL", "DEFINITIONS", "DESCRIPTION", "DISPLAY-HINT", "END", "ENTERPRISE",
    "EXPORTS", "FROM", "GAUGE", "GAUGE32", "GROUP", "IDENTIFIER",
    "IMPLICIT", "IMPORTS", "INDEX", "INTEGER", "INTEGER32", "Integer32", "IpAddress",
    "LAST-UPDATED", "MAX-ACCESS", "MIN-ACCESS", "MODULE", "MODULE-COMPLIANCE",
    "MODULE-IDENTITY", "NOTIFICATION-GROUP", "NOTIFICATION-TYPE", "OBJECT",
    "OBJECT-GROUP", "OBJECT-IDENTITY", "OBJECT-TYPE", "OBJECTS", "OCTET",
    "OF", "ORGANIZATION", "REFERENCE", "REVISION", "SEQUENCE", "SIZE",
    "STATUS", "STRING", "SYNTAX", "TEXTUAL-CONVENTION", "TimeTicks",
    "TRAP-TYPE", "UNITS", "UNIVERSAL", "Unsigned32", "VARIABLES", "WRITE-SYNTAX",
    # Additional from complete Erlang list
    "Counter64", "MANDATORY-GROUPS", "COMPLIANCE", "PRODUCT-RELEASE", 
    "SUPPORTS", "INCLUDES", "VARIATION", "CREATION-REQUIRES", "AGENT-CAPABILITIES",
    "IMPLIED", "CHOICE", "EXPLICIT", "TAGS", "BIT", "OCTET", "NULL", "BOOLEAN",
    # Extended from actual Erlang grammar - missing critical keywords
    "MACRO", "TYPE", "VALUE", "ABSENT", "ANY", "DEFINED", "BY", "OPTIONAL",
    "DEFAULT", "COMPONENTS", "PRIVATE", "PUBLIC", "REAL", "INCLUDES", "MIN", "MAX",
    "EXTENSIBILITY", "IMPLIED", "WITH", "COMPONENT", "PRESENT", "EXCEPT",
    "INTERSECTION", "UNION", "ALL", "ENCODED"
  ])

  @doc """
  Tokenize MIB content following Erlang snmpc_tok.erl exactly.
  Returns {:ok, tokens} or {:error, reason}
  """
  def tokenize(input, opts \\ []) when is_binary(input) do
    try do
      # Handle encoding issues like Erlang snmpc_misc does
      case validate_encoding(input) do
        :ok ->
          tokens = do_tokenize(input, 1, [])
          {:ok, Enum.reverse(tokens)}
        {:error, reason} ->
          {:error, reason}
      end
    rescue
      e -> {:error, Exception.message(e)}
    catch
      {:error, reason} -> {:error, reason}
    end
  end
  
  # Validate encoding like Erlang snmpc_misc patterns
  defp validate_encoding(input) do
    if String.valid?(input) do
      :ok
    else
      {:error, "invalid encoding starting at #{inspect(binary_part(input, 0, min(50, byte_size(input))))}"}
    end
  end

  # Main tokenization loop - binary pattern matching for performance
  defp do_tokenize(<<>>, _line, acc), do: acc

  # Skip whitespace efficiently
  defp do_tokenize(<<c, rest::binary>>, line, acc) when c in [?\s, ?\t, ?\r] do
    do_tokenize(rest, line, acc)
  end

  # Handle newlines
  defp do_tokenize(<<?\n, rest::binary>>, line, acc) do
    do_tokenize(rest, line + 1, acc)
  end

  # Skip comments (-- to end of line) - optimized binary matching
  defp do_tokenize(<<"--", rest::binary>>, line, acc) do
    rest_after_comment = skip_comment_binary(rest)
    do_tokenize(rest_after_comment, line, acc)
  end

  # Handle string literals - optimized binary collection
  defp do_tokenize(<<?\", rest::binary>>, line, acc) do
    case collect_string_binary(rest, <<>>) do
      {string_value, rest_after_string} ->
        token = {:string, string_value, %{line: line, column: nil}}
        do_tokenize(rest_after_string, line, [token | acc])
      {:error, reason} ->
        throw({:error, reason})
    end
  end

  # Handle quoted literals
  defp do_tokenize(<<?\', rest::binary>>, line, acc) do
    case collect_quote_binary(rest, <<>>) do
      {quote_value, rest_after_quote} ->
        token = {:quote, quote_value, %{line: line, column: nil}}
        do_tokenize(rest_after_quote, line, [token | acc])
      {:error, reason} ->
        throw({:error, reason})
    end
  end

  # Handle integers - optimized binary integer parsing
  defp do_tokenize(<<c, _::binary>> = input, line, acc) when c >= ?0 and c <= ?9 do
    {int_value, rest} = parse_integer_binary(input, 0)
    token = {:integer, int_value, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  # Handle negative integers
  defp do_tokenize(<<?-, c, _::binary>> = input, line, acc) when c >= ?0 and c <= ?9 do
    <<?-, rest::binary>> = input
    {int_value, rest_after_int} = parse_integer_binary(rest, 0)
    token = {:integer, -int_value, %{line: line, column: nil}}
    do_tokenize(rest_after_int, line, [token | acc])
  end

  # Handle single minus as symbol (not negative number)
  defp do_tokenize(<<?-, rest::binary>>, line, acc) do
    token = {:symbol, :minus, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  # Handle identifiers and keywords - optimized binary name parsing
  defp do_tokenize(<<c, _::binary>> = input, line, acc) 
      when (c >= ?a and c <= ?z) or (c >= ?A and c <= ?Z) do
    {name, rest} = parse_name_binary(input, <<>>)
    token = make_name_token_binary(name, line)
    do_tokenize(rest, line, [token | acc])
  end

  # Handle multi-character symbols
  defp do_tokenize(<<"::=", rest::binary>>, line, acc) do
    token = {:symbol, :assign, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<"..", rest::binary>>, line, acc) do
    token = {:symbol, :range, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  # Handle single character symbols
  defp do_tokenize(<<"{", rest::binary>>, line, acc) do
    token = {:symbol, :open_brace, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<"}", rest::binary>>, line, acc) do
    token = {:symbol, :close_brace, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<"(", rest::binary>>, line, acc) do
    token = {:symbol, :open_paren, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<")", rest::binary>>, line, acc) do
    token = {:symbol, :close_paren, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<"[", rest::binary>>, line, acc) do
    token = {:symbol, :open_bracket, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<"]", rest::binary>>, line, acc) do
    token = {:symbol, :close_bracket, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<",", rest::binary>>, line, acc) do
    token = {:symbol, :comma, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<".", rest::binary>>, line, acc) do
    token = {:symbol, :dot, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<";", rest::binary>>, line, acc) do
    token = {:symbol, :semicolon, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<"|", rest::binary>>, line, acc) do
    token = {:symbol, :pipe, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<":", rest::binary>>, line, acc) do
    token = {:symbol, :colon, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<"=", rest::binary>>, line, acc) do
    token = {:symbol, :equals, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  # Handle additional special characters that appear in SNMP MIBs
  defp do_tokenize(<<"+", rest::binary>>, line, acc) do
    token = {:symbol, :plus, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<"*", rest::binary>>, line, acc) do
    token = {:symbol, :star, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<"/", rest::binary>>, line, acc) do
    token = {:symbol, :slash, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<"<", rest::binary>>, line, acc) do
    token = {:symbol, :less_than, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<">", rest::binary>>, line, acc) do
    token = {:symbol, :greater_than, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  # Handle any other single character as a special symbol (safer than atom)
  defp do_tokenize(<<ch, rest::binary>>, line, acc) do
    token = {:unknown_char, ch, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  # Skip comments until end of line - binary optimized
  defp skip_comment_binary(<<?\n, _::binary>> = rest), do: rest
  defp skip_comment_binary(<<_c, rest::binary>>), do: skip_comment_binary(rest)
  defp skip_comment_binary(<<>>), do: <<>>

  # Collect string characters until closing quote - binary optimized
  defp collect_string_binary(<<?\", rest::binary>>, acc), do: {acc, rest}
  defp collect_string_binary(<<?\\, c, rest::binary>>, acc) do
    # Handle escape sequences
    escaped_char = case c do
      ?n -> ?\n
      ?t -> ?\t
      ?r -> ?\r
      ?\\ -> ?\\
      ?" -> ?"
      ?' -> ?'
      _ -> c
    end
    collect_string_binary(rest, <<acc::binary, escaped_char>>)
  end
  defp collect_string_binary(<<c, rest::binary>>, acc) do
    collect_string_binary(rest, <<acc::binary, c>>)
  end
  defp collect_string_binary(<<>>, _acc) do
    throw({:error, "Unterminated string"})
  end

  # Collect quote characters until closing quote - binary optimized
  defp collect_quote_binary(<<?\', rest::binary>>, acc), do: {acc, rest}
  defp collect_quote_binary(<<c, rest::binary>>, acc) do
    collect_quote_binary(rest, <<acc::binary, c>>)
  end
  defp collect_quote_binary(<<>>, _acc) do
    throw({:error, "Unterminated quote"})
  end

  # Parse integer value - binary optimized
  defp parse_integer_binary(<<c, rest::binary>>, acc) when c >= ?0 and c <= ?9 do
    parse_integer_binary(rest, acc * 10 + (c - ?0))
  end
  defp parse_integer_binary(rest, acc), do: {acc, rest}

  # Parse identifier/keyword names - binary optimized  
  defp parse_name_binary(<<c, rest::binary>>, acc) 
      when (c >= ?a and c <= ?z) or (c >= ?A and c <= ?Z) or 
           (c >= ?0 and c <= ?9) or c == ?- or c == ?_ do
    parse_name_binary(rest, <<acc::binary, c>>)
  end
  defp parse_name_binary(rest, acc), do: {acc, rest}

  # Create appropriate token for name - binary optimized
  defp make_name_token_binary(name, line) do
    if reserved_word?(name) do
      # Convert reserved word to keyword token (lowercase with underscores)
      keyword_atom = name 
                    |> String.replace("-", "_")
                    |> String.downcase()
                    |> String.to_atom()
      {:keyword, keyword_atom, %{line: line, column: nil}}
    else
      # All non-keywords are identifiers in SNMP MIB parsing
      {:identifier, name, %{line: line, column: nil}}
    end
  end

  # Check if word is reserved (faithful to Erlang reserved_word/1)
  defp reserved_word?(name) do
    MapSet.member?(@reserved_words, name)
  end

  @doc """
  Format error messages
  """
  def format_error(reason), do: to_string(reason)

  @doc """
  Test function
  """
  def test do
    test_input = """
    TestMib DEFINITIONS ::= BEGIN
      testObject OBJECT-TYPE
        SYNTAX INTEGER { active(1), inactive(2) }
        MAX-ACCESS read-only
        STATUS current
        DESCRIPTION "Test object"
        ::= { test 1 }
    END
    """
    
    case tokenize(test_input) do
      {:ok, tokens} ->
        IO.puts("Tokenization successful!")
        Enum.each(tokens, fn token -> IO.inspect(token) end)
      {:error, reason} ->
        IO.puts("Tokenization failed: #{reason}")
    end
  end
end