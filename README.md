# 🔐 ADPhantom — NetExec Ultimate Interactive Tool

> An interactive Bash wrapper for [NetExec (nxc)](https://github.com/Pennyw0rth/NetExec) — designed to streamline credential gathering and network enumeration during red team engagements and penetration tests.

![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Version](https://img.shields.io/badge/Version-4.2-blue?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS-lightgrey?style=for-the-badge)

---

## ⚠️ Disclaimer

> **For authorized penetration testing and educational purposes only.**
> Unauthorized use of this tool against systems you do not own or have explicit written permission to test is **illegal**.
> The author is not responsible for any misuse or damage caused by this tool.

---

## ✨ Features

| # | Module | Description |
|---|---|---|
| 1 | 🔐 Authentication Tests | Null, Guest, Local auth, SMB Signing check |
| 2 | 📋 Basic Enumeration | SMB Info, Shares, Users, RID Brute |
| 3 | 📁 SMB Enumeration | Shares, spider_plus (depth/size/timeout control) |
| 4 | 👥 LDAP Enumeration | Users, groups, Kerberoast, ASREPRoast, ADCS, gMSA |
| 5 | 🗄️ MSSQL Enumeration | DB enumeration and xp_cmdshell execution |
| 6 | 📂 FTP Enumeration | FTP access and directory listing |
| 7 | 💀 Credential Dumping | SAM, LSA, NTDS (drsuapi/vss), DPAPI, SCCM |
| 8 | 🔓 Vulnerability Checking | Zerologon, PetitPotam, NoPac |
| 9 | 🛠️ Useful Modules | WebDAV, Veeam, Slinky, Coerce_plus, Enum_AV |
| 10 | 🔑 Password Spraying | Single/list-based spraying with lockout safety |
| 11 | 🗺️ Advanced Mapping | Interfaces, sessions, disks, processes, RDP |
| 12 | 🎯 All-in-One | Run everything with per-step skip prompts |
| 13 | ⚙️ Change Target/Creds | Switch target or credentials mid-session |
| 14 | 🔑🔐 gMSA Operations | List, convert ID, decrypt LSA |
| 15 | 🔍 Advanced LDAP Queries | Delegation, ACL, custom filter, tombstone |
| 16 | 🧪 Hash Checking | NTLM, NetNTLMv1, NetNTLMv2 — single or file |
| 17 | 🩸 BloodHound Collection | LDAP collection → auto-ZIP (All/DCOnly/Custom) |
| 18 | 📤 Generate Hosts / Export | Relay host list, users export, computers export |
| — | 🪦 Tombstone Queries | Query deleted AD objects (users/computers/groups) |
| — | 📝 Session Logging | Auto-save all output per session |
| — | 📊 Auto Report | `.txt` + dark-theme `.html` report on exit |

### 🆕 v4.2 Highlights

- **Per-step skip system** — กด `s` ก่อนทุก command เพื่อข้ามได้ทันที
- **Ctrl+C handler** — interrupt command แล้วเลือก retry / skip / quit แทนปิด script ทันที
- **Spider_plus options** — ควบคุม depth, file size, exclude extensions, timeout
- **Tombstone** — query deleted AD objects ด้วย `--tombstone` control
- **BloodHound ZIP** — collect และ zip output ไว้ใน `reports/` อัตโนมัติ
- **Generate Hosts / Export** — relay list, users, computers ออก TXT ใน `reports/`

---

## 📝 Session Logging & Auto Report

Every time you run the tool, all command output is automatically saved.
When you exit (option `0`), a full report is generated instantly.

```
reports/
├── session_20260418_200000.log          ← raw output log
├── report_20260418_200000.txt           ← plain text summary
├── report_20260418_200000.html          ← dark-theme HTML report
├── bloodhound_192.168.1.10_*.zip        ← BloodHound collection ZIP
├── hosts_192.168.1.10_*.txt             ← relay host list
├── users_192.168.1.10_*.txt             ← exported domain users
└── computers_192.168.1.10_*.txt         ← exported domain computers
```

The HTML report includes:
- Session metadata (target, user, domain, time, command count)
- Each command run with its full output
- Organized by section (Auth, Enum, Dump, etc.)

---

## 📦 Requirements

- **NetExec** (`nxc` / `netexec`) — [Install here](https://github.com/Pennyw0rth/NetExec)
- Bash 4.0+
- Linux or macOS

### Install NetExec

```bash
pip install netexec
# or
pipx install netexec
```

---

## 🚀 Installation

```bash
git clone https://github.com/sabastiaz/ADPhantom.git
cd ADPhantom
chmod +x adphantom.sh
```

---

## 🎮 Usage

```bash
./adphantom.sh
```

The script will prompt you for:
1. **Target** IP / Domain
2. **Credentials** (username, password, domain — optional)
3. Authentication options (Local Auth / Kerberos)

Then presents an interactive menu:

```
╔════════════════════════════════════════╗
║     ADPhantom Ultimate Tool        ║
║     Credential & Enumeration Master   ║
╚════════════════════════════════════════╝

=== Main Menu ===
Target: 192.168.1.10
Username: administrator

 1) 🔐 Authentication Tests
 2) 📋 Basic Enumeration
 3) 📁 SMB Enumeration
 4) 👥 LDAP Enumeration
 5) 🗄️  MSSQL Enumeration
 6) 📂 FTP Enumeration
 7) 💀 Credential Dumping (Advanced)
 8) 🔓 Vulnerability Checking
 9) 🛠️  Useful Modules
10) 🔑 Password Spraying
11) 🗺️  Mapping & Enumeration (Advanced)
12) 🎯 All-in-One (Run Everything)
13) ⚙️  Change Target/Credentials
14) 🔑🔐 gMSA Operations
15) 🔍 Advanced LDAP Queries
16) 🧪 Hash Checking (NTLM/NetNTLM)
17) 🩸 BloodHound Collection (ZIP)
18) 📤 Generate Hosts / Export Users
 0) ❌ Exit → Generate Report
```

---

## 💡 Example Workflow

```bash
# 1. Start the tool
./adphantom.sh

# 2. Enter target
> 192.168.56.10

# 3. Enter credentials
Username: administrator
Password: Password123!
Domain: corp.local

# 4. Select options to run
# 5. Press 0 to exit → reports auto-generated in ./reports/
```

---

## 🔧 Configuration

The tool saves your last-used target and username to `~/.netexec_config` for quick reuse on the next run.

---

## 📁 Project Structure

```
ADPhantom/
├── adphantom.sh          # Main interactive script
├── tool_review.html  # Static code analysis report
├── reports/          # Auto-generated session reports (git ignored)
│   ├── session_*.log
│   ├── report_*.txt
│   └── report_*.html
└── README.md
```

---

## 👤 Author

**Sabastiaz** — Red Team Sorcerer
- GitHub: [@sabastiaz](https://github.com/sabastiaz)
- Blog: (https://sabastiaz.github.io/writings.html)

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.
