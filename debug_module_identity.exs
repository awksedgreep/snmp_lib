#!/usr/bin/env elixir

# Debug the MODULE-IDENTITY parsing flow in IF-MIB

System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

docsis_dir = "test/fixtures/mibs/docsis"
mib_path = Path.join(docsis_dir, "IF-MIB")

IO.puts("=== Debugging MODULE-IDENTITY Flow in IF-MIB ==")

case File.read(mib_path) do
  {:ok, content} ->
    IO.puts("✓ File read: #{byte_size(content)} bytes")
    
    case SnmpLib.MIB.LexerErlangPort.tokenize(content) do
      {:ok, tokens} ->
        IO.puts("✓ Tokenization successful: #{length(tokens)} tokens")
        
        # Find the first MODULE-IDENTITY token
        module_identity_index = tokens
        |> Enum.with_index()
        |> Enum.find(fn {{type, value, _}, _idx} ->
          type == :keyword and value == :module_identity
        end)
        
        case module_identity_index do
          {{_type, _value, _meta}, idx} ->
            IO.puts("Found MODULE-IDENTITY at index #{idx}")
            
            # Get the identifier before MODULE-IDENTITY
            case Enum.at(tokens, idx - 1) do
              {:variable, name, _} ->
                IO.puts("✓ Found MODULE-IDENTITY for: #{name}")
                
                # Try to manually step through the MODULE-IDENTITY parsing
                IO.puts("\nStepping through MODULE-IDENTITY parsing...")
                
                # Start with tokens after "name MODULE-IDENTITY"
                start_tokens = Enum.drop(tokens, idx + 1)
                IO.puts("Starting MODULE-IDENTITY parsing with #{length(start_tokens)} tokens")
                
                # Step 1: LAST-UPDATED
                IO.puts("\n--- Step 1: LAST-UPDATED ---")
                case start_tokens do
                  [{:keyword, :last_updated, _}, {:string, last_updated, _} | after_last_updated] ->
                    IO.puts("✓ LAST-UPDATED: #{last_updated}")
                    
                    # Step 2: ORGANIZATION  
                    IO.puts("\n--- Step 2: ORGANIZATION ---")
                    case after_last_updated do
                      [{:keyword, :organization, _}, {:string, org, _} | after_org] ->
                        IO.puts("✓ ORGANIZATION: #{String.slice(org, 0, 50)}...")
                        
                        # Step 3: CONTACT-INFO
                        IO.puts("\n--- Step 3: CONTACT-INFO ---")
                        case after_org do
                          [{:keyword, :contact_info, _} | after_contact_start] ->
                            IO.puts("✓ Found CONTACT-INFO keyword")
                            IO.puts("Next 5 tokens after CONTACT-INFO:")
                            Enum.take(after_contact_start, 5)
                            |> Enum.with_index()
                            |> Enum.each(fn {token, i} ->
                              IO.puts("  #{i}: #{inspect(token)}")
                            end)
                            
                            # Try parsing contact info
                            case SnmpLib.MIB.Parser.parse_contact_info_clause([{:keyword, :contact_info, nil} | after_contact_start]) do
                              {:ok, {contact_info, after_contact}} ->
                                IO.puts("✓ CONTACT-INFO parsed successfully")
                                IO.puts("Contact info length: #{String.length(contact_info)} chars")
                                
                                # Step 4: DESCRIPTION  
                                IO.puts("\n--- Step 4: DESCRIPTION ---")
                                IO.puts("Tokens at description parsing (first 10):")
                                Enum.take(after_contact, 10)
                                |> Enum.with_index()
                                |> Enum.each(fn {token, i} ->
                                  IO.puts("  #{i}: #{inspect(token)}")
                                end)
                                
                                # Try parsing description
                                case SnmpLib.MIB.Parser.parse_description_clause(after_contact) do
                                  {:ok, {description, after_description}} ->
                                    IO.puts("✓ DESCRIPTION parsed successfully")
                                    IO.puts("Description length: #{if description, do: String.length(description), else: 0} chars")
                                    IO.puts("Remaining tokens after description (first 5):")
                                    Enum.take(after_description, 5)
                                    |> Enum.with_index()
                                    |> Enum.each(fn {token, i} ->
                                      IO.puts("  #{i}: #{inspect(token)}")
                                    end)
                                  {:error, reason} ->
                                    IO.puts("❌ DESCRIPTION parsing failed: #{inspect(reason)}")
                                end
                                
                              {:error, reason} ->
                                IO.puts("❌ CONTACT-INFO parsing failed: #{inspect(reason)}")
                            end
                            
                          other ->
                            IO.puts("❌ Expected CONTACT-INFO, got: #{inspect(Enum.take(other, 3))}")
                        end
                        
                      other ->
                        IO.puts("❌ Expected ORGANIZATION, got: #{inspect(Enum.take(other, 3))}")
                    end
                    
                  other ->
                    IO.puts("❌ Expected LAST-UPDATED, got: #{inspect(Enum.take(other, 3))}")
                end
                
              other ->
                IO.puts("❌ Expected variable before MODULE-IDENTITY, got: #{inspect(other)}")
            end
            
          nil ->
            IO.puts("Could not find MODULE-IDENTITY token")
        end
        
      {:error, reason} ->
        IO.puts("❌ Tokenization failed: #{reason}")
    end
    
  {:error, reason} ->
    IO.puts("❌ File read failed: #{reason}")
end