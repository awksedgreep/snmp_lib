#!/usr/bin/env elixir

Application.put_env(:snmp_lib, :environment, :test)

defmodule MinimalDocsCableDeviceTest do
  @moduledoc "Test minimal version of DOCS-CABLE-DEVICE-MIB to isolate issue"

  def test_minimal_docs_cable_device do
    IO.puts("Testing minimal DOCS-CABLE-DEVICE-MIB...")
    
    # Use the exact structure from the real MIB, but just the essential parts
    minimal_mib_content = """
    DOCS-CABLE-DEVICE-MIB DEFINITIONS ::= BEGIN

    IMPORTS
        MODULE-IDENTITY,
        OBJECT-TYPE,
        IpAddress,
        Unsigned32,
        Counter32,
        Counter64,
        BITS,
        Integer32,
        OBJECT-IDENTITY
        FROM SNMPv2-SMI

        TEXTUAL-CONVENTION,
        MacAddress,
        RowStatus,
        RowPointer,
        DateAndTime,
        TruthValue,
        TimeStamp,
        PhysAddress,
        TEXTUAL-CONVENTION
        FROM SNMPv2-TC

        OBJECT-GROUP,
        MODULE-COMPLIANCE
        FROM SNMPv2-CONF

        docsIfCmtsCmStatusIndex,
        docsIfCmtsCmStatusMacAddress
        FROM DOCS-IF-MIB

        InterfaceIndexOrZero,
        ifIndex,
        InterfaceIndex
        FROM IF-MIB

        InetAddressType,
        InetAddress,
        InetPortNumber
        FROM INET-ADDRESS-MIB

        SnmpAdminString
        FROM SNMP-FRAMEWORK-MIB

        mib-2, zeroDotZero
        FROM SNMPv2-SMI;

    docsDev MODULE-IDENTITY
        LAST-UPDATED    "200612200000Z"
        ORGANIZATION    "IETF IP over Cable Data Network Working Group"
        CONTACT-INFO
            "Rich Woundy
             Postal: Comcast Cable"
        DESCRIPTION
            "This is the MIB Module for DOCSIS-compliant cable modems and cable-modem termination systems."
        ::= { mib-2 69 }

    docsDevMIBObjects  OBJECT IDENTIFIER ::= { docsDev 1 }

    docsDevBase OBJECT IDENTIFIER ::= { docsDevMIBObjects 1 }

    docsDevRole OBJECT-TYPE
        SYNTAX INTEGER {
            cm(1),
            cmtsActive(2),
            cmtsBackup(3)
        }
        MAX-ACCESS read-only
        STATUS current
        DESCRIPTION
            "Defines the current role of this device."
        ::= { docsDevBase 1 }

    END
    """
    
    IO.puts("Parsing minimal MIB...")
    result = SnmpLib.MIB.Parser.parse(minimal_mib_content)
    
    case result do
      {:error, [error]} -> 
        IO.puts("❌ Error occurred:")
        IO.puts("  Type: #{error.type}")
        IO.puts("  Message: #{inspect(error.message)}")
        IO.puts("  Line: #{error.line}")
        
        if String.contains?(error.message, "MAX-ACCESS") do
          IO.puts("\n🔍 MAX-ACCESS error reproduced in minimal test!")
        end
        
      {:ok, mib} -> 
        IO.puts("✅ Success! MIB name: #{mib.name}")
        IO.puts("✅ Definitions parsed: #{length(mib.definitions)}")
        
        mib.definitions
        |> Enum.with_index()
        |> Enum.each(fn {def, idx} ->
          IO.puts("  #{idx + 1}. #{def.name} (#{def.__type__})")
        end)
    end
  end
end

MinimalDocsCableDeviceTest.test_minimal_docs_cable_device()