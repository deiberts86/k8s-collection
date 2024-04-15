# Create Windows RKE2 Agent with Internet Access

- Requirements:
  - Supported CNI's are `Flannel` or `Calico` ONLY!
  - When creating the VM through Harvester, ensure that you have selected the network interface to be e1000e
  - your initial ISO should be a cd-rom
  - If you desire to have virtIO drivers, there are more steps involved here:
    - [Windows VM with VirtIO](https://docs.harvesterhci.io/v1.1/vm/create-windows-vm/#how-to-create-a-windows-vm)

- References:
  - [Network-adapter for Harvester](https://rickardnobel.se/vmxnet3-vs-e1000e-and-e1000-part-1/) |  Use `e1000e`
  - [RKE2 Docs for Windows](https://docs.rke2.io/install/windows_airgap)

1. Requires containers WindowsFeature to be enabled. The powershell script below will install and force reboot the server to ensure compatibility.
```powershell
Enable-WindowsOptionalFeature -FeatureName containers –All -Online -NoRestart -OutVariable results
if ($results.RestartNeeded -eq $true) {
  Restart-Computer -Force
}
```

2. Create designated folder for RKE2 executable
```powershell
new-item -ItemType Directory -Path c:\usr\local\bin
cd c:\usr\local\bin
```

3. Pull RKE2 executable and place in `c:\usr\local\bin`
  - Note, curl should be installed on Windows 2022. If not, use `Invoke-WebRequest` which is slower...

- With Curl
```powershell
# Grab powershell script for installation
curl.exe -fSLo c:\users\administrator\desktop\install-rke2_agent.ps1 "https://raw.githubusercontent.com/rancher/rke2/master/install.ps1"
# Grab RKE2 Executable binary
curl.exe -fSLo c:\usr\local\bin\rke2.exe "https://github.com/rancher/rke2/releases/download/v1.26.15%2Brke2r1/rke2-windows-amd64.exe"
```

- With Invoke-WebRequest
```powershell
# Grab powershell script for installation
Invoke-WebRequest -Verbose -Uri "https://raw.githubusercontent.com/rancher/rke2/master/install.ps1" -Outfile "c:/Users/Administrator/Desktopinstall.ps1"
# Grab RKE2 Executable binary
Invoke-WebRequest -Verbose -Uri "https://github.com/rancher/rke2/releases/download/v1.26.15%2Brke2r1/rke2-windows-amd64.exe" -OutFile "c:/usr/local/bin/rke2.exe"
```

4. Configure RKE2-Agent for Windows 

```powershell
New-Item -Type Directory c:/etc/rancher/rke2 -Force
Set-Content -Path c:/etc/rancher/rke2/config.yaml -Value @"
server: https://<server>:9345
token: <token from server node>
"@
```

5. Set Environment for RKE2
```powershell
$env:PATH+=";c:\var\lib\rancher\rke2\bin;c:\usr\local\bin"

[Environment]::SetEnvironmentVariable(
    "Path",
    [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";c:\var\lib\rancher\rke2\bin;c:\usr\local\bin",
    [EnvironmentVariableTarget]::Machine)
```

6. Running the installer
```powershell
.\"c:\Users\Administrator\Desktopinstall.ps1"
```

7. Start the Windows RKE2 Agent
```powershell
rke2 agent service --add
Start-Service rke2
```

8. Ensure agent installs / registers with cluster you choose.
9. If needed, check event-viewer to validate you don't have errors.
10. Enjoy!