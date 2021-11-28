
Function Copy-SelectedFilesToNewFolder {

    [CmdletBinding()]

    Param (
        [parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [ValidateScript({
            if(!(Test-Path -LiteralPath $_)){
                throw "File or folder does not exist"
            }
            return $true
        })]
        [String[]]
        $File,

        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [string]$NewFolderName = "New Folder"
    )

    Begin {
        $FileList = [System.Collections.Generic.List[object]]@()
        $FolderList = [System.Collections.Generic.List[object]]@()
    }

    Process {
        foreach($curFile in ($File | Where-Object {$_})) {
            if(Test-Path -LiteralPath $curFile -PathType Leaf) {
                $WorkingFile = Convert-Path -LiteralPath $curFile
                $WorkingFile = $WorkingFile.TrimEnd('\')
                $FileList.Add($WorkingFile)
                $FolderList.Add([System.IO.Path]::GetDirectoryName($WorkingFile))
            }
        }
        if(!(Test-ObjectContentsAreIdentical $FolderList)){
            throw "Not all objects are in the same directory. Aborting."
        }

        $FinalDirectory = [IO.Path]::Combine($FolderList[0], $NewFolderName) + "\" 
        Write-Host "`$FinalDirectory: $FinalDirectory"
        #$FinalDirectory = $FolderList[0] + "\" + $NewFolderName + "\"
        
        $fso = new-object -com "Scripting.FileSystemObject"
        if(!(Test-Path $FinalDirectory -PathType Container)){
            $fso.CreateFolder($FinalDirectory) | Out-Null
        }
        foreach ($F in $FileList) {
            $fso.MoveFile($F, $FinalDirectory)
        }
    }
}

#Copy-SelectedFilesToNewFolder "C:\Users\futur\Desktop\Testing\Test\04175_thecitythatneversleeps_2560x1440.jpg"
