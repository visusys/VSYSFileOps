Function Request-AdminRights {
    [CmdletBinding()]
    
    Param(
        [Parameter(Mandatory=$true)]  [string]$CommandLine,
        [Parameter(Mandatory=$false)] [switch]$NoProfile,
        [Parameter(Mandatory=$false)] [switch]$NoExit
    )

    If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        $PSHost = If ($PSVersionTable.PSVersion.Major -le 5) {'PowerShell'} Else {'PwSh'}
        
        # Regex to resolve parameters
        $cmd = ($CommandLine -split '\.ps1[\s\''\"]\s*', 2)[-1]
        Write-Host "Before:    " $cmd

        # Replace double quotes with single quotes 
        # except escaped double quotes I.E: `"
        # $cmd = $cmd -replace '(?<!`)"',''''
        # Replace `" with just "
        # $cmd = $cmd -replace '(`")','"'
        # Write-Host "After:     " $cmd

        $ScriptPath = $MyInvocation.ScriptName

        Start-Process $PSHost -Verb RunAs "
        -NoProfile -NoExit -Command `"
            cd '$pwd';
            & '$ScriptPath' $cmd
        `"
        ";

        #Start-Process -Verb RunAs $PSHost (@(' -NoExit')[!$NoExit] + " -File `"$ScriptPath`" " + $cmd)
        Break
    }
}