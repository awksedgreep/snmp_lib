#!/bin/bash

# Script to download DOCSIS and vendor-specific MIBs using wget
# Target MIBs: DOCS-CABLE-DEVICE-MIB, DOCS-IF-MIB, DOCS-IF3-MIB, DOCS-IF31-MIB,
# DOCS-FDX-MIB, DOCS-BPI2-MIB, DOCS-SUBMGT-MIB, CISCO-CABLE-WIDEBAND-MIB, ARRIS-CM-DEVICE-MIB
# Dependencies: SNMPv2-SMI, SNMPv2-TC, INET-ADDRESS-MIB, IF-MIB, CLAB-DEF-MIB
# Date: June 1, 2025
# Usage: Save as download_mibs.sh, then run: chmod +x download_mibs.sh && ./download_mibs.sh

# Create directory for MIBs
MIB_DIR="docsis"
mkdir -p "$MIB_DIR"
cd "$MIB_DIR" || exit 1

# Log file for download status
LOG_FILE="mib_download.log"
echo "MIB Download Log - $(date)" > "$LOG_FILE"

# Function to download a MIB with error handling
download_mib() {
    local url="$1"
    local output="$2"
    echo "Downloading $output from $url..." | tee -a "$LOG_FILE"
    if wget --no-check-certificate --tries=3 --timeout=10 -O "$output" "$url"; then
        echo "Successfully downloaded $output" | tee -a "$LOG_FILE"
    else
        echo "Failed to download $output from $url" | tee -a "$LOG_FILE"
    fi
}

# IETF RFC MIBs (RFC 4639, 4546, 4131, 4036)
download_mib "https://www.rfc-editor.org/rfc/mibs/docs-cable-device-mib.mib" "DOCS-CABLE-DEVICE-MIB.mib"
download_mib "https://www.rfc-editor.org/rfc/mibs/docs-if-mib.mib" "DOCS-IF-MIB.mib"
download_mib "https://www.rfc-editor.org/rfc/mibs/docs-bpi2-mib.mib" "DOCS-BPI2-MIB.mib"
download_mib "https://www.rfc-editor.org/rfc/mibs/docs-submgt-mib.mib" "DOCS-SUBMGT-MIB.mib"

# CableLabs MIBs (latest versions as of 2025)
download_mib "https://mibs.cablelabs.com/MIBs/DOCSIS/DOCS-IF3-MIB-2025-02-20.txt" "DOCS-IF3-MIB.txt"
download_mib "https://mibs.cablelabs.com/MIBs/DOCSIS/DOCS-IF31-MIB-2025-04-24.txt" "DOCS-IF31-MIB.txt"
download_mib "https://mibs.cablelabs.com/MIBSs/DOCSIS/DOCS-FDX-MIB-2025-02-20.txt" "DOCS-FDX-MIB.txt"

# Vendor-specific MIBs
# Cisco: CISCO-CABLE-WIDEBAND-MIB (available from Cisco's MIB locator)
download_mib "https://mibs.cloudapps.cisco.com/MIBDownload/MIBDownload?MIBName=CISCO-CABLE-WIDEBAND-MIB" "CISCO-CABLE-WIDEBAND-MIB.mib"

# Arris: ARRIS-CM-DEVICE-MIB (may require authentication)
# Note: Replace <arris_support_url> with the actual URL from Arris support portal
# You may need to download manually from https://www.arris.com/support after logging in
# Placeholder: Uncomment and update if you have the URL and credentials
# download_mib "<arris_support_url>/ARRIS-CM-DEVICE-MIB.txt" "ARRIS-CM-DEVICE-MIB.txt"
echo "ARRIS-CM-DEVICE-MIB: Manual download required from Arris support portal (https://www.arris.com/support)" | tee -a "$LOG_FILE"

# Dependencies for MIB compilation
download_mib "https://www.rfc-editor.org/rfc/mibs/snmpv2-smi.mib" "SNMPv2-SMI.mib"
download_mib "https://www.rfc-editor.org/rfc/mibs/snmpv2-tc.mib" "SNMPv2-TC.mib"
download_mib "https://www.rfc-editor.org/rfc/mibs/inet-address-mib.mib" "INET-ADDRESS-MIB.mib"
download_mib "https://www.rfc-editor.org/rfc/mibs/if-mib.mib" "IF-MIB.mib"
download_mib "https://mibs.cablelabs.com/DOCSIS/CLAB-DEF-MIB.txt" "CLAB-DEF-MIB.txt"

# Verify downloads
echo "Download Summary:" | tee -a "$LOG_FILE"
ls -l | tee -a "$LOG_FILE"

# Instructions for next steps
echo -e "\nNext Steps:" | tee -a "$LOG_FILE"
echo "1. Verify all MIBs are downloaded correctly in the '$MIB_DIR' directory." | tee -a "$LOG_FILE"
echo "2. For ARRIS-CM-DEVICE-MIB, visit https://www.arris.com/support, log in, and download manually." | tee -a "$LOG_FILE"
echo "3. Compile MIBs using a tool like smicng or snmpc (e.g., 'smicng DOCS-CABLE-DEVICE-MIB.mib')." | tee -a "$LOG_FILE"
echo "4. Configure your SNMP agent (e.g., :snmp in Elixir) with the compiled MIBs." | tee -a "$LOG_FILE"
echo "5. Test with snmpwalk (e.g., 'snmpwalk -v2c -c public <device_ip> 1.3.6.1.2.1.69')." | tee -a "$LOG_FILE"

exit 0