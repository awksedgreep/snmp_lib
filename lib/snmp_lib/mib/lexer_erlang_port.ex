defmodule SnmpLib.MIB.LexerErlangPort do
  @moduledoc """
  Direct 1:1 port of Erlang snmpc_tok.erl tokenizer to Elixir.
  
  This is a faithful port of the official Erlang SNMP compiler tokenizer
  from OTP lib/snmp/src/compile/snmpc_tok.erl
  
  Focuses on correctness over performance to match Erlang behavior exactly.
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
  def tokenize(input) when is_binary(input) do
    try do
      # Handle encoding issues like Erlang snmpc_misc does
      case validate_encoding(input) do
        :ok ->
          char_list = String.to_charlist(input)
          tokens = do_tokenize(char_list, 1, [])
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

  # Main tokenization loop - faithful port of Erlang tokenise/1
  defp do_tokenize([], _line, acc), do: acc

  # Skip whitespace (space, tab, carriage return)
  defp do_tokenize([?\s | rest], line, acc), do: do_tokenize(rest, line, acc)
  defp do_tokenize([?\t | rest], line, acc), do: do_tokenize(rest, line, acc) 
  defp do_tokenize([?\r | rest], line, acc), do: do_tokenize(rest, line, acc)

  # Handle newlines - increment line counter
  defp do_tokenize([?\n | rest], line, acc), do: do_tokenize(rest, line + 1, acc)

  # Handle comments: -- to end of line (Erlang style)
  defp do_tokenize([?-, ?- | rest], line, acc) do
    remaining = skip_comment(rest)
    do_tokenize(remaining, line, acc)
  end

  # Handle string literals with double quotes
  defp do_tokenize([?" | rest], line, acc) do
    case collect_string(?", rest, [], line) do
      {{:string, string_value, new_line}, remaining} ->
        token = {:string, string_value, %{line: new_line, column: nil}}
        do_tokenize(remaining, new_line, [token | acc])
      {:error, reason} ->
        throw({:error, reason})
    end
  end

  # Handle quoted literals with single quotes  
  defp do_tokenize([?' | rest], line, acc) do
    case collect_string(?', rest, [], line) do
      {{:quote, quote_value, new_line}, remaining} ->
        token = {:quote, quote_value, %{line: new_line, column: nil}}
        do_tokenize(remaining, new_line, [token | acc])
      {:error, reason} ->
        throw({:error, reason})
    end
  end

  # Handle integers (including negative) - Enhanced number parsing
  defp do_tokenize([ch | rest], line, acc) when ch >= ?0 and ch <= ?9 do
    {int_value, remaining} = get_integer(rest, [ch])
    token = {:integer, int_value, %{line: line, column: nil}}
    do_tokenize(remaining, line, [token | acc])
  end

  # Handle negative integers - check for minus followed by digit
  defp do_tokenize([?-, ch | rest], line, acc) when ch >= ?0 and ch <= ?9 do
    {int_value, remaining} = get_integer(rest, [ch])
    token = {:integer, -int_value, %{line: line, column: nil}}
    do_tokenize(remaining, line, [token | acc])
  end

  # Handle single minus as symbol (not negative number)
  defp do_tokenize([?- | rest], line, acc) do
    token = {:symbol, :minus, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  # Handle lowercase atoms/identifiers (following Erlang pattern)
  defp do_tokenize([ch | rest], line, acc) when ch >= ?a and ch <= ?z do
    {name, remaining} = get_name([ch], rest)
    token = make_name_token(:atom, name, line)
    do_tokenize(remaining, line, [token | acc])
  end

  # Handle uppercase variables/identifiers  
  defp do_tokenize([ch | rest], line, acc) when ch >= ?A and ch <= ?Z do
    {name, remaining} = get_name([ch], rest)
    token = make_name_token(:variable, name, line)
    do_tokenize(remaining, line, [token | acc])
  end

  # Handle multi-character symbols first (::=, ..)
  defp do_tokenize([?:, ?:, ?= | rest], line, acc) do
    token = {:symbol, :assign, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize([?., ?. | rest], line, acc) do
    token = {:symbol, :range, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  # Handle single character symbols (exact Erlang mapping)
  defp do_tokenize([?{ | rest], line, acc) do
    token = {:symbol, :open_brace, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize([?} | rest], line, acc) do
    token = {:symbol, :close_brace, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize([?( | rest], line, acc) do
    token = {:symbol, :open_paren, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize([?) | rest], line, acc) do
    token = {:symbol, :close_paren, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize([?[ | rest], line, acc) do
    token = {:symbol, :open_bracket, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize([?] | rest], line, acc) do
    token = {:symbol, :close_bracket, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize([?, | rest], line, acc) do
    token = {:symbol, :comma, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize([?. | rest], line, acc) do
    token = {:symbol, :dot, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize([?; | rest], line, acc) do
    token = {:symbol, :semicolon, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize([?| | rest], line, acc) do
    token = {:symbol, :pipe, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize([?: | rest], line, acc) do
    token = {:symbol, :colon, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize([?= | rest], line, acc) do
    token = {:symbol, :equals, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  # Handle additional special characters that appear in SNMP MIBs
  defp do_tokenize([?+ | rest], line, acc) do
    token = {:symbol, :plus, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize([?* | rest], line, acc) do
    token = {:symbol, :star, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize([?/ | rest], line, acc) do
    token = {:symbol, :slash, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize([?< | rest], line, acc) do
    token = {:symbol, :less_than, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize([?> | rest], line, acc) do
    token = {:symbol, :greater_than, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  # Handle any other single character as a special symbol (safer than atom)
  defp do_tokenize([ch | rest], line, acc) do
    token = {:unknown_char, ch, %{line: line, column: nil}}
    do_tokenize(rest, line, [token | acc])
  end

  # Skip comments until end of line or end of input (faithful to Erlang)
  defp skip_comment([]), do: []
  defp skip_comment([?\n | rest]), do: [?\n | rest]  # Keep newline for line counting
  defp skip_comment([?-, ?- | rest]), do: rest  # Handle nested -- comments
  defp skip_comment([_ | rest]), do: skip_comment(rest)

  # Collect string/quote characters (faithful port of Erlang collect_string)
  defp collect_string(stop_char, chars, acc, line) do
    collect_string_impl(stop_char, chars, acc, line)
  end

  # String collection implementation matching Erlang logic
  defp collect_string_impl(stop_char, [stop_char | rest], acc, line) do
    # Found terminating quote - return reversed string and remaining chars
    string_value = acc |> Enum.reverse() |> List.to_string()
    case stop_char do
      ?" -> {{:string, string_value, line}, rest}
      ?' -> {{:quote, string_value, line}, rest}
    end
  end

  defp collect_string_impl(stop_char, [?\\ | [escaped_char | rest]], acc, line) do
    # Handle escape sequences (basic support)
    actual_char = case escaped_char do
      ?n -> ?\n
      ?t -> ?\t  
      ?r -> ?\r
      ?\\ -> ?\\
      ?" -> ?"
      ?' -> ?'
      _ -> escaped_char
    end
    collect_string_impl(stop_char, rest, [actual_char | acc], line)
  end

  defp collect_string_impl(stop_char, [?\n | rest], acc, line) do
    # Multi-line string support - increment line counter
    collect_string_impl(stop_char, rest, [?\n | acc], line + 1)
  end

  defp collect_string_impl(stop_char, [ch | rest], acc, line) do
    # Regular character - add to accumulator
    collect_string_impl(stop_char, rest, [ch | acc], line)
  end

  defp collect_string_impl(stop_char, [], _acc, line) do
    # Unterminated string - provide more detailed error like Erlang
    stop_char_name = case stop_char do
      ?" -> "double quote"
      ?' -> "single quote"
      _ -> "delimiter"
    end
    {:error, "Unterminated string starting with #{stop_char_name} at line #{line}"}
  end

  # Get integer value (faithful to Erlang get_integer)
  defp get_integer(chars, acc) do
    get_integer_impl(chars, acc)
  end

  defp get_integer_impl([ch | rest], acc) when ch >= ?0 and ch <= ?9 do
    get_integer_impl(rest, [ch | acc])
  end

  defp get_integer_impl(rest, acc) do
    # Convert accumulated digits to integer
    digit_string = acc |> Enum.reverse() |> List.to_string()
    {String.to_integer(digit_string), rest}
  end

  # Get name/identifier (faithful to Erlang get_name) - Enhanced for SNMP
  defp get_name(acc, chars) do
    get_name_impl(acc, chars)
  end

  defp get_name_impl(acc, [ch | rest]) when (ch >= ?a and ch <= ?z) or 
                                           (ch >= ?A and ch <= ?Z) or
                                           (ch >= ?0 and ch <= ?9) or
                                           ch == ?- or
                                           ch == ?_ do  # Allow underscores in names
    get_name_impl([ch | acc], rest)
  end

  defp get_name_impl(acc, rest) do
    name = acc |> Enum.reverse() |> List.to_string()
    {name, rest}
  end

  # Make name token with reserved word checking (faithful to Erlang makeNameRespons)
  defp make_name_token(category, name, line) do
    if reserved_word?(name) do
      # Convert reserved word to keyword token (lowercase with underscores)
      keyword_atom = name 
                    |> String.replace("-", "_")
                    |> String.downcase()
                    |> String.to_atom()
      {:keyword, keyword_atom, %{line: line, column: nil}}
    else
      # Regular identifier
      case category do
        :atom -> {:identifier, name, %{line: line, column: nil}}
        :variable -> {:variable, name, %{line: line, column: nil}}
      end
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
end