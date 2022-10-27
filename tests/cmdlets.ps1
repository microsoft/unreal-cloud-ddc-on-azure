function Upload-BenchmarkECR {
    Write-Host "Logging in to AWS ECR"
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 728559092788.dkr.ecr.us-east-1.amazonaws.com

    Write-Host "Starting docker build"
    docker build -t benchmarker .
}

function Upload-BenchmarkS3 {
    $scriptDir = $PSScriptRoot
    $archivePath = (Join-Path $scriptDir "benchmark.zip")
    Write-Host "Creating archive $archivePath"
    Compress-Archive -Path (Join-Path $scriptDir "*.py"),(Join-Path $scriptDir "*.txt"),(Join-Path $scriptDir "*.tar") -DestinationPath $archivePath -Force
}

