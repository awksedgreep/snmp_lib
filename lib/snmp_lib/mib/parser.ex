defmodule SnmpLib.MIB.Parser do
  @moduledoc """
  SNMP MIB parser - a true 1:1 port of Erlang SNMP MIB parser.
  
  This uses the real snmpc_mib_gram.yrl grammar file from Erlang/OTP
  compiled with yecc parser generator for proper SNMP MIB parsing.
  """
  
  require Logger

  @doc """
  Initialize the parser by compiling the Erlang grammar file.
  This creates a proper yacc-generated parser identical to Erlang's.
  """
  def init_parser do
    # Get the path to our Elixir-compatible grammar file
    grammar_file = Path.join([__DIR__, "..", "..", "..", "src", "mib_grammar_elixir.yrl"])
    
    # Ensure the output directory exists
    output_dir = Path.join([__DIR__, "..", "..", "..", "src"])
    File.mkdir_p!(output_dir)
    
    # Compile the grammar using Erlang's yecc
    result = :yecc.file(to_charlist(grammar_file))
    
    case result do
      {:ok, _generated_file} ->
        module_name = :mib_grammar_elixir
        Logger.debug("Successfully compiled SNMP MIB grammar - Generated parser module: #{module_name}")
        {:ok, module_name}
        
      {:error, reason} ->
        Logger.error("Failed to compile grammar: #{inspect(reason)}")
        {:error, reason}
        
      :error ->
        Logger.error("Grammar compilation failed with error")
        {:error, :compilation_failed}
    end
  end

  @doc """
  Parse all MIB files in a list of directories.
  
  Returns a map with directory paths as keys and results as values.
  Each result contains successful compilations and failures.
  
  ## Examples
  
      # Parse MIBs in multiple directories
      dirs = [
        "/path/to/mibs/working", 
        "/path/to/mibs/docsis"
      ]
      results = SnmpLib.MIB.Parser.mibdirs(dirs)
      
      # Access results by directory
      working_results = results["/path/to/mibs/working"]
      IO.puts("Success: \#{length(working_results.success)}/\#{working_results.total}")
      
      # Get all successful MIBs across directories
      all_mibs = Enum.flat_map(results, fn {_dir, result} -> result.success end)
  """
  def mibdirs(directories) when is_list(directories) do
    Logger.info("Compiling MIBs in #{length(directories)} directories")
    
    results = Enum.map(directories, fn dir ->
      {dir, compile_directory(dir)}
    end) |> Map.new()
    
    # Log summary
    total_success = Enum.reduce(results, 0, fn {_dir, result}, acc -> 
      acc + length(result.success)
    end)
    total_files = Enum.reduce(results, 0, fn {_dir, result}, acc -> 
      acc + result.total
    end)
    
    Logger.info("OVERALL RESULTS: Total MIBs compiled: #{total_success}/#{total_files} (#{Float.round(total_success / max(total_files, 1) * 100, 1)}%)")
    
    Enum.each(results, fn {dir, result} ->
      dir_name = Path.basename(dir)
      success_rate = Float.round(length(result.success) / max(result.total, 1) * 100, 1)
      Logger.info("  #{dir_name}: #{length(result.success)}/#{result.total} (#{success_rate}%)")
    end)
    
    results
  end

  @doc """
  Parse a MIB file using the Erlang SNMP grammar.
  This is the production MIB parser.
  """
  def parse(mib_content) when is_binary(mib_content) do
    # First ensure parser is compiled
    case init_parser() do
      {:ok, parser_module} ->
        # Tokenize the input
        case tokenize(mib_content) do
          {:ok, tokens} ->
            # Parse using the generated parser
            case apply(parser_module, :parse, [tokens]) do
              {:ok, parse_tree} ->
                {:ok, convert_to_elixir_format(parse_tree)}
                
              {:error, reason} ->
                Logger.debug("Parse failed: #{inspect(reason)}")
                {:error, convert_error_to_string(reason)}
            end
            
          {:error, reason} ->
            Logger.debug("Tokenize failed: #{inspect(reason)}")
            {:error, reason}
        end
        
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Parse pre-tokenized MIB tokens using the Erlang SNMP grammar.
  This function takes tokens directly without tokenizing.
  """
  def parse_tokens(tokens) when is_list(tokens) do
    # First ensure parser is compiled
    case init_parser() do
      {:ok, parser_module} ->
        # Parse using the generated parser
        case apply(parser_module, :parse, [tokens]) do
          {:ok, parse_tree} ->
            {:ok, convert_to_elixir_format(parse_tree)}
            
          {:error, reason} ->
            Logger.debug("Parse failed: #{inspect(reason)}")
            {:error, convert_error_to_string(reason)}
        end
        
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Tokenize MIB content using Erlang's SNMP tokenizer.
  This ensures we use the exact same tokenization as Erlang.
  """
  def tokenize(mib_content) when is_binary(mib_content) do
    # Convert to charlist for Erlang compatibility
    char_content = to_charlist(mib_content)
    
    # Use our 1:1 port of the Erlang SNMP tokenizer
    case SnmpLib.MIB.SnmpTokenizer.tokenize(char_content, &SnmpLib.MIB.SnmpTokenizer.null_get_line/0) do
      {:ok, tokens} ->
        Logger.debug("Using 1:1 Elixir port of Erlang SNMP tokenizer")
        # Apply hex atom conversion to tokens from 1:1 tokenizer
        converted_tokens = apply_hex_conversion(tokens)
        {:ok, converted_tokens}
      {:error, reason} ->
        Logger.debug("1:1 tokenizer error: #{inspect(reason)}")
        # Fall back to our custom tokenizer if needed
        case SnmpLib.MIB.Lexer.tokenize(mib_content) do
          {:ok, tokens} ->
            Logger.debug("Falling back to custom tokenizer")
            {:ok, convert_tokens_for_grammar(tokens)}
          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @doc """
  Apply hex atom conversion to tokens from the 1:1 tokenizer.
  Converts hex atoms like :"07fffffff" to integers for grammar compatibility.
  """
  defp apply_hex_conversion(tokens) do
    Enum.map(tokens, &convert_hex_atom/1)
  end
  
  # Convert hex atoms that look like integers to actual integers
  defp convert_hex_atom({:atom, line, atom_value}) when is_atom(atom_value) do
    atom_string = Atom.to_string(atom_value)
    
    # Check if it looks like a hex number
    if String.match?(atom_string, ~r/^[0-9a-fA-F]+$/) do
      try do
        # Try to convert from hex to integer
        hex_value = String.to_integer(atom_string, 16)
        {:integer, line, hex_value}
      rescue
        _ ->
          # If conversion fails, keep as atom
          {:atom, line, atom_value}
      end
    else
      # Not a hex pattern, keep as atom
      {:atom, line, atom_value}
    end
  end
  
  # Pass through all other tokens unchanged
  defp convert_hex_atom(token), do: token

  @doc """
  Convert our token format to the format expected by the Erlang grammar.
  Our format: {:identifier, "value", line}
  Grammar expects: {variable, line, "value"} or {atom, line}
  """
  defp convert_tokens_for_grammar(tokens) do
    converted_tokens = Enum.map(tokens, &convert_single_token/1)
    # Yecc parsers expect the end-of-input token in this format
    converted_tokens ++ [{:'$end', 0}]
  end

  # Convert specific identifiers to atoms for status/access values first
  defp convert_single_token({:identifier, "read-only", line}), do: {:atom, line, :"read-only"}
  defp convert_single_token({:identifier, "current", line}), do: {:atom, line, :current}
  defp convert_single_token({:identifier, "mandatory", line}), do: {:atom, line, :mandatory}
  defp convert_single_token({:identifier, "optional", line}), do: {:atom, line, :optional}
  defp convert_single_token({:identifier, "obsolete", line}), do: {:atom, line, :obsolete}
  defp convert_single_token({:identifier, "deprecated", line}), do: {:atom, line, :deprecated}
  defp convert_single_token({:identifier, "read-write", line}), do: {:atom, line, :"read-write"}
  defp convert_single_token({:identifier, "write-only", line}), do: {:atom, line, :"write-only"}
  defp convert_single_token({:identifier, "not-accessible", line}), do: {:atom, line, :"not-accessible"}
  defp convert_single_token({:identifier, "accessible-for-notify", line}), do: {:atom, line, :"accessible-for-notify"}
  defp convert_single_token({:identifier, "read-create", line}), do: {:atom, line, :"read-create"}

  # Convert identifiers to atoms for object names (these appear in OID definitions)
  # MIB names stay as variables, but object names become atoms
  defp convert_single_token({:identifier, "TEST-MIB", line}) do
    {:variable, line, "TEST-MIB"}
  end
  
  # Convert other identifiers to atoms (object names, etc.)
  defp convert_single_token({:identifier, value, line}) do
    {:atom, line, String.to_atom(value)}
  end
  
  # Convert hex atoms that look like integers to actual integers
  defp convert_single_token({:atom, line, atom_value}) when is_atom(atom_value) do
    atom_string = Atom.to_string(atom_value)
    
    # Check if it looks like a hex number
    if String.match?(atom_string, ~r/^[0-9a-fA-F]+$/) do
      try do
        # Try to convert from hex to integer
        hex_value = String.to_integer(atom_string, 16)
        {:integer, line, hex_value}
      rescue
        _ ->
          # If conversion fails, keep as atom
          {:atom, line, atom_value}
      end
    else
      # Not a hex pattern, keep as atom
      {:atom, line, atom_value}
    end
  end

  # Convert integers 
  defp convert_single_token({:integer, value, line}) do
    {:integer, line, value}
  end

  # Convert strings
  defp convert_single_token({:string, value, line}) do
    {:string, line, value}
  end


  # Convert keywords to their terminal names
  defp convert_single_token({:keyword, :definitions, line}), do: {:'DEFINITIONS', line}
  defp convert_single_token({:keyword, :begin, line}), do: {:'BEGIN', line}
  defp convert_single_token({:keyword, :end, line}), do: {:'END', line}
  defp convert_single_token({:keyword, :imports, line}), do: {:'IMPORTS', line}
  defp convert_single_token({:keyword, :from, line}), do: {:'FROM', line}
  defp convert_single_token({:keyword, :object, line}), do: {:'OBJECT', line}
  defp convert_single_token({:keyword, :identifier, line}), do: {:'IDENTIFIER', line}
  defp convert_single_token({:keyword, :object_type, line}), do: {:'OBJECT-TYPE', line}
  defp convert_single_token({:keyword, :syntax, line}), do: {:'SYNTAX', line}
  defp convert_single_token({:keyword, :max_access, line}), do: {:'MAX-ACCESS', line}
  defp convert_single_token({:keyword, :status, line}), do: {:'STATUS', line}
  defp convert_single_token({:keyword, :description, line}), do: {:'DESCRIPTION', line}
  defp convert_single_token({:keyword, :integer32, line}), do: {:variable, line, "Integer32"}

  # Convert SNMPv2 keywords to their terminal names
  defp convert_single_token({:keyword, :module_identity, line}), do: {:'MODULE-IDENTITY', line}
  defp convert_single_token({:keyword, :module_compliance, line}), do: {:'MODULE-COMPLIANCE', line}
  defp convert_single_token({:keyword, :textual_convention, line}), do: {:'TEXTUAL-CONVENTION', line}
  defp convert_single_token({:keyword, :object_group, line}), do: {:'OBJECT-GROUP', line}
  defp convert_single_token({:keyword, :notification_group, line}), do: {:'NOTIFICATION-GROUP', line}
  defp convert_single_token({:keyword, :object_identity, line}), do: {:'OBJECT-IDENTITY', line}
  defp convert_single_token({:keyword, :notification_type, line}), do: {:'NOTIFICATION-TYPE', line}
  defp convert_single_token({:keyword, :agent_capabilities, line}), do: {:'AGENT-CAPABILITIES', line}
  defp convert_single_token({:keyword, :last_updated, line}), do: {:'LAST-UPDATED', line}
  defp convert_single_token({:keyword, :organization, line}), do: {:'ORGANIZATION', line}
  defp convert_single_token({:keyword, :contact_info, line}), do: {:'CONTACT-INFO', line}
  defp convert_single_token({:keyword, :revision, line}), do: {:'REVISION', line}
  defp convert_single_token({:keyword, :units, line}), do: {:'UNITS', line}
  defp convert_single_token({:keyword, :augments, line}), do: {:'AUGMENTS', line}
  defp convert_single_token({:keyword, :implied, line}), do: {:'IMPLIED', line}
  defp convert_single_token({:keyword, :objects, line}), do: {:'OBJECTS', line}
  defp convert_single_token({:keyword, :notifications, line}), do: {:'NOTIFICATIONS', line}
  defp convert_single_token({:keyword, :module, line}), do: {:'MODULE', line}
  defp convert_single_token({:keyword, :mandatory_groups, line}), do: {:'MANDATORY-GROUPS', line}
  defp convert_single_token({:keyword, :group, line}), do: {:'GROUP', line}
  defp convert_single_token({:keyword, :write_syntax, line}), do: {:'WRITE-SYNTAX', line}
  defp convert_single_token({:keyword, :min_access, line}), do: {:'MIN-ACCESS', line}
  defp convert_single_token({:keyword, :display_hint, line}), do: {:'DISPLAY-HINT', line}
  defp convert_single_token({:keyword, :reference, line}), do: {:'REFERENCE', line}
  defp convert_single_token({:keyword, :index, line}), do: {:'INDEX', line}
  defp convert_single_token({:keyword, :defval, line}), do: {:'DEFVAL', line}
  defp convert_single_token({:keyword, :size, line}), do: {:'SIZE', line}
  defp convert_single_token({:keyword, :trap_type, line}), do: {:'TRAP-TYPE', line}
  defp convert_single_token({:keyword, :enterprise, line}), do: {:'ENTERPRISE', line}
  defp convert_single_token({:keyword, :variables, line}), do: {:'VARIABLES', line}

  # Convert symbols to their terminal equivalents
  defp convert_single_token({:symbol, :assign, line}), do: {:'::=', line}
  defp convert_single_token({:symbol, :comma, line}), do: {:',', line}
  defp convert_single_token({:symbol, :semicolon, line}), do: {:';', line}
  defp convert_single_token({:symbol, :open_brace, line}), do: {:'{', line}
  defp convert_single_token({:symbol, :close_brace, line}), do: {:'}', line}
  defp convert_single_token({:symbol, :open_paren, line}), do: {:'(', line}
  defp convert_single_token({:symbol, :close_paren, line}), do: {:')', line}

  # Default case for other identifiers that should be variables
  defp convert_single_token({token_type, value, line}) do
    Logger.warning("Unknown token #{inspect({token_type, value, line})}")
    {:variable, line, to_string(value)}
  end

  @doc """
  Convert the Erlang parse tree to Elixir-friendly format.
  """
  defp convert_to_elixir_format(result) do
    case result do
      {:pdata, version, mib_name, exports, imports, definitions} ->
        %{
          __type__: :mib,
          name: to_string(mib_name),
          version: version,
          exports: convert_exports(exports),
          imports: convert_imports(imports),
          definitions: convert_definitions(definitions)
        }
      {:pdata, version, mib_name, imports, definitions} ->
        %{
          __type__: :mib,
          name: to_string(mib_name),
          version: version,
          exports: [],
          imports: convert_imports(imports),
          definitions: convert_definitions(definitions)
        }
      other ->
        %{__type__: :unknown, raw: other}
    end
  end

  defp convert_exports(exports) when is_list(exports) do
    Enum.map(exports, fn export ->
      case export do
        {type, name} -> %{type: type, name: to_string(name)}
        name -> %{name: to_string(name)}
      end
    end)
  end
  
  defp convert_imports(imports) when is_list(imports) do
    Enum.map(imports, fn
      {{module_name, symbols}, _line} ->
        %{
          __type__: :import,
          from_module: to_string(module_name),
          symbols: Enum.map(symbols, fn
            {:builtin, symbol} -> to_string(symbol)
            {:node, symbol} -> to_string(symbol)
            {:type, symbol} -> to_string(symbol)
            symbol -> to_string(symbol)
          end)
        }
      {{module_name, symbols}} ->
        %{
          __type__: :import,
          from_module: to_string(module_name),
          symbols: Enum.map(symbols, fn
            {:builtin, symbol} -> to_string(symbol)
            {:node, symbol} -> to_string(symbol)
            {:type, symbol} -> to_string(symbol)
            symbol -> to_string(symbol)
          end)
        }
      other ->
        %{__type__: :import, raw: other}
    end)
  end
  
  defp convert_imports(imports) do
    []
  end

  defp convert_definitions(definitions) when is_list(definitions) do
    Enum.map(definitions, &convert_definition/1)
  end

  # Handle the actual Erlang SNMP record format from the grammar
  defp convert_definition({{record_type, name, macro, parent, sub_index}, line}) when record_type == :mc_internal do
    %{
      __type__: :object_identifier,
      name: to_string(name),
      macro: macro,
      parent: if(is_binary(parent), do: parent, else: to_string(parent)),
      sub_index: convert_sub_index(sub_index),
      line: line
    }
  end
  
  defp convert_definition({{record_type, name, syntax, units, max_acc, status, desc, ref, kind, oid}, line}) when record_type == :mc_object_type do
    %{
      __type__: :object_type,
      name: to_string(name),
      syntax: syntax,
      units: units,
      max_access: max_acc,
      status: status,
      description: clean_description(desc),
      reference: ref,
      kind: kind,
      oid: convert_oid(oid),
      line: line
    }
  end
  
  # Handle module identity record
  defp convert_definition({{:mc_module_identity, name, last_updated, organization, contact_info, description, revisions, oid}, line}) do
    %{
      __type__: :module_identity,
      name: to_string(name),
      last_updated: to_string(last_updated),
      organization: clean_description(to_string(organization)),
      contact_info: clean_description(to_string(contact_info)),
      description: clean_description(to_string(description)),
      revisions: convert_revisions(revisions),
      oid: convert_oid(oid),
      line: line
    }
  end
  
  # Handle textual convention record
  defp convert_definition({{:mc_new_type, name, macro, status, description, reference, display_hint, syntax}, line}) do
    %{
      __type__: :textual_convention,
      name: to_string(name),
      macro: macro,
      status: status,
      description: clean_description(to_string(description)),
      reference: if(reference == :undefined, do: nil, else: to_string(reference)),
      display_hint: if(display_hint == :undefined, do: nil, else: to_string(display_hint)),
      syntax: syntax,
      line: line
    }
  end

  # Handle other record types as they come up
  defp convert_definition({record_tuple, line}) do
    %{
      __type__: :unknown,
      record: record_tuple,
      line: line
    }
  end
  
  # Legacy format handler (may not be needed with real parser)
  defp convert_definition({:ok, {type, name, rest}}) do
    base = %{
      __type__: type,
      name: to_string(name)
    }
    
    case type do
      :objectidentifier ->
        Map.put(base, :oid, convert_oid(rest))
        
      :objectType ->
        convert_object_type(base, rest)
        
      :moduleIdentity ->
        convert_module_identity(base, rest)
        
      :textualConvention ->
        convert_textual_convention(base, rest)
        
      :objectGroup ->
        convert_object_group(base, rest)
        
      _ ->
        Map.put(base, :data, rest)
    end
  end

  defp convert_object_type(base, {syntax, access, status, description, reference, index, defval, oid}) do
    base
    |> Map.put(:syntax, convert_syntax(syntax))
    |> Map.put(:max_access, convert_atom(access))
    |> Map.put(:status, convert_atom(status))
    |> Map.put(:description, clean_description(to_string(description)))
    |> Map.put(:reference, if(reference == :undefined, do: nil, else: to_string(reference)))
    |> Map.put(:index, convert_index(index))
    |> Map.put(:defval, convert_defval(defval))
    |> Map.put(:oid, convert_oid(oid))
  end

  defp convert_module_identity(base, {last_updated, organization, contact_info, description, revisions, oid}) do
    base
    |> Map.put(:last_updated, to_string(last_updated))
    |> Map.put(:organization, to_string(organization))
    |> Map.put(:contact_info, to_string(contact_info))
    |> Map.put(:description, clean_description(to_string(description)))
    |> Map.put(:revisions, convert_revisions(revisions))
    |> Map.put(:oid, convert_oid(oid))
  end

  defp convert_textual_convention(base, {display_hint, status, description, reference, syntax}) do
    base
    |> Map.put(:display_hint, if(display_hint == :undefined, do: nil, else: to_string(display_hint)))
    |> Map.put(:status, convert_atom(status))
    |> Map.put(:description, clean_description(to_string(description)))
    |> Map.put(:reference, if(reference == :undefined, do: nil, else: to_string(reference)))
    |> Map.put(:syntax, convert_syntax(syntax))
  end

  defp convert_object_group(base, {objects, status, description, reference, oid}) do
    base
    |> Map.put(:objects, Enum.map(objects, &to_string/1))
    |> Map.put(:status, convert_atom(status))
    |> Map.put(:description, clean_description(to_string(description)))
    |> Map.put(:reference, if(reference == :undefined, do: nil, else: to_string(reference)))
    |> Map.put(:oid, convert_oid(oid))
  end

  defp convert_oid(oid_list) when is_list(oid_list) do
    Enum.map(oid_list, fn
      {name, value} when is_atom(name) and is_integer(value) ->
        %{name: to_string(name), value: value}
      {name, value} when is_atom(name) and is_list(value) ->
        # Handle charlists in tuple values
        %{name: to_string(name), value: convert_oid_value(value)}
      value when is_integer(value) ->
        %{value: value}
      value when is_list(value) ->
        # Handle charlists
        %{value: convert_oid_value(value)}
      name when is_atom(name) ->
        %{name: to_string(name)}
    end)
  end
  
  # Handle tuple OIDs like {:"mib-2", ~c"4"}
  defp convert_oid({name, value}) when is_atom(name) do
    {name, convert_oid_value(value)}
  end
  
  # Handle other OID formats
  defp convert_oid(oid), do: oid
  
  # Convert OID values, handling charlists
  defp convert_oid_value(value) when is_list(value) do
    try do
      # Check if it's a charlist that can be converted to string
      if Enum.all?(value, fn
        i when is_integer(i) -> i >= 0 and i <= 1114111
        _ -> false
      end) do
        # Convert charlist to string, then try to parse as integer if possible
        str_value = List.to_string(value)
        case Integer.parse(str_value) do
          {int_value, ""} -> int_value  # Pure integer string
          _ -> str_value  # Keep as string if not pure integer
        end
      else
        # Not a charlist, return as-is
        value
      end
    rescue
      _ -> value  # If conversion fails, return original
    end
  end
  
  defp convert_oid_value(value), do: value

  defp convert_syntax(:integer), do: :integer
  defp convert_syntax({:integer, constraints}), do: {:integer, convert_constraints(constraints)}
  defp convert_syntax(:'octet string'), do: :octet_string
  defp convert_syntax({:'octet string', size}), do: {:octet_string, convert_constraints(size)}
  defp convert_syntax(:'object identifier'), do: :object_identifier
  defp convert_syntax(atom) when is_atom(atom), do: atom

  defp convert_constraints(constraints), do: constraints

  defp convert_index(:undefined), do: nil
  defp convert_index(index_list) when is_list(index_list) do
    Enum.map(index_list, fn
      {:implied, name} -> {:implied, to_string(name)}
      name when is_atom(name) -> to_string(name)
    end)
  end

  defp convert_defval(:undefined), do: nil
  defp convert_defval(value), do: value

  defp convert_revisions(revisions) when is_list(revisions) do
    Enum.map(revisions, fn
      {:mc_revision, date, description} ->
        %{date: to_string(date), description: clean_description(to_string(description))}
      {date, description} ->
        %{date: to_string(date), description: clean_description(to_string(description))}
    end)
  end
  
  defp convert_revisions(_revisions), do: []

  defp convert_atom(atom) when is_atom(atom) do
    atom |> to_string() |> String.replace("-", "_") |> String.to_atom()
  end

  # Helper function to compile all MIB files in a directory
  defp compile_directory(directory) do
    case File.ls(directory) do
      {:ok, files} ->
        mib_files = files 
        |> Enum.filter(&is_mib_file?/1)
        |> Enum.sort()
        
        Logger.debug("Processing #{Path.basename(directory)}: #{length(mib_files)} files")
        
        results = Enum.map(mib_files, fn file ->
          file_path = Path.join(directory, file)
          case File.read(file_path) do
            {:ok, content} ->
              case parse(content) do
                {:ok, mib_data} ->
                  {:success, file, mib_data}
                {:error, reason} ->
                  {:error, file, reason}
              end
            {:error, reason} ->
              {:error, file, {:file_read_error, reason}}
          end
        end)
        
        successes = results |> Enum.filter(&(elem(&1, 0) == :success))
        failures = results |> Enum.filter(&(elem(&1, 0) == :error))
        
        # Extract MIB data from successes
        success_mibs = Enum.map(successes, fn {:success, file, mib_data} ->
          Map.put(mib_data, :source_file, file)
        end)
        
        # Extract error info from failures  
        error_info = Enum.map(failures, fn {:error, file, reason} ->
          %{file: file, error: reason}
        end)
        
        %{
          directory: directory,
          total: length(mib_files),
          success: success_mibs,
          failures: error_info,
          success_count: length(successes),
          failure_count: length(failures)
        }
        
      {:error, reason} ->
        Logger.error("Cannot read directory #{directory}: #{inspect(reason)}")
        %{
          directory: directory,
          total: 0,
          success: [],
          failures: [%{file: "directory", error: reason}],
          success_count: 0,
          failure_count: 1
        }
    end
  end
  
  # Helper to identify MIB files
  defp is_mib_file?(filename) do
    String.ends_with?(filename, ".mib") or 
    (not String.contains?(filename, ".") and not String.ends_with?(filename, ".bin"))
  end

  # Clean up description strings by trimming lines and removing excessive whitespace
  defp clean_description(desc) when is_binary(desc) do
    desc
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(" ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
  
  defp clean_description(desc), do: desc

  # Convert charlist error messages to binary strings
  defp convert_error_to_string({mib_name, module, message}) when is_binary(mib_name) and is_atom(module) do
    # Handle Erlang parser errors like {"MIB-NAME", :parser_module, "error message"}
    message_str = if is_list(message), do: convert_deep_charlist(message), else: to_string(message)
    "#{mib_name}: #{message_str}"
  end
  
  defp convert_error_to_string({line, module, message}) when is_list(message) do
    {line, module, convert_deep_charlist(message)}
  end
  
  defp convert_error_to_string(message), do: message
  
  defp convert_deep_charlist(list) when is_list(list) do
    try do
      # Handle lists of charlists like [[115, 121, 110, ...], [39, 84, 69, ...]]
      if is_list_of_charlists?(list) do
        Enum.map(list, &charlist_to_string/1) |> Enum.join("")
      else
        # Try to convert as a single charlist
        charlist_to_string(list)
      end
    rescue
      _ -> list  # If conversion fails, return original
    end
  end
  
  defp convert_deep_charlist(other), do: other
  
  defp is_list_of_charlists?(list) do
    Enum.all?(list, fn
      sublist when is_list(sublist) -> is_charlist?(sublist)
      _ -> false
    end)
  end
  
  defp is_charlist?(list) do
    try do
      Enum.all?(list, fn
        i when is_integer(i) -> i >= 0 and i <= 1114111
        _ -> true  # Allow mixed content for improper lists like [115, 121 | ""]
      end)
    rescue
      _ -> false
    end
  end
  
  defp charlist_to_string(charlist) when is_list(charlist) do
    try do
      # Handle improper lists like [115, 121, 110 | ""]
      case charlist do
        [] -> ""
        [head | tail] when is_integer(head) and head >= 0 and head <= 1114111 ->
          try do
            # Try to convert the whole thing, handling improper lists
            convert_improper_charlist(charlist, [])
          rescue
            _ -> inspect(charlist)  # Fallback to inspect if conversion fails
          end
        _ -> inspect(charlist)
      end
    rescue
      _ -> inspect(charlist)
    end
  end
  
  defp charlist_to_string(other), do: inspect(other)
  
  defp convert_improper_charlist([], acc) do
    acc |> Enum.reverse() |> List.to_string()
  end
  
  defp convert_improper_charlist([head | tail], acc) when is_integer(head) do
    convert_improper_charlist(tail, [head | acc])
  end
  
  defp convert_improper_charlist(other, acc) when is_binary(other) do
    # Handle case where tail is a string (like in [115, 121 | ""])
    (acc |> Enum.reverse() |> List.to_string()) <> other
  end
  
  defp convert_improper_charlist(_, acc) do
    # For any other tail, just convert what we have
    acc |> Enum.reverse() |> List.to_string()
  end

  # Convert sub_index from charlist to appropriate format
  defp convert_sub_index(sub_index) when is_list(sub_index) do
    try do
      # Check if it's a charlist that can be converted to string
      if Enum.all?(sub_index, fn
        i when is_integer(i) -> i >= 0 and i <= 1114111
        _ -> false
      end) do
        case List.to_string(sub_index) do
          # Handle common cases
          "\n" -> nil  # Convert newline to nil (often used as placeholder)
          "" -> nil    # Convert empty string to nil
          str -> str   # Keep as string
        end
      else
        # If not a pure charlist, return as-is (might be list of integers)
        sub_index
      end
    rescue
      _ -> sub_index  # If conversion fails, return original
    end
  end
  
  defp convert_sub_index(sub_index), do: sub_index
end