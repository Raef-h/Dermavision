$litertVersion = "2.1.4"
$currentDir = Get-Location
$jniLibsBase = "$currentDir\android\app\src\main\jniLibs"
$abis = @("arm64-v8a", "armeabi-v7a", "x86_64")

# Download LiteRT AAR (Successor to TFLite)
$aarUrl = "https://maven.google.com/com/google/ai/edge/litert/litert/$litertVersion/litert-$litertVersion.aar"
$aarPath = "$env:TEMP\litert.aar"

Write-Host "Downloading LiteRT AAR ($litertVersion)..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $aarUrl -OutFile $aarPath -UseBasicParsing
Write-Host "Download complete. Extracting .so files..." -ForegroundColor Cyan

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($aarPath)

foreach ($abi in $abis) {
    $jniEntries = $zip.Entries | Where-Object { $_.FullName -like "jni/$abi/*.so" }
    foreach ($entry in $jniEntries) {
        $outDir = "$jniLibsBase\$abi"
        if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
        $fileName = [System.IO.Path]::GetFileName($entry.FullName)
        $outFile = "$outDir\$fileName"
        
        $stream = $entry.Open()
        $fs = [System.IO.File]::Create($outFile)
        $stream.CopyTo($fs)
        $fs.Close()
        $stream.Close()
        Write-Host "  [OK] $abi/$fileName" -ForegroundColor Green
        
        # KEY: tflite_flutter 0.11.0 specifically looks for libtensorflowlite_jni.so.
        # Since LiteRT is the new TFLite, libLiteRt.so contains the updated runtime.
        if ($fileName -eq "libLiteRt.so") {
             Copy-Item $outFile "$outDir\libtensorflowlite_jni.so" -Force
             Write-Host "  [FORCE ALIAS] Created libtensorflowlite_jni.so from libLiteRt.so" -ForegroundColor Yellow
        }
    }
}

$zip.Dispose()
Remove-Item $aarPath

Write-Host "Done. Modern libraries installed with compatibility alias." -ForegroundColor Green
