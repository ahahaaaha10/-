$u = "https://pkgs.tailscale.com/stable/tailscale-setup-1.82.0-amd64.msi"
$m = "$env:TEMP\ts.msi"
(New-Object Net.WebClient).DownloadFile($u, $m)
Start-Process msiexec.exe -ArgumentList "/i", "`"$m`"", "/quiet", "/norestart" -Wait
$ts = "$env:ProgramFiles\Tailscale\tailscale.exe"
Stop-Service tailscale -Force -ErrorAction SilentlyContinue
Start-Service tailscale
$key = $env:TS_KEY
& $ts up --authkey=$key --hostname="ai-node" --reset

pip install --no-cache-dir streamlit ollama

$appCode = @"
import streamlit as st
import ollama
st.set_page_config(page_title="Unrestricted Node", layout="wide")
st.title("💀 Unrestricted AI Node")
if "messages" not in st.session_state:
    st.session_state.messages = []
for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])
if prompt := st.chat_input("Input command..."):
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.markdown(prompt)
    with st.chat_message("assistant"):
        response = ollama.chat(model='dolphin-mistral', messages=[{'role': 'user', 'content': prompt}])
        msg = response['message']['content']
        st.markdown(msg)
    st.session_state.messages.append({"role": "assistant", "content": msg})
"@
Set-Content -Path "app.py" -Value $appCode

# FIXED URL: Using the latest stable GitHub release link
$olUrl = "https://github.com/ollama/ollama/releases/download/v0.5.11/ollama-windows-amd64.zip"
try {
    (New-Object Net.WebClient).DownloadFile($olUrl, "$env:TEMP\ol.zip")
} catch {
    Write-Host "Primary URL failed, trying fallback..."
    $olUrl = "https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.zip"
    (New-Object Net.WebClient).DownloadFile($olUrl, "$env:TEMP\ol.zip")
}

Expand-Archive -Path "$env:TEMP\ol.zip" -DestinationPath "$env:USERPROFILE\ollama" -Force
Start-Process -FilePath "$env:USERPROFILE\ollama\ollama.exe" -ArgumentList "serve" -NoNewWindow
Start-Sleep -Seconds 15

& "$env:USERPROFILE\ollama\ollama.exe" pull dolphin-mistral

Write-Host "Booting Streamlit UI..."
Start-Process streamlit -ArgumentList "run app.py --server.port 8501 --server.address 0.0.0.0" -NoNewWindow

while ($true) {
    Write-Host "[$(Get-Date)] AI Node Live at http://ai-node:8501"
    Start-Sleep -Seconds 60
}
