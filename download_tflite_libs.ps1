$tfliteVersion = "2.11.0"
$jniLibsBase = "c:\Users\Admin\Desktop\flutter\Dermavision - Copy\android\app\src\main\jniLibs"
$abis = @("arm64-v8a", "armeabi-v7a", "x86_64")

# Download GPU AAR
$gpuAarUrl = "https://repo1.maven.org/maven2/org/tensorflow/tensorflow-lite-gpu/$tfliteVersion/tensorflow-lite-gpu-$tfliteVersion.aar"
$aarPath = "$env:TEMP\tflite_gpu.aar"

Write-Host "Downloading TFLite GPU AAR ($tfliteVersion)..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $gpuAarUrl -OutFile $aarPath -UseBasicParsing
Write-Host "Download complete. Extracting GPU .so files..." -ForegroundColor Cyan

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($aarPath)

Write-Host "GPU AAR jni entries:" -ForegroundColor Yellow
$zip.Entries | Where-Object { $_.FullName -like "jni/*" } | ForEach-Object { Write-Host "  $($_.FullName)" }

foreach ($abi in $abis) {
    $jniEntries = $zip.Entries | Where-Object { $_.FullName -like "jni/$abi/*.so" }
    foreach ($entry in $jniEntries) {
        $outDir = "$jniLibsBase\$abi"
        New-Item -ItemType Directory -Force -Path $outDir | Out-Null
        $fileName = [System.IO.Path]::GetFileName($entry.FullName)
        $outFile = "$outDir\$fileName"
        $stream = $entry.Open()
        $fs = [System.IO.File]::Create($outFile)
        $stream.CopyTo($fs)
        $fs.Close()
        $stream.Close()
        Write-Host "  [OK] $abi/$fileName" -ForegroundColor Green
    }
}

$zip.Dispose()
Remove-Item $aarPath
Write-Host "Done." -ForegroundColor Green
