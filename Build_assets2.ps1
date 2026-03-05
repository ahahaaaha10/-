$msi = "$env:TEMP\$(Get-Random).msi"
(New-Object Net.WebClient).DownloadFile("https://pkgs.tailscale.com/stable/tailscale-setup-1.82.0-amd64.msi", $msi)
Start-Process msiexec.exe -ArgumentList "/i", "`"$msi`"", "/quiet", "/norestart" -Wait
$ts = "$env:ProgramFiles\Tailscale\tailscale.exe"
if (!(Test-Path $ts)) { exit 1 }
$key = $env:TS_KEY
& $ts up --authkey=$key --hostname="kali-win-$(Get-Random -Max 999)"

docker pull kalilinux/kali-rolling
docker run -d --name kali_node -p 3389:3389 -p 22:22 kalilinux/kali-rolling sleep infinity
docker exec kali_node apt-get update
docker exec kali_node apt-get install -y kali-desktop-xfce xrdp openssh-server
docker exec kali_node service xrdp start
docker exec kali_node service ssh start
docker exec kali_node useradd -m -G sudo -s /bin/bash Kali_User
docker exec kali_node bash -c "echo 'Kali_User:Pass$(Get-Random -Max 9999)!' | chpasswd"

Write-Host "KALI_READY"
docker exec kali_node bash -c "grep 'Kali_User' /etc/shadow"

$limit = (Get-Date).AddMinutes(350)
while ((Get-Date) -lt $limit) {
    Write-Host "[$(Get-Date)] Heartbeat: Kali Container Active"
    Start-Sleep -Seconds 30
}

