$msi = "$env:TEMP\$(Get-Random).msi"
(New-Object Net.WebClient).DownloadFile("https://pkgs.tailscale.com/stable/tailscale-setup-1.82.0-amd64.msi", $msi)
Start-Process msiexec.exe -ArgumentList "/i", "`"$msi`"", "/quiet", "/norestart" -Wait
& "$env:ProgramFiles\Tailscale\tailscale.exe" up --authkey=$env:TS_KEY --hostname="srv-$(Get-Random)"

# 1. Install Ollama (Native)
iwr -useb https://ollama.com/install.ps1 | iex
Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden
Start-Sleep -Seconds 15
ollama pull llama3

# 2. Install Open WebUI (Native via Python)
# GitHub Runners have Python 3.12+ pre-installed
pip install open-webui

# 3. Start the Web Server on Port 3000
# We use 'start' so it runs in its own process
Start-Process "open-webui" -ArgumentList "serve", "--port", "3000" -WindowStyle Hidden

Write-Host "================================"
Write-Host "AI INTERFACE: http://[YOUR-TAILSCALE-IP]:3000"
Write-Host "MODE: Native Python (No Docker)"
Write-Host "================================"

$limit = (Get-Date).AddMinutes(350)
while ((Get-Date) -lt $limit) {
    Start-Sleep -Seconds 60
}
