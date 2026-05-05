# 🔐 BigBlack NXC — NetExec Ultimate Interactive Tool

> An interactive Bash wrapper for [NetExec (nxc)](https://github.com/Pennyw0rth/NetExec) — designed to streamline credential gathering and network enumeration during red team engagements and penetration tests.

![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Version](https://img.shields.io/badge/Version-4.1-blue?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS-lightgrey?style=for-the-badge)

---

## ⚠️ Disclaimer

> **For authorized penetration testing and educational purposes only.**
> Unauthorized use of this tool against systems you do not own or have explicit written permission to test is **illegal**.
> The author is not responsible for any misuse or damage caused by this tool.

---

## ✨ Features

| Module | Description |
|---|---|
| 🔐 Authentication Tests | Null, Guest, Local, SMB Signing Check |
| 📋 Basic Enumeration | SMB Info, Shares, Users, RID Brute |
| 📁 SMB Enumeration | Shares, directories, sessions, disks |
| 👥 LDAP Enumeration | Users, groups, computers, domain info |
| 🗄️ MSSQL Enumeration | DB enumeration and query execution |
| 📂 FTP Enumeration | FTP access and file listing |
| 💀 Credential Dumping | SAM, LSA, NTDS, DPAPI, SCCM |
| 🔓 Vulnerability Checking | EternalBlue, PrintNightmare, ZeroLogon, etc. |
| 🛠️ Useful Modules | BloodHound, Mimikatz, PowerShell, WMI |
| 🔑 Password Spraying | Single/list-based spraying with lockout safety |
| 🗺️ Advanced Mapping | Network interfaces, logged users, processes |
| 🎯 All-in-One | Run all enumeration at once |
| 🔑🔐 gMSA Operations | Read gMSA passwords |
| 🔍 Advanced LDAP | ASREPRoast, Kerberoast, ACL, GPO |
| 🧪 Hash Checking | NTLM, NetNTLMv1, NetNTLMv2 from single or file |
| 📝 Session Logging | Auto-save all command output to log file |
| 📊 Auto Report | Generate `.txt` and `.html` report on exit |

---

## 📝 Session Logging & Auto Report

Every time you run the tool, all command output is automatically saved.
When you exit (option `0`), a full report is generated instantly.

```
reports/
├── session_20260418_200000.log     ← raw output log
├── report_20260418_200000.txt      ← plain text summary
└── report_20260418_200000.html     ← dark-theme HTML report
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
git clone https://github.com/sabastiaz/BigBlack-NXC.git
cd BigBlack-NXC
chmod +x nxcbb.sh
```

---

## 🎮 Usage

```bash
./nxcbb.sh
```

The script will prompt you for:
1. **Target** IP / Domain
2. **Credentials** (username, password, domain — optional)
3. Authentication options (Local Auth / Kerberos)

Then presents an interactive menu:

```
╔════════════════════════════════════════╗
║     BigBlack NXC Ultimate Tool        ║
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
 0) ❌ Exit → Generate Report
```

---

## 💡 Example Workflow

```bash
# 1. Start the tool
./nxcbb.sh

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
BigBlack-NXC/
├── nxcbb.sh          # Main interactive script
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
- Blog: [medium.com/@sabastiaz](https://medium.com/@sabastiaz)

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.
