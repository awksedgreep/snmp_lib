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
  
  require Logger

  # Complete reserved words list from Erlang snmpc_tok.erl - Extended from official source
  # Optimized: Pre-computed keyword atoms to avoid runtime string processing
  @reserved_words_map %{
    "ACCESS" => :access, "AGENT-CAPABILITIES" => :agent_capabilities, "APPLICATION" => :application, 
    "AUGMENTS" => :augments, "BEGIN" => :begin, "BITS" => :bits, "CHOICE" => :choice, 
    "CONTACT-INFO" => :contact_info, "COUNTER" => :counter, "COUNTER32" => :counter32, "Counter32" => :counter32,
    "COUNTER64" => :counter64, "Counter64" => :counter64, "DEFVAL" => :defval, "DEFINITIONS" => :definitions, 
    "DESCRIPTION" => :description, "DISPLAY-HINT" => :display_hint, "END" => :end, 
    "ENTERPRISE" => :enterprise, "EXPORTS" => :exports, "FROM" => :from, "GAUGE" => :gauge, 
    "GAUGE32" => :gauge32, "Gauge32" => :gauge32, "GROUP" => :group, "IDENTIFIER" => :identifier, "IMPLICIT" => :implicit, 
    "IMPORTS" => :imports, "INDEX" => :index, "INTEGER" => :integer, "INTEGER32" => :integer32, 
    "Integer32" => :integer32, "IpAddress" => :ipaddress, "LAST-UPDATED" => :last_updated, 
    "MAX-ACCESS" => :max_access, "MIN-ACCESS" => :min_access, "MODULE" => :module, 
    "MODULE-COMPLIANCE" => :module_compliance, "MODULE-IDENTITY" => :module_identity, 
    "NOTIFICATION-GROUP" => :notification_group, "NOTIFICATION-TYPE" => :notification_type, 
    "OBJECT" => :object, "OBJECT-GROUP" => :object_group, "OBJECT-IDENTITY" => :object_identity, 
    "OBJECT-TYPE" => :object_type, "OBJECTS" => :objects, "OCTET" => :octet, "OF" => :of, 
    "ORGANIZATION" => :organization, "REFERENCE" => :reference, "REVISION" => :revision, 
    "SEQUENCE" => :sequence, "SIZE" => :size, "STATUS" => :status, "STRING" => :string, 
    "SYNTAX" => :syntax, "TEXTUAL-CONVENTION" => :textual_convention, "TimeTicks" => :timeticks, 
    "TRAP-TYPE" => :trap_type, "UNITS" => :units, "UNIVERSAL" => :universal, 
    "Unsigned32" => :unsigned32, "VARIABLES" => :variables, "WRITE-SYNTAX" => :write_syntax,
    # Additional from complete Erlang list
    "MANDATORY-GROUPS" => :mandatory_groups, "COMPLIANCE" => :compliance, 
    "PRODUCT-RELEASE" => :product_release, "SUPPORTS" => :supports, "INCLUDES" => :includes, 
    "VARIATION" => :variation, "CREATION-REQUIRES" => :creation_requires, "IMPLIED" => :implied, 
    "EXPLICIT" => :explicit, "TAGS" => :tags, "BIT" => :bit, "NULL" => :null, "BOOLEAN" => :boolean,
    # Extended from actual Erlang grammar - missing critical keywords
    "MACRO" => :macro, "TYPE" => :type, "VALUE" => :value, "ABSENT" => :absent, "ANY" => :any, 
    "DEFINED" => :defined, "BY" => :by, "OPTIONAL" => :optional, "DEFAULT" => :default, 
    "COMPONENTS" => :components, "PRIVATE" => :private, "PUBLIC" => :public, "REAL" => :real, 
    "MIN" => :min, "MAX" => :max, "EXTENSIBILITY" => :extensibility, "WITH" => :with, 
    "COMPONENT" => :component, "PRESENT" => :present, "EXCEPT" => :except, 
    "INTERSECTION" => :intersection, "UNION" => :union, "ALL" => :all, "ENCODED" => :encoded
  }
  

  @doc """
  Tokenize MIB content following Erlang snmpc_tok.erl exactly.
  Returns {:ok, tokens} or {:error, reason}
  """
  def tokenize(input, _opts \\ []) when is_binary(input) do
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

  # Handle identifiers and keywords FIRST - most common in MIB files
  defp do_tokenize(<<c, _::binary>> = input, line, acc) 
      when (c >= ?a and c <= ?z) or (c >= ?A and c <= ?Z) do
    {name, rest} = parse_name_inline(input, <<>>)
    token = make_name_token_binary(name, line)
    do_tokenize(rest, line, [token | acc])
  end

  # Handle integers - inlined binary integer parsing for performance
  defp do_tokenize(<<c, _::binary>> = input, line, acc) when c >= ?0 and c <= ?9 do
    {int_value, rest} = parse_integer_inline(input, 0)
    token = {:integer, int_value, line}
    do_tokenize(rest, line, [token | acc])
  end

  # Handle negative integers
  defp do_tokenize(<<?-, c, _::binary>> = input, line, acc) when c >= ?0 and c <= ?9 do
    <<?-, rest::binary>> = input
    {int_value, rest_after_int} = parse_integer_inline(rest, 0)
    token = {:integer, -int_value, line}
    do_tokenize(rest_after_int, line, [token | acc])
  end
  
  # Handle multi-character symbols
  defp do_tokenize(<<"::=", rest::binary>>, line, acc) do
    token = {:symbol, :assign, line}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<"..", rest::binary>>, line, acc) do
    token = {:symbol, :range, line}
    do_tokenize(rest, line, [token | acc])
  end

  # Handle single character symbols
  defp do_tokenize(<<"{", rest::binary>>, line, acc) do
    token = {:symbol, :open_brace, line}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<"}", rest::binary>>, line, acc) do
    token = {:symbol, :close_brace, line}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<"(", rest::binary>>, line, acc) do
    token = {:symbol, :open_paren, line}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<")", rest::binary>>, line, acc) do
    token = {:symbol, :close_paren, line}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<"[", rest::binary>>, line, acc) do
    token = {:symbol, :open_bracket, line}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<"]", rest::binary>>, line, acc) do
    token = {:symbol, :close_bracket, line}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<",", rest::binary>>, line, acc) do
    token = {:symbol, :comma, line}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<".", rest::binary>>, line, acc) do
    token = {:symbol, :dot, line}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<";", rest::binary>>, line, acc) do
    token = {:symbol, :semicolon, line}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<"|", rest::binary>>, line, acc) do
    token = {:symbol, :pipe, line}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<":", rest::binary>>, line, acc) do
    token = {:symbol, :colon, line}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<"=", rest::binary>>, line, acc) do
    token = {:symbol, :equals, line}
    do_tokenize(rest, line, [token | acc])
  end

  # Handle additional special characters that appear in SNMP MIBs
  defp do_tokenize(<<"+", rest::binary>>, line, acc) do
    token = {:symbol, :plus, line}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<"*", rest::binary>>, line, acc) do
    token = {:symbol, :star, line}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<"/", rest::binary>>, line, acc) do
    token = {:symbol, :slash, line}
    do_tokenize(rest, line, [token | acc])
  end

  # Handle single minus as symbol (not negative number)
  defp do_tokenize(<<?-, rest::binary>>, line, acc) do
    token = {:symbol, :minus, line}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<"<", rest::binary>>, line, acc) do
    token = {:symbol, :less_than, line}
    do_tokenize(rest, line, [token | acc])
  end

  defp do_tokenize(<<">", rest::binary>>, line, acc) do
    token = {:symbol, :greater_than, line}
    do_tokenize(rest, line, [token | acc])
  end

  # Handle string literals - optimized binary collection
  defp do_tokenize(<<?\", rest::binary>>, line, acc) do
    {string_value, rest_after_string} = collect_string_binary(rest, <<>>)
    token = {:string, string_value, line}
    do_tokenize(rest_after_string, line, [token | acc])
  end

  # Handle quoted literals
  defp do_tokenize(<<?\', rest::binary>>, line, acc) do
    {quote_value, rest_after_quote} = collect_quote_binary(rest, <<>>)
    token = {:quote, quote_value, line}
    do_tokenize(rest_after_quote, line, [token | acc])
  end

  # Handle any other single character as a special symbol (safer than atom)
  defp do_tokenize(<<ch, rest::binary>>, line, acc) do
    token = {:unknown_char, ch, line}
    do_tokenize(rest, line, [token | acc])
  end

  # Helper functions for parsing
  
  # Inlined integer parsing - faster than function calls
  defp parse_integer_inline(<<c, rest::binary>>, acc) when c >= ?0 and c <= ?9 do
    parse_integer_inline(rest, acc * 10 + (c - ?0))
  end
  defp parse_integer_inline(rest, acc), do: {acc, rest}
  
  # Inlined name parsing - faster than function calls for identifiers/keywords
  defp parse_name_inline(<<c, rest::binary>>, acc) 
      when (c >= ?a and c <= ?z) or (c >= ?A and c <= ?Z) or 
           (c >= ?0 and c <= ?9) or c == ?- or c == ?_ do
    parse_name_inline(rest, <<acc::binary, c>>)
  end
  defp parse_name_inline(rest, acc), do: {acc, rest}

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


  # Create appropriate token for name - binary optimized with pre-computed keywords
  defp make_name_token_binary(name, line) do
    case Map.get(@reserved_words_map, name) do
      nil ->
        # All non-keywords are identifiers in SNMP MIB parsing
        {:identifier, name, line}
      keyword_atom ->
        # Use pre-computed keyword atom (no string processing needed)
        {:keyword, keyword_atom, line}
    end
  end

  # Check if word is reserved (faithful to Erlang reserved_word/1)
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
        Logger.info("Tokenization successful!")
        Enum.each(tokens, fn token -> Logger.debug(inspect(token)) end)
      {:error, reason} ->
        Logger.error("Tokenization failed: #{reason}")
    end
  end
end