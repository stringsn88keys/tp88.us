# PowerShell Quick Reference for bash/zsh/cmd Users

PowerShell is a cross-platform shell and scripting language built on .NET. Unlike cmd or bash,
it passes **objects** through pipelines, not text — which changes how filtering, sorting, and
formatting work. Aliases exist for most common bash/cmd commands so muscle memory still works,
but the full cmdlet names are more predictable and composable.

**Key concepts:**
- Cmdlets follow a `Verb-Noun` convention: `Get-Process`, `Set-Content`, `Remove-Item`
- The pipeline passes .NET objects, not strings — use `.Property` access instead of `awk`/`cut`
- Tab completion works on cmdlet names, parameters, and property names
- `$_` is the current pipeline object (like `$item` in a `for` loop)
- Most cmdlets have short aliases: `gci` = `Get-ChildItem`, `gc` = `Get-Content`, etc.
- `$env:VAR` accesses environment variables; `$VAR` is a local shell variable

---

## Navigation

| command | from | powershell | abbreviated |
|---------|------|------------|-------------|
| `pwd` | bash | `Get-Location` | `gl` or just `pwd` |
| `cd /path` | bash/cmd | `Set-Location /path` | `cd /path` |
| `cd -` | bash | `Set-Location -` | `cd -` |
| `pushd /path` | bash/cmd | `Push-Location /path` | `pushd /path` |
| `popd` | bash/cmd | `Pop-Location` | `popd` |
| `ls` | bash | `Get-ChildItem` | `ls` or `gci` |
| `ls -la` | bash | `Get-ChildItem -Force` | `ls -Force` |
| `ls -lart` | bash | `Get-ChildItem \| Sort-Object LastWriteTime` | `ls \| sort LastWriteTime` |
| `dir /o:d` | cmd.exe | `Get-ChildItem \| Sort-Object LastWriteTime` | `ls \| sort LastWriteTime` |
| `ls -larS` | bash | `Get-ChildItem \| Sort-Object Length` | `ls \| sort Length` |
| `dir /o:s` | cmd.exe | `Get-ChildItem \| Sort-Object Length` | `ls \| sort Length` |
| `find . -name '*wildcard*'` | bash | `Get-ChildItem -Path . -Include '*wildcard*' -Recurse` | `gci . -inc '*wildcard*' -R` |
| `find . -type f` | bash | `Get-ChildItem -Recurse -File` | `gci -R -File` |
| `find . -type d` | bash | `Get-ChildItem -Recurse -Directory` | `gci -R -Directory` |
| `find . -mtime -1` | bash | `Get-ChildItem -Recurse \| Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-1) }` | `gci -R \| ? { $_.LastWriteTime -gt (Get-Date).AddDays(-1) }` |

---

## File Operations

| command | from | powershell | abbreviated |
|---------|------|------------|-------------|
| `cat file.txt` | bash | `Get-Content file.txt` | `gc file.txt` |
| `type file.txt` | cmd.exe | `Get-Content file.txt` | `gc file.txt` |
| `head -n 20 file.txt` | bash | `Get-Content file.txt -TotalCount 20` | `gc file.txt -Head 20` |
| `tail -n 20 file.txt` | bash | `Get-Content file.txt -Tail 20` | `gc file.txt -Tail 20` |
| `tail -f logfile.log` | bash | `Get-Content logfile.log -Wait` | `gc logfile.log -Wait` |
| `cp src dst` | bash | `Copy-Item src dst` | `cp src dst` |
| `cp -r src/ dst/` | bash | `Copy-Item -Recurse src dst` | `cp -R src dst` |
| `xcopy /s src dst` | cmd.exe | `Copy-Item -Recurse src dst` | `cp -R src dst` |
| `mv src dst` | bash/cmd | `Move-Item src dst` | `mv src dst` |
| `rm file.txt` | bash | `Remove-Item file.txt` | `rm file.txt` |
| `rm -rf dir/` | bash | `Remove-Item -Recurse -Force dir` | `rm -r -fo dir` |
| `rmdir /q /s dir` | cmd.exe | `Remove-Item -Recurse -Force dir` | `rm -r -fo dir` |
| `mkdir dir` | bash/cmd | `New-Item -ItemType Directory dir` | `ni -ItemType Directory dir` |
| `mkdir -p a/b/c` | bash | `New-Item -ItemType Directory -Force a/b/c` | `ni -ItemType Directory -Force a/b/c` |
| `touch file.txt` | bash | `New-Item file.txt -ItemType File` | `ni file.txt` |
| `touch file.txt` (update mtime) | bash | `(Get-Item file.txt).LastWriteTime = Get-Date` | N/A |
| `ln -s target link` | bash | `New-Item -ItemType SymbolicLink -Path link -Target target` | `ni -ItemType SymbolicLink -Path link -Target target` |
| `stat file.txt` | bash | `Get-Item file.txt \| Select-Object *` | `gi file.txt \| select *` |
| `chmod +x file` | bash | `(no direct equivalent — use ACLs)` | N/A |
| `chown user file` | bash | `(Get-Acl / Set-Acl)` | N/A |

