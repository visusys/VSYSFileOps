function Set-SystemPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [ValidateScript({
            if (!(Test-Path -LiteralPath $_)) {
                throw [System.ArgumentException] "File or Folder does not exist."
            }
            if (Test-Path -LiteralPath $_ -PathType Leaf) {
                throw [System.ArgumentException] "File passed when a folder was expected."
            }
            return $true
        })]
        [String]
        $Path,

        [Parameter(Mandatory = $false)]
        [switch]$Remove,

        [Parameter(Mandatory = $false)]
        [switch]$NoConfirm
    )

    Begin {

        Add-Type -AssemblyName PresentationCore,PresentationFramework
        [System.Windows.Forms.Application]::EnableVisualStyles()

        if(!(Test-IsAdmin)){
            Write-Verbose "This function requires admin privileges. Exiting."
            Exit
        }
    }

    Process {

        if($Path.Contains(';')){
            Write-Verbose "Passed path has a semicolon in its name. Exiting."
            throw [System.Exception] "Invalid path passed. Paths cannot contain a semicolon."
            Exit
        }

        $NewPathList = [System.Collections.Generic.List[object]]@()
        $RegKey = (Get-Item "HKLM:\System\CurrentControlSet\Control\Session Manager\Environment").GetValue("PATH", $null, "DoNotExpandEnvironmentNames")
        $PathList = $RegKey -split ';'
        $PathList = $PathList | Where-Object {$_}

        $Found = $false
        $Path = $Path.TrimEnd('\')
        foreach($P in $PathList) {
            $PTmp = $P.TrimEnd('\')
            if($PTmp -eq $Path){
                $Found = $true
            }else{
                [void]$NewPathList.Add($P)
            }
        }

        if(!$Found -and $Remove){
            Write-Verbose "The path ($P) was not found, nothing to remove."
            if(!$NoConfirm){
                Invoke-GUIMessageBox "The path ($P) was not found, nothing to remove." -Title "Path not found" -Buttons 'OK' -Icon 'Information'
            }
            Exit
        }
        if($Found -and !$Remove){
            Write-Verbose "The path ($P) already exists in System PATH."
            if(!$NoConfirm){
                Invoke-GUIMessageBox "The path ($P) already exists in System PATH." -Title "Path already exists" -Buttons 'OK' -Icon 'Information'
            }
            Exit
        }

        if(!$Found -and !$Remove){
            [void]$NewPathList.Add($Path)
            if($NoConfirm){
                $Result = 'Yes'
            }else{
                Write-Verbose "Invoking confirmation (Add) MessageBox."
                $Result = Invoke-GUIMessageBox "Add $Path to the System PATH environment variable?" -Title "Confirm Addition" -Buttons 'YesNoCancel' -Icon 'Question' -DefaultButton 'Button1'
            }
            if($Result -ne 'Yes') { 
                Write-Verbose "User canceled the process."
                Exit
            }
        }elseif ($Found -and $Remove) {
            if($NoConfirm){
                $Result = 'Yes'
            }else{
                Write-Verbose "Invoking confirmation (Remove) MessageBox."
                $Result = Invoke-GUIMessageBox "Remove $Path from System PATH environment variable?" -Title "Confirm remove" -Buttons 'YesNoCancel' -Icon 'Question' -DefaultButton 'Button1'
            }
            if($Result -ne 'Yes') {
                Write-Verbose "User canceled the process."
                Exit
            }
        }

        if($Remove) {
            Write-Verbose "Removing $Path from the System PATH environment variable."
        }else{
            Write-Verbose "Adding $Path to the System PATH environment variable."
        }
        
        $NewPath = $NewPathList -Join ';'
        [Environment]::SetEnvironmentVariable('path',$NewPath,'Machine')

        if($Remove) {
            Write-Verbose "$Path was successfully removed from the system PATH environment variable."
            if(!$NoConfirm){
                $Result = Invoke-GUIMessageBox "$Path was successfully removed from the system PATH environment variable." -Title 'Success' -Buttons 'OK' -Icon 'Information'
            }
        }else{
            Write-Verbose "$Path was successfully added to the system PATH environment variable."
            if(!$NoConfirm){
                $Result = Invoke-GUIMessageBox "$Path was successfully added to the system PATH environment variable." -Title 'Success' -Buttons 'OK' -Icon 'Information'
            }
        }

        Return
    }

    End {

    }
}