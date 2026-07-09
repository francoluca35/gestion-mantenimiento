$rawPath = "D:\Clientes-2026\sika\gestion-mantenimiento\docs\referencias\_manual-raw.txt"
$outDir = "D:\Clientes-2026\sika\gestion-mantenimiento\docs\referencias\sgmwin-manual"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$lines = Get-Content -Path $rawPath -Encoding UTF8

$chapters = @(
	@{ file = "00-indice.md"; title = "Indice"; start = 1; end = 342 },
	@{ file = "01-introduccion.md"; title = "1 - Introduccion"; start = 343; end = 528 },
	@{ file = "02-comenzar-a-trabajar.md"; title = "2 - Comenzar a trabajar"; start = 529; end = 623 },
	@{ file = "03-archivos-maestros.md"; title = "3 - Archivos maestros"; start = 624; end = 2124 },
	@{ file = "04-administracion-trabajos.md"; title = "4 - Administracion de trabajos"; start = 2125; end = 3164 },
	@{ file = "05-analisis-trabajos.md"; title = "5 - Analisis de la informacion de los trabajos"; start = 3165; end = 3614 },
	@{ file = "06-administracion-stock.md"; title = "6 - Administracion del stock"; start = 3615; end = 4174 },
	@{ file = "07-analisis-stock.md"; title = "7 - Analisis de la informacion de stock"; start = 4175; end = 4429 },
	@{ file = "08-configuracion.md"; title = "8 - Configuracion"; start = 4430; end = 4834 },
	@{ file = "09-anexo-1-report-pro.md"; title = "9 - Anexo 1: REPORT PRO"; start = 4835; end = 4870 },
	@{ file = "10-anexo-2-planos.md"; title = "10 - Anexo 2: Planos"; start = 4871; end = 4877 },
	@{ file = "11-anexo-3-graficas.md"; title = "11 - Anexo 3: Graficas"; start = 4878; end = 4936 },
	@{ file = "12-anexo-4-edicion-texto.md"; title = "12 - Anexo 4: Edicion rapida de texto"; start = 4937; end = $lines.Count }
)

function Remove-DuplicatedHalf([string]$line) {
	if ($line.Length -lt 8) { return $line }
	$half = [math]::Floor($line.Length / 2)
	$left = $line.Substring(0, $half)
	$right = $line.Substring($half)
	if ($left -eq $right) { return $left.Trim() }
	return $line
}

function Normalize-Line([string]$line) {
	$line = $line.Trim()
	if ([string]::IsNullOrWhiteSpace($line)) { return $null }

	$line = Remove-DuplicatedHalf $line

	if ($line -match '^(S U G E R E N C I A|N O T A|A V I S O|I M P O R T A N T E|S O L I C I T U D)$') { return $null }

	$line = $line -replace '(S U G E R E N C I A|N O T A|A V I S O|I M P O R T A N T E).*$', ''
	$line = $line.Trim()
	if ([string]::IsNullOrWhiteSpace($line)) { return $null }

	return $line
}

function Is-SectionTitle([string]$line) {
	if ($line.Length -lt 4 -or $line.Length -gt 90) { return $false }
	if ($line -match '^Figura ') { return $false }
	if ($line -match '^[A-Z0-9][A-Z0-9 \.\-\(\)]+$' -and $line.Length -ge 6) { return $true }
	if ($line -match '^[0-9]+\.' ) { return $true }
	if ($line -cmatch '^[A-Z][a-z]' -and $line -notmatch '\.$') { return $true }
	return $false
}

function Format-Content([string[]]$chunk) {
	$result = New-Object System.Collections.Generic.List[string]
	$prev = $null
	$prevSection = $null

	foreach ($raw in $chunk) {
		$line = Normalize-Line $raw
		if ($null -eq $line) { continue }
		if ($line -eq $prev) { continue }

		if ($line.StartsWith("### ")) {
			$heading = $line.Substring(4).Trim()
			$heading = Remove-DuplicatedHalf $heading
			if ($heading -match '^Figura') {
				$result.Add("")
				$result.Add("> **$heading**")
			} elseif ($heading -match '^En Es') {
				# saltar artefactos de indice interno
			} else {
				$result.Add("")
				$result.Add("### $heading")
			}
			$prev = $line
			continue
		}

		if (Is-SectionTitle $line) {
			if ($line -ne $prevSection) {
				$result.Add("")
				$result.Add("## $line")
				$prevSection = $line
			}
			$prev = $line
			continue
		}

		$result.Add($line)
		$prev = $line
	}

	return @($result.ToArray())
}

foreach ($ch in $chapters) {
	$chunk = $lines[($ch.start - 1)..($ch.end - 1)]
	$body = Format-Content $chunk
	$header = @(
		"# $($ch.title)",
		"",
		"> Fuente: MANUAL SGMWIN3.docx - L&M Ingenieria S.R.L.",
		"> Extraido automaticamente. Las referencias a figuras (Figura X) corresponden al manual original impreso.",
		""
	)
	$md = ($header + $body) -join "`n"
	$path = Join-Path $outDir $ch.file
	[System.IO.File]::WriteAllText($path, $md, [System.Text.UTF8Encoding]::new($true))
	Write-Host "Wrote $($ch.file) ($($body.Length) lines)"
}

Write-Host "Done -> $outDir"
