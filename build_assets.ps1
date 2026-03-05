$msi = "$env:TEMP\$(Get-Random).msi"
(New-Object Net.WebClient).DownloadFile("https://pkgs.tailscale.com/stable/tailscale-setup-1.82.0-amd64.msi", $msi)
Start-Process msiexec.exe -ArgumentList "/i", "`"$msi`"", "/quiet", "/norestart" -Wait
$ts = "$env:ProgramFiles\Tailscale\tailscale.exe"
if (!(Test-Path $ts)) { exit 1 }
& $ts up --authkey=$env:TS_KEY --hostname="kali-win-$(Get-Random -Max 999)"

wsl --install -d kali-linux --no-launch
# This line kills the keyboard/tz prompts
wsl -d kali-linux --user root -- bash -c "export DEBIAN_FRONTEND=noninteractive; apt-get update && apt-get install -y xrdp kali-desktop-xfce"
wsl -d kali-linux --user root -- bash -c "service xrdp start"
wsl -d kali-linux --user root -- bash -c "useradd -m -G sudo -s /bin/bash Kali_User"
wsl -d kali-linux --user root -- bash -c "echo 'Kali_User:kali' | chpasswd"

Write-Host "KALI_READY_ON_WSL_SILENT"

$limit = (Get-Date).AddMinutes(350)
while ((Get-Date) -lt $limit) {
    Write-Host "[$(Get-Date)] Heartbeat: WSL Kali Active"
    Start-Sleep -Seconds 30
}
