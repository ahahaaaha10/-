
$ts = "$env:ProgramFiles\Tailscale\tailscale.exe"
& $ts up --authkey=$env:TS_KEY --hostname="ai-node" --reset
$olExe = "$env:USERPROFILE\ollama\ollama.exe"
$env:OLLAMA_HOST = "127.0.0.1:11434"
Start-Process -FilePath $olExe -ArgumentList "serve" -NoNewWindow

Write-Host "Waiting for Ollama to generate keys and wake up..."
for ($i=0; $i -lt 10; $i++) {
    $check = Test-NetConnection -ComputerName 127.0.0.1 -Port 11434 -ErrorAction SilentlyContinue
    if ($check.TcpTestSucceeded) { 
        Write-Host "Ollama is awake."
        break 
    }
    Start-Sleep -Seconds 5
}

Write-Host "Pulling Unrestricted Model (Dolphin)..."
& $olExe pull dolphin-mistral

$env:STREAMLIT_BROWSER_GATHER_USAGE_STATS = "false"
$env:STREAMLIT_SERVER_HEADLESS = "true"

$appCode = @"
import streamlit as st
import ollama
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

Write-Host "Launching Website..."
Start-Process streamlit -ArgumentList "run app.py --server.port 8501 --server.address 0.0.0.0" -NoNewWindow

Start-Sleep -Seconds 15
$tsIp = (& $ts ip -4)
while ($true) {
    $web = Test-NetConnection -ComputerName localhost -Port 8501 -ErrorAction SilentlyContinue
    if ($web.TcpTestSucceeded) {
        Write-Host "[SUCCESS] Open this: http://$($tsIp):8501"
    } else {
        Write-Host "[RETRYING] Website still loading..."
    }
    Start-Sleep -Seconds 30
}
