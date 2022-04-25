<#
.SYNOPSIS
    Detects if a file is locked or not.

.DESCRIPTION
    Some file actions need exclusive access by the calling process, so 
    Windows will lock access to a file. 
    
    This Function can detect if a file is locked or not.

    Returns $True if the file is locked (If PassThru is not specefied).
    Returns $False if the file is not locked.

    If PassThru is specefied:
    Returns a Management.Automation.ErrorRecord Object if the file is locked. 
    Returns $null if the file is not locked.

    WARNING: The file could become locked the very next millisecond 
    by any other process after this function has been run. 
    Make sure this is taken into account.

.PARAMETER FilePath
    Path of the file being tested.

.PARAMETER PassThru
    If set to true:
    Returns a Management.Automation.ErrorRecord Object if the file is locked. 
    Returns $null if the file is not locked.

.EXAMPLE
    PS> Test-FileIsLocked -FilePath "C:\Documents\FileThatIsntLocked.log"
    $false

.EXAMPLE
    PS> Test-FileIsLocked -FilePath "C:\Documents\FileThatIsntLocked.log" -PassThru
    $null

.EXAMPLE
    PS> Test-FileIsLocked -FilePath "C:\Documents\LockedFile.log" -PassThru
    Management.Automation.ErrorRecord

.EXAMPLE
    PS> Test-FileIsLocked -FilePath "C:\Documents\LockedFile.log"
    $true

.INPUTS
    System.String - The path of the file being tested.

.OUTPUTS
    No PassThru:
    $true if file is locked.
    $false if file is not locked.

    PassThru:
    Management.Automation.ErrorRecord if file is locked.
    $null if file is not locked.

.NOTES
    Name: Test-FileIsLocked
    Author: Visusys
    Release: 1.0.0
    License: MIT License
    DateCreated: 2022-04-15

.LINK
    https://github.com/visusys
    
#>
Function Test-FileIsLocked {
    param (
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelinebyPropertyName)]
        [String[]]
        $Path,

        [Parameter(Mandatory=$false,ValueFromPipelinebyPropertyName)]
        [Switch]
        $PassThru
    )

    process {

        If(Test-Path -LiteralPath $Path) { $FileInfo = Get-Item -LiteralPath $Path } Else { Return $False }
    
        try {
            $Stream = $FileInfo.Open([System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::None)
        } catch [System.IO.IOException] {

            # The file is not available because it is being written to 
            # or being processed by another thread or does not exist.

            If($PassThru.IsPresent) {	

                Write-Verbose "IO Exception: $($_.Exception.Message)"

                $exception     = $_.Exception
                $errorID       = 'FileIsLocked'
                $errorCategory = [Management.Automation.ErrorCategory]::OpenError
                $target        = $Path
                $errorRecord   = New-Object Management.Automation.ErrorRecord $exception, $errorID, $errorCategory, $target
                return $errorRecord
            } else {
                return $true
            }
        }
        finally {
            if ($stream){
                $stream.Close()
            }
        }
        # File is not locked.
        If($PassThru.IsPresent) {
            return $Null
        } Else {
            $False
        }
    }
}