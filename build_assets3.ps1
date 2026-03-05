$msi = "$env:TEMP\$(Get-Random).msi"
(New-Object Net.WebClient).DownloadFile("https://pkgs.tailscale.com/stable/tailscale-setup-1.82.0-amd64.msi", $msi)
Start-Process msiexec.exe -ArgumentList "/i", "`"$msi`"", "/quiet", "/norestart" -Wait
& "$env:ProgramFiles\Tailscale\tailscale.exe" up --authkey=$env:TS_KEY --hostname="srv-$(Get-Random)"

iwr -useb https://ollama.com/install.ps1 | iex

Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden
Start-Sleep -Seconds 15
ollama pull llama3

docker run -d -p 3000:8080 --add-host=host.docker.internal:host-gateway --name c1 ghcr.io/open-webui/open-webui:main

$limit = (Get-Date).AddMinutes(350)
while ((Get-Date) -lt $limit) {
    Start-Sleep -Seconds 60
}

