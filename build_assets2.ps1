[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$url = "https://pkgs.tailscale.com/stable/tailscale-setup-1.82.0-amd64.msi"
$msi = "$env:TEMP\ts.msi"
(New-Object Net.WebClient).DownloadFile($url, $msi)
Start-Process msiexec.exe -ArgumentList "/i", "`"$msi`"", "/quiet", "/norestart" -Wait
$ts = "${env:ProgramFiles}\Tailscale\tailscale.exe"
Start-Service tailscale -ErrorAction SilentlyContinue
& $ts up --authkey=$env:TS_KEY --hostname="claw-chat-node" --reset

$rustInstaller = "$env:TEMP\rustup-init.exe"
(New-Object Net.WebClient).DownloadFile("https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe", $rustInstaller)
& $rustInstaller -y --default-toolchain stable
$env:Path += ";$env:USERPROFILE\.cargo\bin"

git clone https://github.com/ultraworkers/claw-code
cd claw-code/rust
cargo build --workspace
$clawBin = "$PSScriptRoot\claw.exe"
Move-Item -Path ".\target\debug\claw.exe" -Destination $clawBin -Force
cd ../..

pip install --no-cache-dir streamlit requests

$appCode = @"
import streamlit as st
import subprocess
import os

st.set_page_config(page_title="CLAW CHAT", layout="wide")
st.markdown("<style>.stApp {background-color: #0a0a0a; color: #00ff00; font-family: 'Courier New', monospace;}</style>", unsafe_allow_html=True)
st.title("📟 CLAW-CODE | LOCAL INTERFACE")

if "messages" not in st.session_state:
    st.session_state.messages = []

for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])

if prompt := st.chat_input("ENTER COMMAND..."):
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.markdown(prompt)

    with st.chat_message("assistant"):
        process = subprocess.run(
            [".\\claw.exe", "prompt", prompt],
            capture_output=True, text=True, env=os.environ
        )
        response = process.stdout if process.returncode == 0 else f"ERROR: {process.stderr}"
        st.markdown(response)
        st.session_state.messages.append({"role": "assistant", "content": response})
"@
Set-Content -Path "app.py" -Value $appCode

$env:STREAMLIT_BROWSER_GATHER_USAGE_STATS = "false"
$env:STREAMLIT_SERVER_HEADLESS = "true"
$env:ANTHROPIC_API_KEY = "$env:ANTHROPIC_API_KEY"

Start-Process streamlit -ArgumentList "run app.py --server.port 8501 --server.address 0.0.0.0" -NoNewWindow
$tsIp = (& $ts ip -4).Trim()

while ($true) {
    Write-Host "CLAW CHAT LIVE: http://$($tsIp):8501"
    Start-Sleep -Seconds 60
}
