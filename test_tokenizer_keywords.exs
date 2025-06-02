#!/usr/bin/env elixir

defmodule TestTokenizerKeywords do
  def run do
    IO.puts("🧪 Testing tokenizer with SNMPv2 keywords that were missing...")
    
    # Test specific SNMPv2 keywords that were causing failures
    test_cases = [
      "MODULE-COMPLIANCE",
      "MODULE-IDENTITY", 
      "TEXTUAL-CONVENTION",
      "OBJECT-GROUP",
      "IMPLIED",
      "MODULE"
    ]
    
    Enum.each(test_cases, fn keyword ->
      test_string = keyword <> " ::= BEGIN END"
      IO.puts("\n📝 Testing keyword: #{keyword}")
      
      case SnmpLib.MIB.SnmpTokenizer.tokenize(to_charlist(test_string), &SnmpLib.MIB.SnmpTokenizer.null_get_line/0) do
        {:ok, tokens} ->
          # Find the keyword token
          keyword_tokens = tokens
          |> Enum.filter(fn
            {atom, _line} when is_atom(atom) ->
              atom_str = Atom.to_string(atom)
              String.contains?(atom_str, String.replace(keyword, "-", "")) or atom_str == keyword
            {atom, _line, _value} when is_atom(atom) ->
              atom_str = Atom.to_string(atom)
              String.contains?(atom_str, String.replace(keyword, "-", "")) or atom_str == keyword
            _ -> false
          end)
          
          if length(keyword_tokens) > 0 do
            IO.puts("✅ SUCCESS: #{keyword} tokenized as #{inspect(keyword_tokens)}")
          else
            IO.puts("❌ FAILED: #{keyword} not found in tokens")
            IO.puts("   All tokens: #{inspect(tokens)}")
          end
          
        {:error, reason} ->
          IO.puts("❌ TOKENIZATION_FAILED: #{inspect(reason)}")
      end
    end)
    
    IO.puts("\n" <> String.duplicate("=", 50))
    IO.puts("🧪 Testing with AGENTX-MIB MODULE-COMPLIANCE section...")
    
    # Test the actual MODULE-COMPLIANCE section from AGENTX-MIB
    module_compliance_snippet = """
    agentxMIBCompliance MODULE-COMPLIANCE
      STATUS      current
      DESCRIPTION
         "The compliance statement for SNMP entities that implement the
          AgentX protocol."
      MODULE -- this module
         MANDATORY-GROUPS  { agentxMIBGroup }
    """
    
    case SnmpLib.MIB.SnmpTokenizer.tokenize(to_charlist(module_compliance_snippet), &SnmpLib.MIB.SnmpTokenizer.null_get_line/0) do
      {:ok, tokens} ->
        IO.puts("✅ SUCCESS: MODULE-COMPLIANCE snippet tokenized!")
        
        # Count specific tokens
        module_compliance_count = tokens |> Enum.count(fn {t, _} -> t == :'MODULE-COMPLIANCE' end)
        module_count = tokens |> Enum.count(fn {t, _} -> t == :'MODULE' end)
        status_count = tokens |> Enum.count(fn {t, _} -> t == :'STATUS' end)
        
        IO.puts("   Found:")
        IO.puts("   - MODULE-COMPLIANCE tokens: #{module_compliance_count}")
        IO.puts("   - MODULE tokens: #{module_count}")
        IO.puts("   - STATUS tokens: #{status_count}")
        
      {:error, reason} ->
        IO.puts("❌ MODULE-COMPLIANCE snippet failed: #{inspect(reason)}")
    end
  end
end

TestTokenizerKeywords.run()