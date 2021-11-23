function Copy-DirectoryAndFlatten ($SourceDir, $DestinationDir) {
	
	Get-ChildItem $SourceDir -Recurse | Where-Object { $_.PSIsContainer -eq $false } | ForEach-Object ($_) {
		$SourceFile = $_.FullName
		$DestinationFile = $DestinationDir + $_
		
        if (Test-Path $DestinationFile) {
			$i = 0
            # While $DestinationFile exists, increment the file name until it doesn't
			while (Test-Path $DestinationFile) {
				$i += 1
				$x = $i + 1
				$x = ([string]$x).PadLeft(2,'0')
				$DestinationFile = $DestinationDir + $_.basename + '_' + $x + $_.extension
			}
            # HERE is where it jumps to the second Copy-Item statement
		} else {
			Copy-Item -Path $SourceFile -Destination $DestinationFile -Force
		}
		Copy-Item -Path $SourceFile -Destination $DestinationFile -Force
	}
}


$SourceDirectoryParentPath = (get-item $SourceDirectoryPath).parent.FullName

# Create a new temporary directory
$TempDirectory     = New-TempDirectory
$TempDirectoryPath = $TempDirectory.FullName + '\'

# Copy everything from the source directory to the temporary directory
Copy-DirectoryAndFlatten -SourceDir $SourceDirectoryPath -DestinationDir $TempDirectoryPath

# Move the temporary directory to the same directory as the supplied path
Move-Item -Path $TempDirectory -Destination $SourceDirectoryParentPath

$NewTempDirectory = $SourceDirectoryParentPath + '\' + $TempDirectory.Name

Remove-Item $SourceDirectoryPath -Recurse
Rename-Item $NewTempDirectory $SourceDirectoryPath