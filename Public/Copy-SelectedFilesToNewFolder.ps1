
Function Copy-SelectedFilesToNewFolder {

    [cmdletbinding()]

    Param (
        [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [ValidateScript({
            if(-Not (Test-Path -LiteralPath $_)){
                throw "File or folder does not exist"
            }
            return $true
        })]
        [String[]]$File,

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

        $FinalDirectory = $FolderList[0] + "\" + $NewFolderName + "\"
        
        $fso = new-object -com "Scripting.FileSystemObject"
        if(!(Test-Path $FinalDirectory -PathType Container)){
            $fso.CreateFolder($FinalDirectory) | Out-Null
        }

        $ReturnData = [System.Collections.Generic.List[object]]@()

        foreach ($F in $FileList) {
            $fso.MoveFile($F, $FinalDirectory)
            $ReturnData.Add([System.Uri]$F)
        }
    }
    End {
        return $ReturnData
    }
}