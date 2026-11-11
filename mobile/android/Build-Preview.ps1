param(
    [Parameter(Mandatory)] [string] $PlatformJar,
    [Parameter(Mandatory)] [string] $BuildTools,
    [Parameter(Mandatory)] [string] $KeyStore,
    [Parameter(Mandatory)] [string] $OutputDirectory
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-BuildTool {
    param([string] $Tool, [string[]] $Arguments)
    & $Tool @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Failed: $Tool ($LASTEXITCODE)" }
}

$PlatformJar = (Resolve-Path -LiteralPath $PlatformJar).Path
$BuildTools = (Resolve-Path -LiteralPath $BuildTools).Path
$KeyStore = (Resolve-Path -LiteralPath $KeyStore).Path
if (-not $env:SAI_PREVIEW_KEY_PASSWORD) { throw 'Set SAI_PREVIEW_KEY_PASSWORD for this build session.' }

$output = New-Item -ItemType Directory -Force $OutputDirectory
$apk = Join-Path $output.FullName 'SAI-Browser-Android-0.1.0-preview.1.apk'
if (Test-Path -LiteralPath $apk) { throw "Output exists: $apk" }

$scratch = Join-Path ([IO.Path]::GetTempPath()) ('sai-preview-' + [guid]::NewGuid())
New-Item -ItemType Directory "$scratch/classes", "$scratch/checks", "$scratch/res/drawable" | Out-Null
try {
    Copy-Item -LiteralPath "$PSScriptRoot/../../assets/sai-browser.png" -Destination "$scratch/res/drawable/sai_browser.png"
    $sources = (Get-ChildItem -LiteralPath "$PSScriptRoot/src" -Filter '*.java').FullName
    Invoke-BuildTool javac @('--release', '8', '-encoding', 'UTF-8', '-d', "$scratch/checks",
        "$PSScriptRoot/src/WebAddress.java", "$PSScriptRoot/AddressCheck.java")
    Invoke-BuildTool java @('-cp', "$scratch/checks", 'org.ysai.saibrowser.preview.AddressCheck')
    Invoke-BuildTool javac (@('--release', '8', '-encoding', 'UTF-8', '-cp', $PlatformJar, '-d', "$scratch/classes" ) + $sources)
    $classFiles = (Get-ChildItem -LiteralPath "$scratch/classes" -Recurse -Filter '*.class').FullName
    Invoke-BuildTool "$BuildTools/d8.bat" (@('--lib', $PlatformJar, '--min-api', '28', '--output', $scratch) + $classFiles)
    Invoke-BuildTool "$BuildTools/aapt2.exe" @('compile', '--dir', "$scratch/res", '-o', "$scratch/res.zip")
    Invoke-BuildTool "$BuildTools/aapt2.exe" @('link', '-I', $PlatformJar, '--manifest',
        "$PSScriptRoot/AndroidManifest.xml", '-o', "$scratch/unsigned.apk", "$scratch/res.zip")

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::Open("$scratch/unsigned.apk", [IO.Compression.ZipArchiveMode]::Update)
    try {
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, "$scratch/classes.dex", 'classes.dex') | Out-Null
    } finally {
        $archive.Dispose()
    }
    Invoke-BuildTool "$BuildTools/zipalign.exe" @('-f', '4', "$scratch/unsigned.apk", "$scratch/aligned.apk")
    Invoke-BuildTool "$BuildTools/apksigner.bat" @('sign', '--ks', $KeyStore, '--ks-key-alias', 'sai-preview',
        '--ks-pass', 'env:SAI_PREVIEW_KEY_PASSWORD', '--v4-signing-enabled', 'false',
        '--out', "$scratch/signed.apk", "$scratch/aligned.apk")
    Invoke-BuildTool "$BuildTools/apksigner.bat" @('verify', '--verbose', '--print-certs', "$scratch/signed.apk")
    Invoke-BuildTool "$BuildTools/zipalign.exe" @('-c', '4', "$scratch/signed.apk")
    Copy-Item -LiteralPath "$scratch/signed.apk" -Destination $apk
    $hash = (Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash.ToLowerInvariant()
    Set-Content -LiteralPath "$apk.sha256" -Value "$hash  $([IO.Path]::GetFileName($apk))" -Encoding ascii
    Get-Item -LiteralPath $apk
} finally {
    $resolved = (Resolve-Path -LiteralPath $scratch).Path
    if ($resolved -eq $scratch -and (Split-Path $resolved -Leaf) -match '^sai-preview-[0-9a-f-]{36}$') {
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
