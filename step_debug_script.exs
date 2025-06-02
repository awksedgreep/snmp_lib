
# First, let me trace through the parsing process step by step
{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
{:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)

IO.puts("=== STEP-BY-STEP PARSING DEBUG ===")

# Add debug to parser manually
defmodule DebugParser do
  def step_by_step_parse(tokens) do
    IO.puts("Starting with tokens: #{length(tokens)} total")
    
    # Try to parse header first
    IO.puts("Parsing header...")
    case tokens do
      [{:identifier, mib_name, _} | rest] ->
        IO.puts("MIB name: #{mib_name}")
        case rest do
          [{:keyword, :definitions, _} | rest2] ->
            IO.puts("Found DEFINITIONS")
            case rest2 do
              [{:symbol, :assign, _} | rest3] ->
                IO.puts("Found ::=")
                case rest3 do
                  [{:keyword, :begin, _} | rest4] ->
                    IO.puts("Found BEGIN")
                    IO.puts("Header parsing successful, remaining tokens: #{length(rest4)}")
                    parse_imports(rest4)
                  other ->
                    IO.puts("Expected BEGIN, got: #{inspect(Enum.take(other, 3))}")
                end
              other ->
                IO.puts("Expected ::=, got: #{inspect(Enum.take(other, 3))}")
            end
          other ->
            IO.puts("Expected DEFINITIONS, got: #{inspect(Enum.take(other, 3))}")
        end
      other ->
        IO.puts("Expected identifier, got: #{inspect(Enum.take(other, 3))}")
    end
  end
  
  def parse_imports(tokens) do
    IO.puts("\nParsing imports section...")
    case tokens do
      [{:keyword, :imports, _} | rest] ->
        IO.puts("Found IMPORTS keyword")
        # Find where imports section ends
        {import_tokens, remaining} = find_imports_end(rest, [])
        IO.puts("Import tokens: #{length(import_tokens)}")
        IO.puts("Next 5 tokens after imports: #{inspect(Enum.take(remaining, 5))}")
        parse_definitions(remaining)
      other ->
        IO.puts("No IMPORTS section, proceeding to definitions")
        IO.puts("Next 5 tokens: #{inspect(Enum.take(other, 5))}")
        parse_definitions(other)
    end
  end
  
  def find_imports_end([], acc), do: {Enum.reverse(acc), []}
  def find_imports_end([{:identifier, name, _} | rest], acc) do
    # Check if this starts a definition
    case rest do
      [{:keyword, key, _} | _] when key in [:object_type, :module_identity, :object_identity] ->
        {Enum.reverse(acc), [{:identifier, name, 0} | rest]}
      _ ->
        find_imports_end(rest, [{:identifier, name, 0} | acc])
    end
  end
  def find_imports_end([token | rest], acc) do
    find_imports_end(rest, [token | acc])
  end
  
  def parse_definitions(tokens) do
    IO.puts("\nParsing definitions section...")
    IO.puts("First 10 tokens in definitions: #{inspect(Enum.take(tokens, 10))}")
    # Just see what happens with first definition
    parse_first_definition(tokens)
  end
  
  def parse_first_definition([{:identifier, name, _} | rest]) do
    IO.puts("\nFirst definition: #{name}")
    IO.puts("Next 10 tokens: #{inspect(Enum.take(rest, 10))}")
    # This is likely where the error occurs
  end
  def parse_first_definition(other) do
    IO.puts("Expected identifier for definition, got: #{inspect(Enum.take(other, 5))}")
  end
end

DebugParser.step_by_step_parse(tokens)

