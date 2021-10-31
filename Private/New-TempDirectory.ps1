function New-TempDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    $name = [System.IO.Path]::GetRandomFileName()
    return (New-Item -ItemType Directory -Path (Join-Path $parent $name))
}