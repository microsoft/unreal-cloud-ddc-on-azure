function Upload-BenchmarkECR {
    Write-Host "Starting docker build"
    docker build -t benchmarker .
}

function Upload-BenchmarkS3 {
    $scriptDir = $PSScriptRoot
    $archivePath = (Join-Path $scriptDir "benchmark.zip")
    Write-Host "Creating archive $archivePath"
    Compress-Archive -Path (Join-Path $scriptDir "*.py"),(Join-Path $scriptDir "*.txt"),(Join-Path $scriptDir "*.tar") -DestinationPath $archivePath -Force
}

