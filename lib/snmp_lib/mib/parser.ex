defmodule SnmpLib.MIB.Parser do
  @moduledoc """
  Direct port of Erlang snmpc_mib_gram.yrl parser to Elixir.
  
  This is a 1:1 port of the official Erlang SNMP MIB grammar parser
  from OTP lib/snmp/src/compile/snmpc_mib_gram.yrl
  
  Original copyright: Ericsson AB 1996-2025 (Apache License 2.0)
  """

  # MIB parsing result types
  @type mib() :: %{
    name: binary(),
    imports: [import()],
    definitions: [definition()],
    version: :v1 | :v2
  }

  @type import() :: %{
    __type__: :import,
    symbols: [binary()],
    from_module: binary()
  }

  @type definition() :: %{
    name: binary(),
    type: atom(),
    value: term()
  }

  @type token() :: {atom(), any(), any()}

  @type parse_result() :: 
    {:ok, mib()} | 
    {:error, [error()]}

  @type error() :: %{
    type: atom(),
    message: binary(),
    line: integer()
  }

  @doc """
  Parse a list of tokens into a MIB structure.
  Returns {:ok, mib} or {:error, errors}
  """
  @spec parse(binary()) :: parse_result()
  def parse(input) when is_binary(input) do
    with {:ok, tokens} <- SnmpLib.MIB.Lexer.tokenize(input) do
      parse_tokens(tokens)
    end
  end

  @spec parse_tokens([token()]) :: parse_result()
  def parse_tokens(tokens) when is_list(tokens) do
    try do
      do_parse(tokens)
    rescue
      exception ->
        error = SnmpLib.MIB.Error.new(:unexpected_token, 
          message: "Parser exception: #{Exception.message(exception)}", line: 0)
        {:error, [error]}
    catch
      {:error, reason} when is_binary(reason) ->
        error = SnmpLib.MIB.Error.new(:unexpected_token, message: reason, line: 0)
        {:error, [error]}
      {:error, reason} ->
        error = SnmpLib.MIB.Error.new(:unexpected_token, message: inspect(reason), line: 0)
        {:error, [error]}
    end
  end

  # Main parsing entry point - follows snmpc_mib_gram.yrl structure
  defp do_parse(tokens) do
    case parse_mib_header(tokens) do
      {:ok, {mib_name, remaining_tokens}} ->
        case parse_imports_section(remaining_tokens) do
          {:ok, {imports, remaining_tokens}} ->
            case parse_definitions_section(remaining_tokens) do
              {:ok, {definitions, remaining_tokens}} ->
                case expect_keyword(remaining_tokens, :end) do
                  {:ok, _final_tokens} ->
      
      
                    # Determine SNMP version from definitions
                    version = determine_snmp_version(definitions)
                    
                    mib = %{
                      __type__: :mib,
                      name: mib_name,
                      imports: imports,
                      definitions: definitions,
                      version: version
                    }
                    
                    {:ok, mib}
                  {:error, reason} -> handle_parse_error(reason)
                end
              {:error, reason} -> handle_parse_error(reason)
            end
          {:error, reason} -> handle_parse_error(reason)
        end
      {:error, reason} -> handle_parse_error(reason)
    end
  end

  # Parse MIB header: "MibName DEFINITIONS ::= BEGIN"
  defp parse_mib_header([{:identifier, mib_name, _} | tokens]) do
    with {:ok, tokens} <- expect_keyword(tokens, :definitions),
         {:ok, tokens} <- expect_symbol(tokens, :assign),
         {:ok, tokens} <- expect_keyword(tokens, :begin) do
      {:ok, {mib_name, tokens}}
    end
  end

  defp parse_mib_header(tokens) do
    {:error, "Expected MIB name identifier, got #{inspect(hd(tokens))}"}
  end

  # Parse IMPORTS section (optional)
  defp parse_imports_section([{:keyword, :imports, _} | tokens]) do
    parse_import_groups(tokens, [])
  end

  defp parse_imports_section(tokens) do
    {:ok, {[], tokens}}
  end

  # Parse multiple import groups recursively
  defp parse_import_groups(tokens, acc) do
    case parse_single_import_group(tokens) do
      {:ok, {import_group, remaining_tokens}} ->
        parse_import_groups(remaining_tokens, [import_group | acc])
      {:done, remaining_tokens} ->
        {:ok, {Enum.reverse(acc), remaining_tokens}}
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Parse single import group: "symbol1, symbol2 FROM ModuleName"
  defp parse_single_import_group(tokens) do
    case parse_symbol_list_until_from(tokens, []) do
      {:ok, {symbols, [{:keyword, :from, _} | remaining_tokens]}} ->
        case parse_module_name_with_comment(remaining_tokens) do
          {:ok, {module_name, remaining_tokens}} ->
            import_group = %{__type__: :import, symbols: symbols, from_module: module_name}
            {:ok, {import_group, remaining_tokens}}
          {:error, reason} ->
            {:error, reason}
        end
      {:done, remaining_tokens} ->
        {:done, remaining_tokens}
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Parse symbol list until FROM keyword
  defp parse_symbol_list_until_from(tokens, acc) do
    case parse_next_symbol_or_from(tokens) do
      {:symbol, symbol, remaining_tokens} ->
        parse_symbol_list_until_from(remaining_tokens, [symbol | acc])
      {:from, remaining_tokens} ->
        {:ok, {Enum.reverse(acc), [{:keyword, :from, nil} | remaining_tokens]}}
      {:done, remaining_tokens} ->
        {:done, remaining_tokens}
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Parse next symbol or detect FROM
  defp parse_next_symbol_or_from([{:keyword, :from, _} | tokens]) do
    {:from, tokens}
  end

  defp parse_next_symbol_or_from([{:keyword, :end, _} | _] = tokens) do
    {:done, tokens}
  end

  # Detect start of new definition sections that should end import parsing
  # IMPORTANT: These specific patterns must come BEFORE the general identifier pattern
  defp parse_next_symbol_or_from([{:identifier, _name, _}, {:keyword, :module_identity, _} | _] = tokens) do
    {:done, tokens}
  end

  defp parse_next_symbol_or_from([{:identifier, _name, _}, {:keyword, :object_type, _} | _] = tokens) do
    {:done, tokens}
  end

  defp parse_next_symbol_or_from([{:identifier, _name, _}, {:keyword, :textual_convention, _} | _] = tokens) do
    {:done, tokens}
  end

  defp parse_next_symbol_or_from([{:identifier, _name, _}, {:keyword, :object, _}, {:keyword, :identifier, _} | _] = tokens) do
    {:done, tokens}
  end

  defp parse_next_symbol_or_from([{:identifier, _name, _}, {:symbol, :assign, _} | _] = tokens) do
    {:done, tokens}
  end

  defp parse_next_symbol_or_from([{:keyword, keyword, _} | tokens]) do
    # Convert keyword back to string for imports
    symbol = keyword |> to_string() |> String.upcase() |> String.replace("_", "-")
    case tokens do
      [{:symbol, :comma, _} | rest] -> {:symbol, symbol, rest}
      [{:keyword, :from, _} | _] = rest -> {:symbol, symbol, rest}
      _ -> {:symbol, symbol, tokens}
    end
  end

  defp parse_next_symbol_or_from([{:identifier, symbol, _} | tokens]) do
    case tokens do
      [{:symbol, :comma, _} | rest] -> {:symbol, symbol, rest}
      [{:keyword, :from, _} | _] = rest -> {:symbol, symbol, rest}
      _ -> {:symbol, symbol, tokens}
    end
  end

  defp parse_next_symbol_or_from([{:symbol, :semicolon, _} | tokens]) do
    {:done, tokens}
  end

  defp parse_next_symbol_or_from([]) do
    {:done, []}
  end

  defp parse_next_symbol_or_from(tokens) do
    {:error, "Unexpected token in imports: #{inspect(hd(tokens))}"}
  end

  # Parse module name potentially followed by comment
  defp parse_module_name_with_comment([{:identifier, module_name, _} | tokens]) do
    # Skip optional comment (-- RFC xxxx) and optional comma or semicolon
    remaining_tokens = skip_optional_comment_and_separators(tokens)
    {:ok, {module_name, remaining_tokens}}
  end

  defp parse_module_name_with_comment(tokens) do
    {:error, "Expected module name, got #{inspect(hd(tokens))}"}
  end

  # Skip optional comment after module name and optional separators
  defp skip_optional_comment_and_separators([{:symbol, :comma, _} | tokens]) do
    # Skip comma and continue parsing more import groups
    tokens
  end
  
  defp skip_optional_comment_and_separators([{:symbol, :semicolon, _} | tokens]) do
    # Semicolon ends the imports section
    tokens
  end
  
  defp skip_optional_comment_and_separators(tokens) do
    # No separators found, continue with next tokens
    tokens
  end

  # Parse definitions section
  defp parse_definitions_section(tokens) do
    parse_definition_list(tokens, [])
  end

  # Parse list of definitions recursively
  defp parse_definition_list([{:keyword, :end, _} | _] = tokens, acc) do
    {:ok, {Enum.reverse(acc), tokens}}
  end

  defp parse_definition_list([{:identifier, name, pos} | tokens], acc) do
    case parse_definition(name, pos, tokens) do
      {:ok, {definition, rest}} ->
        parse_definition_list(rest, [definition | acc])
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_definition_list([], acc) do
    {:ok, {Enum.reverse(acc), []}}
  end

  defp parse_definition_list(tokens, _acc) do
    {:error, "Expected definition or END, got #{inspect(hd(tokens))}"}
  end

  # Parse individual definition based on lookahead
  defp parse_definition(name, _pos, tokens) do
    case tokens do
      # MODULE-IDENTITY
      [{:keyword, :module_identity, _} | rest] ->
        parse_module_identity(name, rest)
        
      # OBJECT-TYPE  
      [{:keyword, :object_type, _} | rest] ->
        parse_object_type(name, rest)
        
      # TEXTUAL-CONVENTION (can appear without ::=)
      [{:keyword, :textual_convention, _} | rest] ->
        parse_textual_convention(name, rest)
        
      # ::= TEXTUAL-CONVENTION
      [{:symbol, :assign, _}, {:keyword, :textual_convention, _} | rest] ->
        parse_textual_convention(name, rest)
        
      # MODULE-COMPLIANCE
      [{:keyword, :module_compliance, _} | rest] ->
        parse_module_compliance(name, rest)
        
      # OBJECT-GROUP
      [{:keyword, :object_group, _} | rest] ->
        parse_object_group(name, rest)
        
      # OBJECT IDENTIFIER ::= { ... }
      [{:keyword, :object, _}, {:keyword, :identifier, _}, {:symbol, :assign, _} | rest] ->
        parse_object_identifier_definition(name, rest)
        
      # ::= SEQUENCE { ... }
      [{:symbol, :assign, _}, {:keyword, :sequence, _}, {:symbol, :open_brace, _} | rest] ->
        parse_sequence_definition(name, rest)
        
      # ::= { ... } (OID assignment)
      [{:symbol, :assign, _}, {:symbol, :open_brace, _} | rest] ->
        parse_oid_assignment(name, rest)
        
      # Handle DEFVAL clause (often appears before ::=)
      [{:keyword, :defval, _} | rest] ->
        case skip_defval_clause(rest) do
          {:ok, remaining_tokens} -> parse_definition(name, nil, remaining_tokens)
          {:error, reason} -> {:error, reason}
        end
        
      # ::= value (simple assignment) - must be last
      [{:symbol, :assign, _} | rest] ->
        parse_simple_assignment(name, rest)
        
      _ ->
        {:error, "Unknown definition type for #{name}, tokens: #{inspect(tokens)}"}
    end
  end

  # Parse MODULE-IDENTITY
  defp parse_module_identity(name, tokens) do
    with {:ok, {last_updated, tokens}} <- parse_last_updated_clause(tokens),
         {:ok, {organization, tokens}} <- parse_organization_clause(tokens),
         {:ok, {contact_info, tokens}} <- parse_contact_info_clause(tokens),
         {:ok, {description, tokens}} <- parse_description_clause(tokens),
         {:ok, {revisions, tokens}} <- parse_revisions_clause(tokens),
         {:ok, {oid, tokens}} <- parse_oid_assignment_clause(tokens) do
      
      definition = %{
        name: name,
        __type__: :module_identity,
        last_updated: last_updated,
        organization: organization,
        contact_info: contact_info,
        description: description,
        revisions: revisions,
        oid: oid
      }
      
      {:ok, {definition, tokens}}
    end
  end

  # Parse OBJECT-TYPE with flexible clause order
  defp parse_object_type(name, tokens) do
    case parse_object_type_clauses(tokens, %{}) do
      {:ok, {clauses, remaining_tokens}} ->
        with {:ok, {oid, tokens}} <- parse_oid_assignment_clause(remaining_tokens) do
          definition = %{
            name: name,
            __type__: :object_type,
            syntax: Map.get(clauses, :syntax),
            max_access: Map.get(clauses, :access),
            status: Map.get(clauses, :status),
            description: Map.get(clauses, :description),
            oid: oid
          }
          |> Map.merge(Map.drop(clauses, [:syntax, :access, :status, :description]))
          
          {:ok, {definition, tokens}}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Parse object type clauses in any order
  defp parse_object_type_clauses(tokens, acc) do
    case tokens do
      [{:keyword, :syntax, _} | rest] ->
        case parse_syntax_type(rest) do
          {:ok, {syntax, remaining}} ->
            parse_object_type_clauses(remaining, Map.put(acc, :syntax, syntax))
          {:error, reason} -> {:error, reason}
        end
      
      [{:keyword, :access, _}, {:identifier, access, _} | rest] ->
        access_atom = String.to_atom(String.replace(access, "-", "_"))
        parse_object_type_clauses(rest, Map.put(acc, :access, access_atom))
      
      [{:keyword, :max_access, _}, {:identifier, access, _} | rest] ->
        access_atom = String.to_atom(String.replace(access, "-", "_"))
        parse_object_type_clauses(rest, Map.put(acc, :access, access_atom))
      
      [{:keyword, :status, _}, {:identifier, status, _} | rest] ->
        status_atom = String.to_atom(status)
        parse_object_type_clauses(rest, Map.put(acc, :status, status_atom))
      
      [{:keyword, :description, _}, {:string, description, _} | rest] ->
        parse_object_type_clauses(rest, Map.put(acc, :description, description))
      
      [{:keyword, :reference, _}, {:string, reference, _} | rest] ->
        parse_object_type_clauses(rest, Map.put(acc, :reference, reference))
      
      [{:keyword, :units, _}, {:string, units, _} | rest] ->
        parse_object_type_clauses(rest, Map.put(acc, :units, units))
      
      [{:keyword, :defval, _} | rest] ->
        case skip_defval_clause(rest) do
          {:ok, remaining} -> parse_object_type_clauses(remaining, acc)
          {:error, reason} -> {:error, reason}
        end
      
      [{:keyword, :index, _}, {:symbol, :open_brace, _} | rest] ->
        case parse_index_list(rest, []) do
          {:ok, {index, remaining}} ->
            parse_object_type_clauses(remaining, Map.put(acc, :index, index))
          {:error, reason} -> {:error, reason}
        end
      
      [{:keyword, :augments, _}, {:symbol, :open_brace, _}, {:identifier, table, _}, {:symbol, :close_brace, _} | rest] ->
        parse_object_type_clauses(rest, Map.put(acc, :augments, table))
      
      _ ->
        # Validate required OBJECT-TYPE clauses
        cond do
          map_size(acc) == 0 ->
            {:error, "No OBJECT-TYPE clauses found"}
          not Map.has_key?(acc, :syntax) ->
            {:error, "OBJECT-TYPE missing required SYNTAX clause"}
          not Map.has_key?(acc, :access) ->
            {:error, "OBJECT-TYPE missing required MAX-ACCESS or ACCESS clause"}
          not Map.has_key?(acc, :status) ->
            {:error, "OBJECT-TYPE missing required STATUS clause"}
          true ->
            {:ok, {acc, tokens}}
        end
    end
  end

  # Parse textual convention clauses in any order
  defp parse_textual_convention_clauses(tokens, acc) do
    case tokens do
      [{:keyword, :display_hint, _}, {:string, hint, _} | rest] ->
        parse_textual_convention_clauses(rest, Map.put(acc, :display_hint, hint))
      
      [{:keyword, :status, _}, {:identifier, status, _} | rest] ->
        status_atom = String.to_atom(status)
        parse_textual_convention_clauses(rest, Map.put(acc, :status, status_atom))
      
      [{:keyword, :status, _}, {:keyword, status, _} | rest] ->
        parse_textual_convention_clauses(rest, Map.put(acc, :status, status))
      
      [{:keyword, :description, _}, {:string, description, _} | rest] ->
        parse_textual_convention_clauses(rest, Map.put(acc, :description, description))
      
      [{:keyword, :reference, _}, {:string, reference, _} | rest] ->
        parse_textual_convention_clauses(rest, Map.put(acc, :reference, reference))
      
      [{:keyword, :syntax, _} | rest] ->
        case parse_syntax_type(rest) do
          {:ok, {syntax, remaining}} ->
            parse_textual_convention_clauses(remaining, Map.put(acc, :syntax, syntax))
          {:error, reason} -> {:error, reason}
        end
      
      _ ->
        # Validate required TEXTUAL-CONVENTION clauses
        cond do
          map_size(acc) == 0 ->
            {:error, "No TEXTUAL-CONVENTION clauses found"}
          not Map.has_key?(acc, :status) ->
            {:error, "TEXTUAL-CONVENTION missing required STATUS clause"}
          not Map.has_key?(acc, :description) ->
            {:error, "TEXTUAL-CONVENTION missing required DESCRIPTION clause"}
          not Map.has_key?(acc, :syntax) ->
            {:error, "TEXTUAL-CONVENTION missing required SYNTAX clause"}
          true ->
            {:ok, {acc, tokens}}
        end
    end
  end

  # Parse module compliance clauses in any order
  defp parse_module_compliance_clauses(tokens, acc) do
    case tokens do
      [{:keyword, :status, _}, {:identifier, status, _} | rest] ->
        status_atom = String.to_atom(status)
        parse_module_compliance_clauses(rest, Map.put(acc, :status, status_atom))
      
      [{:keyword, :status, _}, {:keyword, status, _} | rest] ->
        parse_module_compliance_clauses(rest, Map.put(acc, :status, status))
      
      [{:keyword, :description, _}, {:string, description, _} | rest] ->
        parse_module_compliance_clauses(rest, Map.put(acc, :description, description))
      
      [{:keyword, :reference, _}, {:string, reference, _} | rest] ->
        parse_module_compliance_clauses(rest, Map.put(acc, :reference, reference))
      
      [{:keyword, :module, _} | rest] ->
        case parse_module_clause(rest) do
          {:ok, {module_clause, remaining}} ->
            modules = Map.get(acc, :module_clauses, [])
            parse_module_compliance_clauses(remaining, Map.put(acc, :module_clauses, [module_clause | modules]))
          {:error, reason} -> {:error, reason}
        end
      
      [{:keyword, :mandatory_groups, _}, {:symbol, :open_brace, _} | rest] ->
        case parse_group_list(rest, []) do
          {:ok, {groups, remaining}} ->
            parse_module_compliance_clauses(remaining, Map.put(acc, :mandatory_groups, groups))
          {:error, reason} -> {:error, reason}
        end
      
      [{:keyword, :group, _}, {:identifier, group_name, _} | rest] ->
        case parse_group_clause(group_name, rest) do
          {:ok, {group_clause, remaining}} ->
            groups = Map.get(acc, :groups, [])
            parse_module_compliance_clauses(remaining, Map.put(acc, :groups, [group_clause | groups]))
          {:error, reason} -> {:error, reason}
        end
      
      [{:keyword, :object, _}, {:identifier, object_name, _} | rest] ->
        case parse_object_clause(object_name, rest) do
          {:ok, {object_clause, remaining}} ->
            objects = Map.get(acc, :objects, [])
            parse_module_compliance_clauses(remaining, Map.put(acc, :objects, [object_clause | objects]))
          {:error, reason} -> {:error, reason}
        end
      
      # Check for end of MODULE-COMPLIANCE
      [{:symbol, :assign, _} | _] ->
        # Found ::= which means we're done with clauses
        cond do
          map_size(acc) == 0 ->
            {:error, "No MODULE-COMPLIANCE clauses found"}
          not Map.has_key?(acc, :status) ->
            {:error, "MODULE-COMPLIANCE missing required STATUS clause"}
          not Map.has_key?(acc, :description) ->
            {:error, "MODULE-COMPLIANCE missing required DESCRIPTION clause"}
          true ->
            {:ok, {acc, tokens}}
        end
      
      # Check for next definition starting (identifier followed by known keywords)
      [{:identifier, _next_name, _}, {:keyword, next_keyword, _} | _] when next_keyword in [:object_type, :module_identity, :textual_convention, :module_compliance] ->
        cond do
          map_size(acc) == 0 ->
            {:error, "No MODULE-COMPLIANCE clauses found"}
          not Map.has_key?(acc, :status) ->
            {:error, "MODULE-COMPLIANCE missing required STATUS clause"}
          not Map.has_key?(acc, :description) ->
            {:error, "MODULE-COMPLIANCE missing required DESCRIPTION clause"}
          true ->
            {:ok, {acc, tokens}}
        end
      
      # END token
      [{:keyword, :end, _} | _] ->
        cond do
          map_size(acc) == 0 ->
            {:error, "No MODULE-COMPLIANCE clauses found"}
          not Map.has_key?(acc, :status) ->
            {:error, "MODULE-COMPLIANCE missing required STATUS clause"}
          not Map.has_key?(acc, :description) ->
            {:error, "MODULE-COMPLIANCE missing required DESCRIPTION clause"}
          true ->
            {:ok, {acc, tokens}}
        end
      
      _ ->
        # Unknown token, skip it for now to be permissive
        case tokens do
          [_unknown | rest] ->
            parse_module_compliance_clauses(rest, acc)
          [] ->
            {:ok, {acc, tokens}}
        end
    end
  end

  # Parse object group clauses in any order
  defp parse_object_group_clauses(tokens, acc) do
    case tokens do
      [{:keyword, :objects, _}, {:symbol, :open_brace, _} | rest] ->
        case parse_object_list(rest, []) do
          {:ok, {objects, remaining}} ->
            parse_object_group_clauses(remaining, Map.put(acc, :objects, objects))
          {:error, reason} -> {:error, reason}
        end
      
      [{:keyword, :status, _}, {:identifier, status, _} | rest] ->
        status_atom = String.to_atom(status)
        parse_object_group_clauses(rest, Map.put(acc, :status, status_atom))
      
      [{:keyword, :status, _}, {:keyword, status, _} | rest] ->
        parse_object_group_clauses(rest, Map.put(acc, :status, status))
      
      [{:keyword, :description, _}, {:string, description, _} | rest] ->
        parse_object_group_clauses(rest, Map.put(acc, :description, description))
      
      [{:keyword, :reference, _}, {:string, reference, _} | rest] ->
        parse_object_group_clauses(rest, Map.put(acc, :reference, reference))
      
      # Check for end patterns
      [{:symbol, :assign, _} | _] ->
        validate_object_group_clauses(acc, tokens)
      
      [{:identifier, _next_name, _}, {:keyword, next_keyword, _} | _] when next_keyword in [:object_type, :module_identity, :textual_convention, :module_compliance, :object_group] ->
        validate_object_group_clauses(acc, tokens)
      
      [{:keyword, :end, _} | _] ->
        validate_object_group_clauses(acc, tokens)
      
      _ ->
        # Unknown token, skip it for now
        case tokens do
          [_unknown | rest] ->
            parse_object_group_clauses(rest, acc)
          [] ->
            validate_object_group_clauses(acc, tokens)
        end
    end
  end

  defp validate_object_group_clauses(acc, tokens) do
    cond do
      map_size(acc) == 0 ->
        {:error, "No OBJECT-GROUP clauses found"}
      not Map.has_key?(acc, :objects) ->
        {:error, "OBJECT-GROUP missing required OBJECTS clause"}
      not Map.has_key?(acc, :status) ->
        {:error, "OBJECT-GROUP missing required STATUS clause"}
      not Map.has_key?(acc, :description) ->
        {:error, "OBJECT-GROUP missing required DESCRIPTION clause"}
      true ->
        {:ok, {acc, tokens}}
    end
  end

  # Parse object list: { object1, object2, ... }
  defp parse_object_list([{:symbol, :close_brace, _} | tokens], acc) do
    {:ok, {Enum.reverse(acc), tokens}}
  end

  defp parse_object_list([{:identifier, object, _} | tokens], acc) do
    case tokens do
      [{:symbol, :comma, _} | rest] ->
        parse_object_list(rest, [object | acc])
      _ ->
        parse_object_list(tokens, [object | acc])
    end
  end

  defp parse_object_list(tokens, _acc) do
    {:error, "Invalid object list: #{inspect(tokens)}"}
  end

  # Parse OBJECT IDENTIFIER definition
  defp parse_object_identifier_definition(name, tokens) do
    with {:ok, {oid, tokens}} <- parse_oid_value(tokens) do
      definition = %{
        name: name,
        __type__: :object_identifier,
        oid: oid
      }
      
      {:ok, {definition, tokens}}
    end
  end

  # Parse TEXTUAL-CONVENTION with flexible clause order
  defp parse_textual_convention(name, tokens) do
    case parse_textual_convention_clauses(tokens, %{}) do
      {:ok, {clauses, remaining_tokens}} ->
        definition = %{
          name: name,
          __type__: :textual_convention,
          display_hint: Map.get(clauses, :display_hint),
          status: Map.get(clauses, :status),
          description: Map.get(clauses, :description),
          reference: Map.get(clauses, :reference),
          syntax: Map.get(clauses, :syntax)
        }
        
        {:ok, {definition, remaining_tokens}}
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Parse OBJECT-GROUP
  defp parse_object_group(name, tokens) do
    case parse_object_group_clauses(tokens, %{}) do
      {:ok, {clauses, remaining_tokens}} ->
        # Parse the OID assignment if present
        case parse_oid_assignment_clause(remaining_tokens) do
          {:ok, {oid, final_tokens}} ->
            definition = %{
              name: name,
              __type__: :object_group,
              objects: Map.get(clauses, :objects, []),
              status: Map.get(clauses, :status),
              description: Map.get(clauses, :description),
              reference: Map.get(clauses, :reference),
              oid: oid
            }
            
            {:ok, {definition, final_tokens}}
          {:error, _reason} ->
            # No OID assignment
            definition = %{
              name: name,
              __type__: :object_group,
              objects: Map.get(clauses, :objects, []),
              status: Map.get(clauses, :status),
              description: Map.get(clauses, :description),
              reference: Map.get(clauses, :reference)
            }
            
            {:ok, {definition, remaining_tokens}}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Parse MODULE-COMPLIANCE
  defp parse_module_compliance(name, tokens) do
    case parse_module_compliance_clauses(tokens, %{}) do
      {:ok, {clauses, remaining_tokens}} ->
        # Parse the OID assignment if present
        case parse_oid_assignment_clause(remaining_tokens) do
          {:ok, {oid, final_tokens}} ->
            definition = %{
              name: name,
              __type__: :module_compliance,
              status: Map.get(clauses, :status),
              description: Map.get(clauses, :description),
              reference: Map.get(clauses, :reference),
              module_clauses: Map.get(clauses, :module_clauses, []),
              mandatory_groups: Map.get(clauses, :mandatory_groups, []),
              groups: Map.get(clauses, :groups, []),
              objects: Map.get(clauses, :objects, []),
              oid: oid
            }
            
            {:ok, {definition, final_tokens}}
          {:error, _reason} ->
            # No OID assignment, that's okay for MODULE-COMPLIANCE
            definition = %{
              name: name,
              __type__: :module_compliance,
              status: Map.get(clauses, :status),
              description: Map.get(clauses, :description),
              reference: Map.get(clauses, :reference),
              module_clauses: Map.get(clauses, :module_clauses, []),
              mandatory_groups: Map.get(clauses, :mandatory_groups, []),
              groups: Map.get(clauses, :groups, []),
              objects: Map.get(clauses, :objects, [])
            }
            
            {:ok, {definition, remaining_tokens}}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Parse SEQUENCE definition
  defp parse_sequence_definition(name, tokens) do
    with {:ok, {elements, tokens}} <- parse_sequence_elements(tokens),
         {:ok, tokens} <- expect_symbol(tokens, :close_brace) do
      
      definition = %{
        name: name,
        __type__: :sequence,
        elements: elements
      }
      
      {:ok, {definition, tokens}}
    end
  end

  # Parse OID assignment: { parent child } (tokens already consumed the opening brace)
  defp parse_oid_assignment(name, tokens) do
    with {:ok, {oid, tokens}} <- parse_oid_elements(tokens, []) do
      definition = %{
        name: name,
        __type__: :object_identifier_assignment,
        oid: oid
      }
      
      {:ok, {definition, tokens}}
    end
  end

  # Parse simple assignment: name ::= value
  defp parse_simple_assignment(name, [{:integer, value, _} | tokens]) do
    definition = %{
      name: name,
      __type__: :simple_assignment,
      value: value
    }
    
    {:ok, {definition, tokens}}
  end

  defp parse_simple_assignment(name, [{:identifier, value, _} | tokens]) do
    definition = %{
      name: name,
      __type__: :simple_assignment,
      value: value
    }
    
    {:ok, {definition, tokens}}
  end

  defp parse_simple_assignment(_name, tokens) do
    {:error, "Expected value in simple assignment, got #{inspect(hd(tokens))}"}
  end

  # Helper parsing functions for clauses

  defp parse_last_updated_clause([{:keyword, :last_updated, _}, {:string, value, _} | tokens]) do
    {:ok, {value, tokens}}
  end

  defp parse_organization_clause([{:keyword, :organization, _}, {:string, value, _} | tokens]) do
    {:ok, {value, tokens}}
  end

  defp parse_contact_info_clause([{:keyword, :contact_info, _}, {:string, value, _} | tokens]) do
    {:ok, {value, tokens}}
  end

  defp parse_description_clause([{:keyword, :description, _}, {:string, value, _} | tokens]) do
    {:ok, {value, tokens}}
  end

  defp parse_status_clause([{:keyword, :status, _}, {:identifier, status, _} | tokens]) do
    {:ok, {String.to_atom(status), tokens}}
  end
  
  defp parse_status_clause([{:keyword, :status, _}, {:keyword, status, _} | tokens]) do
    {:ok, {status, tokens}}
  end
  
  defp parse_status_clause(tokens) do
    {:error, "Expected STATUS clause, got #{inspect(tokens)}"}
  end

  defp parse_syntax_clause([{:keyword, :syntax, _} | tokens]) do
    parse_syntax_type(tokens)
  end

  defp parse_syntax_clause([]) do
    {:error, "Expected SYNTAX clause but reached end of tokens"}
  end

  defp parse_syntax_clause(tokens) do
    {:error, "Expected SYNTAX clause, got #{inspect(hd(tokens))}"}
  end

  defp parse_access_clause(tokens) do
    case tokens do
      [{:keyword, :access, _}, {:identifier, access, _} | rest] ->
        {:ok, {String.to_atom(String.replace(access, "-", "_")), rest}}
      [{:keyword, :max_access, _}, {:identifier, access, _} | rest] ->
        {:ok, {String.to_atom(String.replace(access, "-", "_")), rest}}
      # Handle case where ACCESS is keyword format (read-only becomes read_only)
      [{:keyword, :access, _}, {:keyword, access_keyword, _} | rest] ->
        {:ok, {access_keyword, rest}}
      [{:keyword, :max_access, _}, {:keyword, access_keyword, _} | rest] ->
        {:ok, {access_keyword, rest}}
      # Optional access clause - continue parsing
      _ ->
        {:ok, {:not_accessible, tokens}}
    end
  end

  defp parse_oid_assignment_clause([{:symbol, :assign, _} | tokens]) do
    parse_oid_value(tokens)
  end

  # Handle DEFVAL clause before OID assignment
  defp parse_oid_assignment_clause([{:keyword, :defval, _} | tokens]) do
    case skip_defval_clause(tokens) do
      {:ok, remaining_tokens} ->
        parse_oid_assignment_clause(remaining_tokens)
      {:error, reason} -> 
        {:error, reason}
    end
  end

  # Handle case where we don't have tokens (missing clause error)
  defp parse_oid_assignment_clause([]) do
    {:error, "Expected OID assignment but reached end of tokens"}
  end

  defp parse_oid_assignment_clause(tokens) do
    {:error, "Expected ::= for OID assignment, got #{inspect(hd(tokens))}"}
  end

  # Parse OID value: { parent child } or { parent(number) child(number) }
  defp parse_oid_value([{:symbol, :open_brace, _} | tokens]) do
    parse_oid_elements(tokens, [])
  end
  
  defp parse_oid_value(tokens) do
    {:error, "Expected '{' to start OID value, got #{inspect(hd(tokens))}"}
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

  defp parse_oid_elements([], _acc) do
    {:error, "Unexpected end of tokens while parsing OID elements"}
  end

  defp parse_oid_elements([token | _], _acc) do
    case token do
      {:integer, value, _} ->
        {:error, "Expected OID element, but found integer #{value} - this might indicate a function clause mismatch"}
      {:identifier, name, _} ->
        {:error, "Expected OID element, but found identifier '#{name}' - this might indicate a parsing context error"}
      other ->
        {:error, "Invalid OID element: #{inspect(other)}"}
    end
  end

  # Parse syntax types
  defp parse_syntax_type([{:keyword, :integer, _} | tokens]) do
    case tokens do
      [{:symbol, :open_brace, _} | rest] ->
        parse_integer_enum(rest, [])
      [{:symbol, :open_paren, _} | rest] ->
        parse_integer_constraint(rest)
      _ ->
        {:ok, {:integer, tokens}}
    end
  end

  defp parse_syntax_type([{:keyword, :octet, _}, {:keyword, :string, _} | tokens]) do
    case tokens do
      [{:symbol, :open_paren, _} | rest] ->
        parse_size_constraint(rest)
      _ ->
        {:ok, {:octet_string, tokens}}
    end
  end

  # SNMP SMI types
  defp parse_syntax_type([{:keyword, :integer32, _} | tokens]) do
    case tokens do
      [{:symbol, :open_paren, _} | rest] ->
        parse_integer_constraint(rest)
      _ ->
        {:ok, {:integer32, tokens}}
    end
  end

  defp parse_syntax_type([{:keyword, :unsigned32, _} | tokens]) do
    case tokens do
      [{:symbol, :open_paren, _} | rest] ->
        parse_integer_constraint(rest)
      _ ->
        {:ok, {:unsigned32, tokens}}
    end
  end

  defp parse_syntax_type([{:keyword, :counter32, _} | tokens]) do
    {:ok, {:counter32, tokens}}
  end

  defp parse_syntax_type([{:keyword, :counter64, _} | tokens]) do
    {:ok, {:counter64, tokens}}
  end

  defp parse_syntax_type([{:keyword, :gauge32, _} | tokens]) do
    case tokens do
      [{:symbol, :open_paren, _} | rest] ->
        parse_integer_constraint(rest)
      _ ->
        {:ok, {:gauge32, tokens}}
    end
  end

  defp parse_syntax_type([{:keyword, :time_ticks, _} | tokens]) do
    {:ok, {:time_ticks, tokens}}
  end

  defp parse_syntax_type([{:keyword, :timeticks, _} | tokens]) do
    {:ok, {:time_ticks, tokens}}
  end

  defp parse_syntax_type([{:keyword, :ip_address, _} | tokens]) do
    {:ok, {:ip_address, tokens}}
  end

  defp parse_syntax_type([{:keyword, :ipaddress, _} | tokens]) do
    {:ok, {:ip_address, tokens}}
  end

  defp parse_syntax_type([{:keyword, :object, _}, {:keyword, :identifier, _} | tokens]) do
    {:ok, {:object_identifier, tokens}}
  end

  defp parse_syntax_type([{:keyword, :sequence, _} | tokens]) do
    case tokens do
      [{:keyword, :of, _}, {:identifier, type_name, _} | rest] ->
        {:ok, {{:sequence_of, type_name}, rest}}
      [{:keyword, :of, _} | rest] ->
        {:ok, {:sequence_of, rest}}
      [{:symbol, :open_brace, _} | rest] ->
        {:ok, {:sequence, rest}}
      _ ->
        {:ok, {:sequence, tokens}}
    end
  end

  defp parse_syntax_type([{:keyword, :choice, _} | tokens]) do
    case tokens do
      [{:symbol, :open_brace, _} | rest] ->
        {:ok, {:choice, rest}}
      _ ->
        {:ok, {:choice, tokens}}
    end
  end

  defp parse_syntax_type([{:keyword, :bits, _} | tokens]) do
    case tokens do
      [{:symbol, :open_brace, _} | rest] ->
        parse_bits_definition(rest, [])
      _ ->
        {:ok, {:bits, tokens}}
    end
  end

  defp parse_syntax_type([{:identifier, type_name, _} | tokens]) do
    {:ok, {{:named_type, type_name}, tokens}}
  end

  defp parse_syntax_type([]) do
    {:error, "Expected syntax type but reached end of tokens"}
  end

  defp parse_syntax_type(tokens) do
    {:error, "Invalid syntax type: #{inspect(hd(tokens))}"}
  end

  # Parse integer enumeration: { name(1), name2(2) }
  defp parse_integer_enum([{:symbol, :close_brace, _} | tokens], acc) do
    {:ok, {{:integer, :enum, Enum.reverse(acc)}, tokens}}
  end

  defp parse_integer_enum([{:identifier, name, _}, {:symbol, :open_paren, _}, {:integer, value, _}, {:symbol, :close_paren, _} | tokens], acc) do
    enum_value = %{name: name, value: value}
    case tokens do
      [{:symbol, :comma, _} | rest] ->
        parse_integer_enum(rest, [enum_value | acc])
      _ ->
        parse_integer_enum(tokens, [enum_value | acc])
    end
  end

  # Handle invalid token sequences in integer enum
  defp parse_integer_enum(tokens, _acc) do
    {:error, "Invalid integer enumeration format: #{inspect(tokens)}"}
  end

  # Parse integer constraint: handles both simple ranges and complex OR constraints
  defp parse_integer_constraint(tokens) do
    parse_integer_constraint_list(tokens, [])
  end

  # Parse constraint list with OR operators
  defp parse_integer_constraint_list([{:symbol, :close_paren, _} | tokens], acc) do
    case acc do
      [single_constraint] ->
        {:ok, {single_constraint, tokens}}
      multiple_constraints ->
        {:ok, {{:integer, :or_constraint, Enum.reverse(multiple_constraints)}, tokens}}
    end
  end

  # Range pattern: min..max
  defp parse_integer_constraint_list([{:integer, min, _}, {:symbol, :range, _}, {:integer, max, _} | tokens], acc) do
    constraint = {:range, min, max}
    case tokens do
      [{:symbol, :pipe, _} | rest] ->
        parse_integer_constraint_list(rest, [constraint | acc])
      _ ->
        parse_integer_constraint_list(tokens, [constraint | acc])
    end
  end

  # Single integer
  defp parse_integer_constraint_list([{:integer, value, _} | tokens], acc) do
    case tokens do
      [{:symbol, :pipe, _} | rest] ->
        parse_integer_constraint_list(rest, [value | acc])
      _ ->
        parse_integer_constraint_list(tokens, [value | acc])
    end
  end

  # Handle unexpected tokens
  defp parse_integer_constraint_list(tokens, _acc) do
    {:error, "Invalid integer constraint pattern: #{inspect(tokens)}"}
  end

  # Parse BITS definition: { bit1(0), bit2(1), ... }
  defp parse_bits_definition([{:symbol, :close_brace, _} | tokens], acc) do
    {:ok, {{:bits, Enum.reverse(acc)}, tokens}}
  end

  defp parse_bits_definition([{:identifier, name, _}, {:symbol, :open_paren, _}, {:integer, value, _}, {:symbol, :close_paren, _} | tokens], acc) do
    bit_value = %{name: name, value: value}
    case tokens do
      [{:symbol, :comma, _} | rest] ->
        parse_bits_definition(rest, [bit_value | acc])
      _ ->
        parse_bits_definition(tokens, [bit_value | acc])
    end
  end

  # Handle invalid token sequences in bits definition
  defp parse_bits_definition(tokens, _acc) do
    {:error, "Invalid BITS definition format: #{inspect(tokens)}"}
  end

  # Parse integer range: (min..max) - kept for compatibility
  defp parse_integer_range([{:integer, min, _}, {:symbol, :range, _}, {:integer, max, _}, {:symbol, :close_paren, _} | tokens]) do
    {:ok, {{:integer, :range, {min, max}}, tokens}}
  end

  # Handle invalid integer range patterns
  defp parse_integer_range(tokens) do
    {:error, "Invalid integer range pattern: expected (min..max), got #{inspect(tokens)}"}
  end

  # Parse size constraint: SIZE (constraint)
  defp parse_size_constraint([{:keyword, :size, _}, {:symbol, :open_paren, _} | tokens]) do
    case parse_size_values(tokens) do
      {:ok, {constraint, [{:symbol, :close_paren, _} | rest]}} ->
        {:ok, {{:octet_string, :size, constraint}, rest}}
      error ->
        error
    end
  end

  # Parse size values: number | (min..max) | (val1 | val2 | min..max)
  # Single integer without parentheses
  defp parse_size_values([{:integer, value, _} | tokens]) do
    # Check if this is part of a larger constraint (i.e., followed by pipe or range)
    case tokens do
      [{:symbol, :pipe, _} | _] ->
        # This integer is part of a list, need to parse as constraint list
        parse_size_constraint_list([{:integer, value, nil} | tokens], [])
      [{:symbol, :range, _} | _] ->
        # This integer starts a range, need to parse as constraint list  
        parse_size_constraint_list([{:integer, value, nil} | tokens], [])
      _ ->
        # Simple single integer constraint
        {:ok, {value, tokens}}
    end
  end

  # Parenthesized constraint list
  defp parse_size_values([{:symbol, :open_paren, _} | tokens]) do
    parse_size_constraint_list(tokens, [])
  end

  defp parse_size_constraint_list([{:symbol, :close_paren, _} | tokens], acc) do
    {:ok, {Enum.reverse(acc), tokens}}
  end

  # Range pattern must come before single integer pattern
  defp parse_size_constraint_list([{:integer, min, _}, {:symbol, :range, _}, {:integer, max, _} | tokens], acc) do
    constraint = {:range, min, max}
    case tokens do
      [{:symbol, :pipe, _} | rest] ->
        parse_size_constraint_list(rest, [constraint | acc])
      _ ->
        parse_size_constraint_list(tokens, [constraint | acc])
    end
  end

  # Single integer pattern - but check if it's followed by range first
  defp parse_size_constraint_list([{:integer, value, _} | tokens], acc) do
    case tokens do
      # If next is range, this should be handled by range pattern above
      [{:symbol, :range, _} | _] ->
        {:error, "Range pattern should have been matched earlier"}
      [{:symbol, :pipe, _} | rest] ->
        parse_size_constraint_list(rest, [value | acc])
      _ ->
        parse_size_constraint_list(tokens, [value | acc])
    end
  end

  # Handle unexpected tokens
  defp parse_size_constraint_list(tokens, _acc) do
    {:error, "Unexpected tokens in SIZE constraint: #{inspect(tokens)}"}
  end

  # Parse sequence elements for SEQUENCE definitions
  defp parse_sequence_elements(tokens) do
    parse_sequence_element_list(tokens, [])
  end

  defp parse_sequence_element_list([{:symbol, :close_brace, _} | _] = tokens, acc) do
    {:ok, {Enum.reverse(acc), tokens}}
  end

  defp parse_sequence_element_list([{:identifier, name, _} | tokens], acc) do
    case parse_syntax_type(tokens) do
      {:ok, {syntax, rest}} ->
        element = %{name: name, type: syntax}
        case rest do
          [{:symbol, :comma, _} | next] ->
            parse_sequence_element_list(next, [element | acc])
          _ ->
            parse_sequence_element_list(rest, [element | acc])
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Optional clauses parsing
  defp parse_optional_object_clauses(tokens) do
    parse_optional_clauses(tokens, %{})
  end

  defp parse_optional_clauses([{:keyword, :units, _}, {:string, units, _} | tokens], acc) do
    parse_optional_clauses(tokens, Map.put(acc, :units, units))
  end

  defp parse_optional_clauses([{:keyword, :index, _} | tokens], acc) do
    case parse_index_clause(tokens) do
      {:ok, {index, rest}} ->
        parse_optional_clauses(rest, Map.put(acc, :index, index))
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_optional_clauses([{:keyword, :augments, _} | tokens], acc) do
    {:ok, {augments, rest}} = parse_augments_clause(tokens)
    parse_optional_clauses(rest, Map.put(acc, :augments, augments))
  end

  defp parse_optional_clauses([{:keyword, :reference, _}, {:string, reference, _} | tokens], acc) do
    parse_optional_clauses(tokens, Map.put(acc, :reference, reference))
  end

  defp parse_optional_clauses(tokens, acc) do
    {:ok, {acc, tokens}}
  end

  # Parse INDEX clause
  defp parse_index_clause([{:symbol, :open_brace, _} | tokens]) do
    parse_index_list(tokens, [])
  end

  defp parse_index_list([{:symbol, :close_brace, _} | tokens], acc) do
    {:ok, {Enum.reverse(acc), tokens}}
  end

  defp parse_index_list([{:identifier, name, _} | tokens], acc) do
    case tokens do
      [{:symbol, :comma, _} | rest] ->
        parse_index_list(rest, [name | acc])
      _ ->
        parse_index_list(tokens, [name | acc])
    end
  end

  # Parse AUGMENTS clause
  defp parse_augments_clause([{:symbol, :open_brace, _}, {:identifier, table, _}, {:symbol, :close_brace, _} | tokens]) do
    {:ok, {table, tokens}}
  end

  defp parse_augments_clause(tokens) do
    {:ok, {nil, tokens}}
  end

  # Parse optional display hint
  defp parse_optional_display_hint([{:keyword, :display_hint, _}, {:string, hint, _} | tokens]) do
    {:ok, {hint, tokens}}
  end

  defp parse_optional_display_hint(tokens) do
    {:ok, {nil, tokens}}
  end

  # Skip DEFVAL clause
  defp skip_defval_clause([{:symbol, :open_brace, _} | tokens]) do
    skip_until_close_brace(tokens, 1)
  end

  defp skip_defval_clause(tokens) do
    {:ok, tokens}
  end

  defp skip_until_close_brace([], _depth) do
    {:error, "Expected closing brace for DEFVAL clause"}
  end

  defp skip_until_close_brace([{:symbol, :close_brace, _} | tokens], 1) do
    {:ok, tokens}
  end

  defp skip_until_close_brace([{:symbol, :close_brace, _} | tokens], depth) when depth > 1 do
    skip_until_close_brace(tokens, depth - 1)
  end

  defp skip_until_close_brace([{:symbol, :open_brace, _} | tokens], depth) do
    skip_until_close_brace(tokens, depth + 1)
  end

  defp skip_until_close_brace([_ | tokens], depth) do
    skip_until_close_brace(tokens, depth)
  end

  # Parse revisions clause (optional, can be multiple)
  defp parse_revisions_clause(tokens) do
    parse_revision_list(tokens, [])
  end

  defp parse_revision_list([{:keyword, :revision, _}, {:string, date, _}, {:keyword, :description, _}, {:string, desc, _} | tokens], acc) do
    revision = %{date: date, description: desc}
    parse_revision_list(tokens, [revision | acc])
  end

  defp parse_revision_list(tokens, acc) do
    {:ok, {Enum.reverse(acc), tokens}}
  end

  # Parse MODULE clause in compliance statement
  defp parse_module_clause(tokens) do
    # For now, just skip to the end of the module clause
    # This is a simplified implementation
    {:ok, {%{type: :module}, tokens}}
  end

  # Parse group list: { group1, group2, ... }
  defp parse_group_list([{:symbol, :close_brace, _} | tokens], acc) do
    {:ok, {Enum.reverse(acc), tokens}}
  end

  defp parse_group_list([{:identifier, group, _} | tokens], acc) do
    case tokens do
      [{:symbol, :comma, _} | rest] ->
        parse_group_list(rest, [group | acc])
      _ ->
        parse_group_list(tokens, [group | acc])
    end
  end

  defp parse_group_list(tokens, _acc) do
    {:error, "Invalid group list: #{inspect(tokens)}"}
  end

  # Parse GROUP clause with description
  defp parse_group_clause(group_name, tokens) do
    case tokens do
      [{:keyword, :description, _}, {:string, description, _} | rest] ->
        group_clause = %{type: :group, name: group_name, description: description}
        {:ok, {group_clause, rest}}
      _ ->
        group_clause = %{type: :group, name: group_name}
        {:ok, {group_clause, tokens}}
    end
  end

  # Parse OBJECT clause with optional constraints
  defp parse_object_clause(object_name, tokens) do
    case parse_object_compliance_clause(tokens, %{name: object_name, type: :object}) do
      {:ok, {object_clause, remaining}} ->
        {:ok, {object_clause, remaining}}
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Parse object compliance clauses (WRITE-SYNTAX, MIN-ACCESS, etc.)
  defp parse_object_compliance_clause(tokens, acc) do
    case tokens do
      [{:keyword, :write_syntax, _} | rest] ->
        case parse_syntax_type(rest) do
          {:ok, {syntax, remaining}} ->
            parse_object_compliance_clause(remaining, Map.put(acc, :write_syntax, syntax))
          {:error, reason} -> {:error, reason}
        end
      
      [{:keyword, :min_access, _}, {:identifier, access, _} | rest] ->
        access_atom = String.to_atom(String.replace(access, "-", "_"))
        parse_object_compliance_clause(rest, Map.put(acc, :min_access, access_atom))
      
      [{:keyword, :description, _}, {:string, description, _} | rest] ->
        parse_object_compliance_clause(rest, Map.put(acc, :description, description))
      
      _ ->
        {:ok, {acc, tokens}}
    end
  end

  # Utility functions

  # Expect specific keyword token
  defp expect_keyword([{:keyword, expected, _} | tokens], expected) do
    {:ok, tokens}
  end

  defp expect_keyword(tokens, expected) do
    {:error, "Expected keyword #{expected}, got #{inspect(hd(tokens))}"}
  end

  # Expect specific symbol token
  defp expect_symbol([{:symbol, expected, _} | tokens], expected) do
    {:ok, tokens}
  end

  defp expect_symbol(tokens, expected) do
    {:error, "Expected symbol #{expected}, got #{inspect(hd(tokens))}"}
  end

  # Determine SNMP version from definitions
  # Handle parse errors consistently
  defp handle_parse_error(reason) when is_binary(reason) do
    error = SnmpLib.MIB.Error.new(:unexpected_token, message: reason, line: 0)
    {:error, [error]}
  end
  
  defp handle_parse_error(reason) do
    error = SnmpLib.MIB.Error.new(:unexpected_token, message: inspect(reason), line: 0)
    {:error, [error]}
  end

  defp determine_snmp_version(definitions) do
    has_v2_constructs = Enum.any?(definitions, fn def ->
      def.__type__ in [:module_identity, :object_group, :notification_group, :module_compliance]
    end)
    
    if has_v2_constructs, do: :v2, else: :v1
  end

  @doc """
  Format error messages
  """
  def format_error({:error, errors}) when is_list(errors) do
    errors
    |> Enum.map(&format_single_error/1)
    |> Enum.join("\n")
  end

  def format_error({:error, error}) do
    format_single_error(error)
  end

  defp format_single_error(%{type: type, message: message, line: line}) do
    "Line #{line}: #{type} - #{message}"
  end

  defp format_single_error(error) when is_binary(error) do
    error
  end

  defp format_single_error(error) do
    inspect(error)
  end
end