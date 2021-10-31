
# TODO: Convert and clean

function Test-IsSensitivePath {
	[CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]  [string]$Path
    )

    if(!(Test-Path $Path -IsValid)){
        throw "A valid path has not been passed"
    }
    
    if($Path -eq "" -or $Path -eq " " -or $Path -eq $null){
        throw "Invalid path passed."
    }

    $OSDrive = $((Get-WmiObject Win32_OperatingSystem).SystemDrive)

    $UnsafeDirectories = @(
        $($OSDrive + '\Windows'),
        $($OSDrive + '\Users'),
        $($OSDrive + '\Users\' + $env:UserName),
        $($OSDrive + '\Users\' + $env:UserName + '\AppData'),
        $($OSDrive + '\Users\' + $env:UserName + '\AppData\LocalLow'),
        $($OSDrive + '\Users\' + $env:UserName + '\AppData\Roaming'),
        $($OSDrive + '\ProgramData'),
        $($OSDrive + '\Program Files (x86)'),
        $($OSDrive + '\Program Files'),
        $($OSDrive + '\$WinREAgent')
    )
    $UnsafeDirectoriesRecurse = @(
        ($OSDrive + '\Windows\'),
        ($OSDrive + '\$WinREAgent\')
    )
    $UnsafeDirectoriesAnyDrive = @(
        'System Volume Information',
        '$RECYCLE.BIN'
    )

    #Initialize IsSensitive
    $IsSensitive = $false

    #Test for unsafe directories IE C:\Windows
    foreach ( $dir in $UnsafeDirectories ){
        if($Path -eq $dir -or $Path -eq $($dir + '\')){
            $IsSensitive = $true
            Write-Warning "$Path is a sensitive path!"
            exit
        }
    }
    # Test for unsafe directories within specific unsafe directories
    # IE: C:\Windows\System32
    if ($IsSensitive -eq $false){
        foreach ($dir in $UnsafeDirectoriesRecurse){
            if($Path -like "$dir*"){
                $IsSensitive = $true
                Write-Warning "$Path is within a sensitive path!"
                break
            }
        }
    }
    # Test for unsafe directories on all drives
    # IE: D:\System Volume Information
    if ($IsSensitive -eq $false){
        foreach ( $dir in $UnsafeDirectoriesAnyDrive ){
            $str = [Regex]::Escape($dir)
            if($Path -match '^[a-zA-Z]:\\' + $str){
                $IsSensitive = $true
                Write-Warning "$Path is within a sensitive path! `$UnsafeDirectoriesAnyDrive"
                break
            }
        }
    }

    # Test whether the path is exactly a drive letter
    if($Path -match '^[a-zA-Z]:\\$' -or $Path -match '^[a-zA-Z]:$'){
        $IsSensitive = $true
        Write-Warning "$Path is a drive letter!"
    }
    
    #If we made it this far, path isn't sensitive
    if($IsSensitive -eq $false){
        Write-Verbose "$Path is not a sensitive path."
    }

    $IsSensitive
}
function New-TempDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    $name = [System.IO.Path]::GetRandomFileName()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}

function Copy-DirectoryAndFlatten ($SourceDir,$DestinationDir)
{
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

if($args.Length -eq 0){
	throw "No directory passed."
}

if($args[0] -eq "" -or $args[0] -eq " "){
	throw "Passed an empty directory."
}

if(Test-Path -Path $args[0]){
	Write-Verbose "Path is valid. Continuing."
}else {
	throw "Passed path is not valid."
}

$SourceDirectoryPath=$args[0]

$IsSensitivePath = Test-IsSensitivePath $SourceDirectoryPath
if($IsSensitivePath -eq $true){
	throw "Passed path is within a sensitive OS folder."
}else{
	Write-Verbose "Passed path is not sensitive."
}

#Read-Host -Prompt "You are about to flatten '$SourceDirectoryPath' Press any key to proceed."

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