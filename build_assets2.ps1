$url = "https://pkgs.tailscale.com/stable/tailscale-setup-1.82.0-amd64.msi"
$msi = "$env:TEMP\ts.msi"
(New-Object Net.WebClient).DownloadFile($url, $msi)
Start-Process msiexec.exe -ArgumentList "/i", "`"$msi`"", "/quiet", "/norestart" -Wait
$ts = "${env:ProgramFiles}\Tailscale\tailscale.exe"
Start-Service tailscale -ErrorAction SilentlyContinue
& $ts up --authkey=$env:TS_KEY --hostname="roblox-coder-pro" --reset
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
& "$olDir\ollama.exe" pull qwen2.5-coder:3b
pip install --no-cache-dir streamlit ollama
$env:STREAMLIT_BROWSER_GATHER_USAGE_STATS = "false"
$env:STREAMLIT_SERVER_HEADLESS = "true"
$appCode = @"
import streamlit as st
import ollama

st.set_page_config(page_title="Roblox Script Gen", layout="wide")
st.markdown("<style>body {background-color: #0e1117; color: #ffffff;}</style>", unsafe_allow_html=True)
st.title("⚡ Pro Roblox Luau Coder")
st.caption("Running Qwen2.5-Coder 3B - Optimized for Exploits")

if "messages" not in st.session_state:
    st.session_state.messages = [{"role": "system", "content": "You are an expert Roblox Luau scripter. You write optimized, clean scripts for executors like Synapse, Sentinel, or ScriptWare. Always use task.wait() and modern Luau practices."}]

for m in st.session_state.messages:
    if m["role"] != "system":
        with st.chat_message(m["role"]):
            st.markdown(m["content"])

if p := st.chat_input("What script do you need?"):
    st.session_state.messages.append({"role": "user", "content": p})
    with st.chat_message("user"): st.markdown(p)
    with st.chat_message("assistant"):
        res_area = st.empty()
        full_res = ""
        try:
            stream = ollama.chat(model='qwen2.5-coder:3b', messages=st.session_state.messages, stream=True)
            for chunk in stream:
                full_res += chunk['message']['content']
                res_area.markdown(full_res + "▌")
            res_area.markdown(full_res)
            st.session_state.messages.append({"role": "assistant", "content": full_res})
        except Exception as e:
            st.error(f"Error: {e}")
"@
Set-Content -Path "app.py" -Value $appCode
Start-Process streamlit -ArgumentList "run app.py --server.port 8501 --server.address 0.0.0.0" -NoNewWindow
Start-Sleep -Seconds 30
$tsIp = (& $ts ip -4).Trim()
while ($true) {
    $web = Test-NetConnection -ComputerName localhost -Port 8501 -ErrorAction SilentlyContinue
    if ($web.TcpTestSucceeded) {
        Write-Host "READY: http://$($tsIp):8501"
    }
    Start-Sleep -Seconds 30
}
