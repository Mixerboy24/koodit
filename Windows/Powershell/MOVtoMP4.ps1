$source = Read-Host "Anna kansio (esim. D:/Videot/14082025/)"
$destination = Join-Path $source "MP4"

if (-not (Test-Path $destination)) {
    New-Item -Path $destination -ItemType Directory
}

Get-ChildItem -Path $source -Filter *.MOV | ForEach-Object {
    $inputFile = $_.FullName
    $outputFile = Join-Path $destination ($_.BaseName + ".mp4")
    ffmpeg.exe -i "$inputFile" -c:v libx264 -pix_fmt yuv420p -crf 18 -preset fast -c:a copy "$outputFile"
}

Write-Host "Muunnetut MP4:t löytyvät kansiosta: $destination"
