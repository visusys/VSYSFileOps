Function Copy-DirectoryStructureToNewFolder{
    [CmdletBinding()]

    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)] 
        [string]$Path,

        [Parameter(Mandatory=$false)]
        [switch]$Force = $false
    )

    # Test whether the path is exactly a drive letter
    if($Path -match '^[a-zA-Z]:\\$' -or $Path -match '^[a-zA-Z]:$'){
        throw "Path cannot be at the root of a drive. Aborting."
    }

    # Check if the path is valid
    if(-not(Test-Path -Path $Path -PathType Container)){
        throw "Path specified is not an existing directory."
    }

    # Create the destination path format
    $DestinationPath = (Get-Item $Path).FullName + ' Folder Copy'

    # Test that the destination isn't an existing file system item
    while(Test-Path -Path $DestinationPath -PathType Container){
        if($Force) {
            break
        }
        Write-Warning "The destination path already exists."
        $NewFolderName = Read-Host -Prompt "Input the name of the new folder to be created."
        $DestinationPath = (get-item $Path).parent.FullName + '\' + $NewFolderName
    }
    
    # If we've reached this point all validation checks passed, begin copy
    robocopy $Path $DestinationPath /e /xf *.* | Out-Null
}