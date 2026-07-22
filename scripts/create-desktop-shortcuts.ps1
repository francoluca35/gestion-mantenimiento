# Crea accesos directos en el Escritorio.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$desktop = [Environment]::GetFolderPath("Desktop")
$shell = New-Object -ComObject WScript.Shell
$icon = "$env:SystemRoot\System32\shell32.dll"

function New-AppShortcut(
	[string]$name,
	[string]$target,
	[string]$description,
	[int]$iconIndex
) {
	$linkPath = Join-Path $desktop "$name.lnk"
	$shortcut = $shell.CreateShortcut($linkPath)
	$shortcut.TargetPath = Join-Path $root $target
	$shortcut.WorkingDirectory = $root
	$shortcut.Description = $description
	$shortcut.IconLocation = "$icon,$iconIndex"
	$shortcut.WindowStyle = 1
	$shortcut.Save()
	Write-Host "Creado: $linkPath" -ForegroundColor Green
}

New-AppShortcut `
	-name "Iniciar Gestión Mantenimiento" `
	-target "INICIAR-GESTION.cmd" `
	-description "Levanta Docker, API, web, base de datos y backups" `
	-iconIndex 137

New-AppShortcut `
	-name "Estado Gestión Mantenimiento" `
	-target "ESTADO-GESTION.cmd" `
	-description "Muestra el estado del servidor" `
	-iconIndex 167

New-AppShortcut `
	-name "Detener Gestión Mantenimiento" `
	-target "DETENER-GESTION.cmd" `
	-description "Detiene el stack Docker de Gestión" `
	-iconIndex 131