---

## Text Processing

| command | from | powershell | abbreviated |
|---------|------|------------|-------------|
| `grep 'pattern' file.txt` | bash | `Select-String -Pattern 'pattern' file.txt` | `sls 'pattern' file.txt` |
| `grep -r 'pattern' .` | bash | `Select-String -Path . -Pattern 'pattern' -Recurse` | `sls -Path . 'pattern' -R` |
| `grep -rn 'pattern' .` | bash | `Select-String -Path . -Pattern 'pattern' -Recurse \| Select-Object Filename, LineNumber, Line` | `sls -Path . 'pattern' -R \| select Filename, LineNumber, Line` |
| `grep -v 'pattern' file` | bash | `Get-Content file \| Where-Object { $_ -notmatch 'pattern' }` | `gc file \| ? { $_ -notmatch 'pattern' }` |
| `grep -c 'pattern' file` | bash | `(Select-String 'pattern' file).Count` | `(sls 'pattern' file).Count` |
| `grep -i 'pattern' file` | bash | `Select-String -Pattern 'pattern' -CaseSensitive:$false file` | `sls 'pattern' file` (case-insensitive by default) |
| `wc -l file.txt` | bash | `(Get-Content file.txt).Count` | `(gc file.txt).Count` |
| `wc -w file.txt` | bash | `(Get-Content file.txt \| Measure-Object -Word).Words` | `(gc file.txt \| measure -Word).Words` |
| `sort file.txt` | bash | `Get-Content file.txt \| Sort-Object` | `gc file.txt \| sort` |
| `sort -r file.txt` | bash | `Get-Content file.txt \| Sort-Object -Descending` | `gc file.txt \| sort -desc` |
| `sort file.txt \| uniq` | bash | `Get-Content file.txt \| Sort-Object -Unique` | `gc file.txt \| sort -Unique` |
| `sort file.txt \| uniq -c` | bash | `Get-Content file.txt \| Group-Object \| Select-Object Count, Name` | `gc file.txt \| group \| select Count, Name` |
| `cut -d: -f1 file` | bash | `Get-Content file \| ForEach-Object { $_.Split(':')[0] }` | `gc file \| % { $_.Split(':')[0] }` |
| `awk '{print $2}' file` | bash | `Get-Content file \| ForEach-Object { ($_ -split '\s+')[1] }` | `gc file \| % { ($_ -split '\s+')[1] }` |
| `sed -i 's/foo/bar/g' file.txt` | bash | `(Get-Content file.txt) -replace 'foo','bar' \| Set-Content file.txt` | `(gc file.txt) -replace 'foo','bar' \| sc file.txt` |
| `sed 's/foo/bar/g' file` (stdout) | bash | `(Get-Content file) -replace 'foo','bar'` | `(gc file) -replace 'foo','bar'` |
| `tr '[:upper:]' '[:lower:]'` | bash | `$str.ToLower()` or `"$str".ToLower()` | N/A |
| `echo "text" \| tee file.txt` | bash | `"text" \| Tee-Object file.txt` | `"text" \| tee file.txt` |

---

## Line Counting by File Type

| command | from | powershell | abbreviated |
|---------|------|------------|-------------|
| `find . -name '*.py' \| xargs wc -l \| tail -1` | bash | `Get-ChildItem -Recurse -Filter '*.py' \| Get-Content \| Measure-Object -Line \| Select-Object -ExpandProperty Lines` | `gci -R -fil '*.py' \| gc \| measure -Line \| % Lines` |
| `find . -name '*.py' \| xargs wc -l \| sort -rn` | bash | `Get-ChildItem -Recurse -Filter '*.py' \| ForEach-Object { [PSCustomObject]@{ File=$_.FullName; Lines=(Get-Content $_).Count } } \| Sort-Object Lines -Descending` | `gci -R -fil '*.py' \| % { [psc]@{File=$_.FullName;Lines=(gc $_).Count} } \| sort Lines -desc` |
| Count lines grouped by extension | bash (complex) | `Get-ChildItem -Recurse -File \| Group-Object Extension \| ForEach-Object { [PSCustomObject]@{ Extension=$_.Name; Lines=($_.Group \| Get-Content \| Measure-Object -Line).Lines } } \| Sort-Object Lines -Descending` | `gci -R -File \| group Extension \| % { [psc]@{Ext=$_.Name;Lines=($_.Group\|gc\|measure -Line).Lines} } \| sort Lines -desc` |

---

## Hex / Binary Inspection

