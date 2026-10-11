param(
    [string]$DocumentPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'docs\Informe_Laboratorio_4_UNSA_LAB.docx'),
    [string]$PreviewPath = (Join-Path (Split-Path -Parent $PSScriptRoot) '.dart_tool\Informe_Laboratorio_4_UNSA_LAB_revision.pdf')
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $DocumentPath)) { throw 'No se encuentra el informe DOCX' }
if (-not (Test-Path -LiteralPath (Split-Path -Parent $PreviewPath))) { throw 'No se encuentra la carpeta de revisión' }
$word = $null
$document = $null
try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0
    $document = $word.Documents.Open($DocumentPath, $false, $false, $false)
    $document.Repaginate()
    $pages = $document.ComputeStatistics(2)
    $document.Fields.Update() | Out-Null
    foreach ($section in $document.Sections) {
        foreach ($header in $section.Headers) { $header.Range.Fields.Update() | Out-Null }
        foreach ($footer in $section.Footers) {
            $footer.Range.Fields.Update() | Out-Null
            foreach ($field in $footer.Range.Fields) {
                if ($field.Code.Text -match 'NUMPAGES') { $field.Result.Text = [string]$pages }
            }
        }
    }
    $document.Repaginate()
    $pages = $document.ComputeStatistics(2)
    $document.Save()
    $document.ExportAsFixedFormat($PreviewPath, 17)
    [pscustomobject]@{ Documento = $DocumentPath; Paginas = $pages; Revision = $PreviewPath }
} finally {
    if ($document) { $document.Close($false) }
    if ($word) { $word.Quit() }
    if ($document) { [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($document) }
    if ($word) { [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}
