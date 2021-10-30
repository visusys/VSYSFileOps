
Function Add-SelectedFilesToNewFolder{
    [CmdletBinding()]
    
    Param(
        [Parameter(Mandatory=$true)]  [string[]]$files,
        [Parameter(Mandatory=$false)] [string]$foldername='New Folder',
        [Parameter(Mandatory=$false)] [switch]$prompt
    )

    # Determine if all files actually exist
    foreach ($file in $files) {
        if(!(Test-Path -Path $file -PathType Leaf)){
            throw "One or more files given does not exist."
        }
    }

    # Determine all files reside in the same directory
    $dirtest  = $null
    $filetest = $null
    foreach ($file in $files) {

        $dirname = [System.IO.Path]::GetDirectoryName($file)
        Write-Verbose "Directory name: $dirname" 

        if (!$dirtest) {
            $dirtest = [System.IO.Path]::GetDirectoryName($file)
            Write-Verbose "Init: Setting `$dirtest to $dirtest"
        }else {
            #Make sure all files are in the same directory
            $filetest = [System.IO.Path]::GetDirectoryName($file)
            if ($dirtest -ne $filetest) {
                throw "Some of the files passed are not in the same directory."
                Exit
            }
        }
    }
    Write-Verbose "All files share the same directory."

    #Test if the final directory already exists
    $folderexists = $false
    $finaldir = $dirtest + '\' + $foldername
    if (Test-Path -Path $finaldir) {
        $folderexists = $true
        Write-Warning "Destination directory already exists!"
        if($prompt){
            $decision = $Host.UI.PromptForChoice('','Are you sure you want to proceed?', @('&Yes'; '&No'), 1)
            if($decision -eq 1){
                Return
            }
        }
    } else {
        Write-Verbose "Path doesn't exist. Continuing."
    }

    Write-Verbose "Final Directory: $finaldir"

    #Create the new directory if it doesn't exist
    $fso = new-object -com "Scripting.FileSystemObject"
    if($folderexists -ne $true){
        $fso.CreateFolder($finaldir) | Out-Null
    }
    #Move the files to the new directory
    foreach ($file in $files) {
        Write-Verbose "`$file: $file"
        Write-Verbose "`$finaldir: $finaldir"
        $fso.MoveFile($file, $finaldir + '\')
    }
}