| command | from | powershell | abbreviated |
|---------|------|------------|-------------|
| `xxd file` | bash | `Format-Hex file` | `fhx file` |
| `find . -name '*wildcard*' \| xargs -I {} xxd {}` | bash | `Get-ChildItem -Path . -Include '*wildcard*' -Recurse \| ForEach-Object { Format-Hex $_ }` | `gci '*wildcard*' -R \| foreach { fhx $_ }` |

---

## Environment Variables

| command | from | powershell | abbreviated |
|---------|------|------------|-------------|
| `echo $VAR` | bash | `Write-Output $env:VAR` | `$env:VAR` |
| `echo %VAR%` | cmd.exe | `Write-Output $env:VAR` | `$env:VAR` |
| `export VAR=value` | bash | `$env:VAR = 'value'` | N/A |
| `set VAR=value` | cmd.exe | `$env:VAR = 'value'` | N/A |
| `env` | bash | `Get-ChildItem Env:` | `ls Env:` |
| `printenv PATH` | bash | `$env:PATH` | N/A |
| `unset VAR` | bash | `Remove-Item Env:VAR` | `ri Env:VAR` |
| `VAR=x command` (inline) | bash | `$env:VAR = 'x'; command; Remove-Item Env:VAR` | N/A |

---

## Process Management

| command | from | powershell | abbreviated |
|---------|------|------------|-------------|
| `ps aux` | bash | `Get-Process` | `gps` |
| `ps aux \| grep name` | bash | `Get-Process -Name '*name*'` | `gps -Name '*name*'` |
| `kill -9 PID` | bash | `Stop-Process -Id PID -Force` | `kill -Id PID -Force` |
| `kill -9 $(pgrep name)` | bash | `Get-Process -Name name \| Stop-Process -Force` | `gps name \| kill -Force` |
| `tasklist` | cmd.exe | `Get-Process` | `gps` |
| `taskkill /F /PID PID` | cmd.exe | `Stop-Process -Id PID -Force` | `kill -Id PID -Force` |
| `taskkill /F /IM name.exe` | cmd.exe | `Stop-Process -Name name -Force` | `kill -Name name -Force` |
| `top` / `htop` | bash | `Get-Process \| Sort-Object CPU -Descending \| Select-Object -First 20` | `gps \| sort CPU -desc \| select -First 20` |
| `time {command}` | bash | `Measure-Command { command }` | N/A |
| `nohup cmd &` | bash | `Start-Process cmd -NoNewWindow` | N/A |
| `jobs` | bash | `Get-Job` | `gjb` |
| `bg` / `fg` | bash | `Start-Job` / `Receive-Job` | N/A |

---

## Network

| command | from | powershell | abbreviated |
|---------|------|------------|-------------|
| `ping -c 4 host` | bash | `Test-Connection -Count 4 host` | `tnc host -Count 4` |
| `ping host` | cmd.exe | `Test-Connection host` | `tnc host` |
| `traceroute host` | bash | `Test-NetConnection -TraceRoute host` | `tnc host -TraceRoute` |
| `tracert host` | cmd.exe | `Test-NetConnection -TraceRoute host` | `tnc host -TraceRoute` |
| `netstat -an` | bash/cmd | `Get-NetTCPConnection` | `gntc` |
| `netstat -tlnp` | bash | `Get-NetTCPConnection -State Listen` | `gntc -State Listen` |
| `ss -tlnp` | bash | `Get-NetTCPConnection -State Listen` | `gntc -State Listen` |
| `nslookup host` | bash/cmd | `Resolve-DnsName host` | `rdns host` |
| `dig host` | bash | `Resolve-DnsName host` | `rdns host` |
| `curl -o out.txt URL` | bash | `Invoke-WebRequest -Uri URL -OutFile out.txt` | `iwr URL -OutFile out.txt` |
| `curl -s URL` | bash | `(Invoke-WebRequest URL).Content` | `(iwr URL).Content` |
| `curl -I URL` | bash | `Invoke-WebRequest URL -Method Head` | `iwr URL -Method Head` |
| `wget URL` | bash | `Invoke-WebRequest -Uri URL -OutFile filename` | `iwr URL -OutFile filename` |
| `curl -X POST -d data URL` | bash | `Invoke-RestMethod -Method Post -Body data -Uri URL` | `irm -Method Post -Body data URL` |
| `curl -s URL \| jq .` | bash | `Invoke-RestMethod URL \| ConvertTo-Json` | `irm URL \| ConvertTo-Json` |
| `hostname` | bash/cmd | `hostname` or `$env:COMPUTERNAME` | N/A |
| `ifconfig` / `ip addr` | bash | `Get-NetIPAddress` | N/A |

---

## Disk & Storage

