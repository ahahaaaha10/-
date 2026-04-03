$url = "https://pkgs.tailscale.com/stable/tailscale-setup-1.82.0-amd64.msi"
$msi = "$env:TEMP\ts.msi"
(New-Object Net.WebClient).DownloadFile($url, $msi)
Start-Process msiexec.exe -ArgumentList "/i", "`"$msi`"", "/quiet", "/norestart" -Wait
$ts = "${env:ProgramFiles}\Tailscale\tailscale.exe"
Start-Service tailscale -ErrorAction SilentlyContinue
& $ts up --authkey=$env:TS_KEY --hostname="ai-node" --reset
$olUrl = "https://github.com/ollama/ollama/releases/download/v0.5.11/ollama-windows-amd64.zip"
$olZip = "$env:TEMP\ol.zip"
$olDir = "$env:USERPROFILE\ollama"
(New-Object Net.WebClient).DownloadFile($olUrl, $olZip)
Expand-Archive -Path $olZip -DestinationPath $olDir -Force
$env:OLLAMA_HOST = "127.0.0.1:11434"
Start-Process -FilePath "$olDir\ollama.exe" -ArgumentList "serve" -NoNewWindow
for ($i=0; $i -lt 20; $i++) {
    $check = Test-NetConnection -ComputerName 127.0.0.1 -Port 11434 -ErrorAction SilentlyContinue
    if ($check.TcpTestSucceeded) { break }
    Start-Sleep -Seconds 5
}
& "$olDir\ollama.exe" pull dolphin-mistral
pip install --no-cache-dir streamlit ollama
$env:STREAMLIT_BROWSER_GATHER_USAGE_STATS = "false"
$env:STREAMLIT_SERVER_HEADLESS = "true"
$appCode = @"
import streamlit as st
import ollama
st.set_page_config(page_title="Unrestricted AI", layout="wide")
st.title("💀 Unrestricted AI Node")
if "messages" not in st.session_state:
    st.session_state.messages = []
for m in st.session_state.messages:
    with st.chat_message(m["role"]):
        st.markdown(m["content"])
if p := st.chat_input("Send command..."):
    st.session_state.messages.append({"role": "user", "content": p})
    with st.chat_message("user"): st.markdown(p)
    with st.chat_message("assistant"):
        try:
            r = ollama.chat(model='dolphin-mistral', messages=[{'role': 'user', 'content': p}])
            msg = r['message']['content']
            st.markdown(msg)
            st.session_state.messages.append({"role": "assistant", "content": msg})
        except Exception as e:
            st.error(f"AI Error: {e}")
"@
Set-Content -Path "app.py" -Value $appCode
Start-Process streamlit -ArgumentList "run app.py --server.port 8501 --server.address 0.0.0.0" -NoNewWindow
Start-Sleep -Seconds 30
$tsIp = (& $ts ip -4).Trim()
while ($true) {
    $web = Test-NetConnection -ComputerName localhost -Port 8501 -ErrorAction SilentlyContinue
    if ($web.TcpTestSucceeded) {
        Write-Host "URL: http://$($tsIp):8501"
    }
    Start-Sleep -Seconds 30
}
