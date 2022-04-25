function Move-ExtensionToFolder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [ValidateScript({
            if (!(Test-Path -LiteralPath $_)) {
                throw [System.ArgumentException] "File or Folder does not exist."
            }
            if (Test-Path -LiteralPath $_ -PathType Container) {
                throw [System.ArgumentException] "Folder passed when a file was expected."
            }
            return $true
        })]
        [String[]]
        $Files,

        [Parameter(Mandatory=$false)]
        [Switch]
        $ToUpper
    )

    Process {
        foreach ($File in $Files) {
            $NewFolder = ([System.IO.Path]::GetExtension($File)).Replace('.','')
            if($ToUpper){$NewFolder = $NewFolder.ToUpper()}
            $NewFolder = ([System.IO.Path]::GetDirectoryName($File)) + '\' + $NewFolder
            if(!(Test-Path -LiteralPath $NewFolder -PathType Container)){
                New-Item $NewFolder -ItemType Directory -Force
            }
            Move-Item $File -Destination $NewFolder -Force
        }
        
        # This is ugly. Very ugly. But it does the job!
        # I'm sending the refresh command every 20ms
        # just to make sure it's captured.
        $wshell = New-Object -ComObject wscript.shell
        $wshell.SendKeys("{F5}")
        Start-Sleep -Milliseconds 20
        $wshell.SendKeys("{F5}")
        Start-Sleep -Milliseconds 20
        $wshell.SendKeys("{F5}")
        Start-Sleep -Milliseconds 20
        $wshell.SendKeys("{F5}")
        Start-Sleep -Milliseconds 20
        $wshell.SendKeys("{F5}")
    }
}