| command | from | powershell | abbreviated |
|---------|------|------------|-------------|
| `df -h` | bash | `Get-PSDrive` | `gdr` |
| `df -h /path` | bash | `Get-PSDrive -Name C` | `gdr C` |
| `du -sh .` | bash | `(Get-ChildItem -Recurse \| Measure-Object Length -Sum).Sum / 1MB` | `(gci -R \| measure Length -Sum).Sum / 1MB` |
| `du -sh dir/*` | bash | `Get-ChildItem \| ForEach-Object { [PSCustomObject]@{ Name=$_.Name; SizeMB=((gci $_ -R -ea SilentlyContinue \| measure Length -Sum).Sum/1MB) } }` | N/A |

---

## Archives

| command | from | powershell | abbreviated |
|---------|------|------------|-------------|
| `tar -czf archive.tar.gz dir/` | bash | `Compress-Archive -Path dir -DestinationPath archive.zip` | N/A |
| `tar -xzf archive.tar.gz` | bash | `Expand-Archive archive.zip -DestinationPath .` | N/A |
| `zip -r archive.zip dir/` | bash | `Compress-Archive -Path dir -DestinationPath archive.zip` | N/A |
| `unzip archive.zip` | bash | `Expand-Archive archive.zip` | N/A |
| `unzip -d dir archive.zip` | bash | `Expand-Archive archive.zip -DestinationPath dir` | N/A |

---

## Output & Redirection

| command | from | powershell | abbreviated |
|---------|------|------------|-------------|
| `echo "text"` | bash/cmd | `Write-Output "text"` | `echo "text"` |
| `echo "text" > file` | bash/cmd | `"text" \| Out-File file` or `"text" > file` | N/A |
| `echo "text" >> file` | bash/cmd | `"text" \| Out-File file -Append` or `"text" >> file` | N/A |
| `cmd 2>&1` | bash | `cmd 2>&1` (works) or `cmd *>&1` (all streams) | N/A |
| `cmd > /dev/null` | bash | `cmd \| Out-Null` or `cmd > $null` | N/A |
| `cmd \| less` | bash | `cmd \| Out-Host -Paging` | `cmd \| oh -Paging` |
| `cmd \| head -n 10` | bash | `cmd \| Select-Object -First 10` | `cmd \| select -First 10` |
| `cmd \| tail -n 10` | bash | `cmd \| Select-Object -Last 10` | `cmd \| select -Last 10` |
| `printf "fmt" args` | bash | `[string]::Format("fmt", args)` or `"$var"` interpolation | N/A |

---

## System Info

| command | from | powershell | abbreviated |
|---------|------|------------|-------------|
| `uname -a` | bash | `[System.Environment]::OSVersion` | N/A |
| `uname -r` (kernel) | bash | `(Get-ComputerInfo).OsVersion` | N/A |
| `hostname` | bash/cmd | `hostname` | N/A |
| `whoami` | bash/cmd | `whoami` or `$env:USERNAME` | N/A |
| `id` | bash | `[Security.Principal.WindowsIdentity]::GetCurrent()` | N/A |
| `date` | bash | `Get-Date` | N/A |
| `date +%Y-%m-%d` | bash | `Get-Date -Format 'yyyy-MM-dd'` | N/A |
| `uptime` | bash | `(Get-Date) - (gcim Win32_OperatingSystem).LastBootUpTime` | N/A |
| `free -h` | bash | `Get-ComputerInfo \| Select-Object TotalPhysicalMemory, *Memory*` | N/A |
| `lscpu` | bash | `Get-ComputerInfo \| Select-Object *Processor*` | N/A |
| `history` | bash | `Get-History` | `h` |
| `history \| grep cmd` | bash | `Get-History \| Where-Object { $_.CommandLine -match 'cmd' }` | `h \| ? { $_.CommandLine -match 'cmd' }` |
| `!n` (run history item n) | bash | `Invoke-History n` | `r n` |
| `clear` | bash/cmd | `Clear-Host` | `cls` or `clear` |

---

## Command Discovery

| command | from | powershell | abbreviated |
|---------|------|------------|-------------|
| `which python` | bash | `Get-Command python` | `gcm python` |
| `where python` | cmd.exe | `Get-Command python` | `gcm python` |
| `man cmd` | bash | `Get-Help cmd -Full` | `help cmd -Full` |
| `cmd --help` | bash | `Get-Help cmd` | `help cmd` |
| `type -a cmd` | bash | `Get-Command cmd \| Select-Object -ExpandProperty Source` | N/A |
| `alias` | bash | `Get-Alias` | `gal` |
| `alias ll='ls -la'` | bash | `Set-Alias ll Get-ChildItem` (simple) or `function ll { ls -Force }` | N/A |
| List all aliases for a cmdlet | bash | `Get-Alias -Definition Get-ChildItem` | `gal -Definition Get-ChildItem` |
