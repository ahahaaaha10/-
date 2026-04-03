$url = "https://pkgs.tailscale.com/stable/tailscale-setup-1.82.0-amd64.msi"
$msi = "$env:TEMP\ts.msi"
(New-Object Net.WebClient).DownloadFile($url, $msi)
Start-Process msiexec.exe -ArgumentList "/i", "`"$msi`"", "/quiet", "/norestart" -Wait
$ts = "${env:ProgramFiles}\Tailscale\tailscale.exe"
Start-Service tailscale -ErrorAction SilentlyContinue
& $ts up --authkey=$env:TS_KEY --hostname="osint-node" --reset
$olUrl = "https://github.com/ollama/ollama/releases/download/v0.5.11/ollama-windows-amd64.zip"
(New-Object Net.WebClient).DownloadFile($olUrl, "$env:TEMP\ol.zip")
Expand-Archive -Path "$env:TEMP\ol.zip" -DestinationPath "$env:USERPROFILE\ollama" -Force
$env:OLLAMA_HOST = "127.0.0.1:11434"
Start-Process -FilePath "$env:USERPROFILE\ollama\ollama.exe" -ArgumentList "serve" -NoNewWindow
pip install --no-cache-dir streamlit ollama requests
for ($i=0; $i -lt 20; $i++) {
    $check = Test-NetConnection -ComputerName 127.0.0.1 -Port 11434 -ErrorAction SilentlyContinue
    if ($check.TcpTestSucceeded) { break }
    Start-Sleep -Seconds 5
}
& "$env:USERPROFILE\ollama\ollama.exe" pull qwen2.5-coder:3b
$appCode = @"
import streamlit as st
import requests
import ollama
import os

st.set_page_config(page_title="OSINT NODE", layout="wide")
st.markdown("<style>.stApp {background-color: #0a0a0a; color: #00ff00; font-family: 'Courier New', monospace;}</style>", unsafe_allow_html=True)
st.title("🕵️ OSINT | RECONNAISSANCE NODE")

hook = os.getenv('DISCORD_WEBHOOK', '')

tab1, tab2, tab3 = st.tabs(["👤 USERNAME HUNTER", "🌐 IP/DOMAIN RECON", "🧠 AI ANALYSIS"])

with tab1:
    user = st.text_input("ENTER TARGET USERNAME")
    if st.button("HUNT"):
        platforms = ["github.com", "instagram.com", "twitter.com", "reddit.com/user", "roblox.com/users/profile?username="]
        for p in platforms:
            url = f"https://{p}/{user}"
            try:
                r = requests.get(url, timeout=5)
                status = "✅ FOUND" if r.status_code == 200 else "❌ NOT FOUND"
                st.write(f"{p}: {status}")
            except: pass

with tab2:
    ip_target = st.text_input("ENTER IP OR DOMAIN")
    if st.button("SCAN"):
        r = requests.get(f"http://ip-api.com/json/{ip_target}").json()
        st.json(r)

with tab3:
    raw_intel = st.text_area("PASTE INTEL FOR ANALYSIS", height=200)
    if st.button("RUN AI RECON"):
        p = f"You are an OSINT expert. Analyze this data and find connections, patterns, or leaks. Be professional. DATA:\n{raw_intel}"
        res = st.empty()
        full = ""
        for chunk in ollama.chat(model='qwen2.5-coder:3b', messages=[{'role': 'user', 'content': p}], stream=True):
            full += chunk['message']['content']
            res.markdown(full)
        if hook and full:
            requests.post(hook, json={"content": f"**INTEL REPORT:**\n{full[:1900]}"})
"@
Set-Content -Path "app.py" -Value $appCode
$env:STREAMLIT_BROWSER_GATHER_USAGE_STATS = "false"
$env:STREAMLIT_SERVER_HEADLESS = "true"
$env:DISCORD_WEBHOOK = "$env:DISCORD_WEBHOOK"
Start-Process streamlit -ArgumentList "run app.py --server.port 8501 --server.address 0.0.0.0" -NoNewWindow
$tsIp = (& $ts ip -4).Trim()
while ($true) {
    Write-Host "OSINT NODE: http://$($tsIp):8501"
    Start-Sleep -Seconds 60
}
