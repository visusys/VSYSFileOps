
# Original Script Created by mklement0 on StackOverflow
#

function Request-AdminRights {

    [CmdletBinding()]
    param(
        [switch]$NoExit
    )
    
    $isWin = $env:OS -eq 'Windows_NT'
    
    # Simply return, if already elevated.
    if (($isWin -and (net.exe session 2>$null)) -or (-not $isWin -and 0 -eq (id -u))) { 
        Write-Verbose "(Now) running as $(("superuser", "admin")[$isWin])."
        return 
    }
    
    # Get the relevant variable values from the calling script's scope.
    $scriptPath             = $PSCmdlet.GetVariableValue('PSCommandPath')
    $scriptBoundParameters  = $PSCmdlet.GetVariableValue('PSBoundParameters')
    $scriptArgs             = $PSCmdlet.GetVariableValue('args')
    
    Write-Verbose ("This script, `"$scriptPath`", requires " + ("superuser privileges, ", "admin privileges, ")[$isWin] + ("re-invoking with sudo...", "re-invoking in a new window with elevation...")[$isWin])
    
    # Note: 
    #   * On Windows, the script invariably runs in a *new window*, and by design we let it run asynchronously, in a stay-open session.
    #   * On Unix, sudo runs in the *same window, synchronously*, and we return to the calling shell when the script exits.
    #   * -inputFormat xml -outputFormat xml are NOT used:
    #      * The use of -encodedArguments *implies* CLIXML serialization of the arguments; -inputFormat xml presumably only relates to *stdin* input.
    #      * On Unix, the CLIXML output created by -ouputFormat xml is not recognized by the calling PowerShell instance and passed through as text.
    #   * On Windows, the elevated session's working dir. is set to the same as the caller's (happens by default on Unix, and also in PS Core on Windows - but not in *WinPS*)
        
    # Determine the full path of the PowerShell executable running this session.
    # Note: The (obsolescent) ISE doesn't support the same CLI parameters as powershell.exe, so we use the latter.
    $psExe = (Get-Process -Id $PID).Path -replace '_ise(?=\.exe$)'
    
    if (0 -ne ($scriptBoundParameters.Count + $scriptArgs.Count)) {
        # ARGUMENTS WERE PASSED, so the CLI must be called with -encodedCommand and -encodedArguments, for robustness.
    
        # !! To work around a bug in the deserialization of [switch] instances, replace them with Boolean values.
        foreach ($key in @($scriptBoundParameters.Keys)) {
            if (($val = $scriptBoundParameters[$key]) -is [switch]) { $null = $scriptBoundParameters.Remove($key); $null = $scriptBoundParameters.Add($key, $val.IsPresent) }
        }
        # Note: If the enclosing script is non-advanced, *both* 
        #       !! Be sure to pass @() when $args is $null (advanced script), otherwise a scalar $null will be passed on reinvocation.
        #       Use the same serialization depth as the remoting infrastructure (1).
        $serializedArgs = [System.Management.Automation.PSSerializer]::Serialize(($scriptBoundParameters, (@(), $scriptArgs)[$null -ne $scriptArgs]), 1)
    
        if($NoExit) {
            $NoExitString = '-noexit '
        }else {
            $NoExitString = ''
        }
        # The command that receives the (deserialized) arguments.
        # Note: Since the new window running the elevated session must remain open, we do *not* append `exit $LASTEXITCODE`, unlike on Unix.
        $cmd = 'param($bound, $positional) Set-Location "{0}"; & "{1}" @bound @positional' -f (Get-Location -PSProvider FileSystem).ProviderPath, $scriptPath
        if ($isWin) {
            Start-Process -Verb RunAs $psExe ($NoExitString+'-encodedCommand {0} -encodedArguments {1}' -f [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd)), [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($serializedArgs)))
            #Start-Process -Verb RunAs $psExe ('-noexit -encodedCommand {0} -encodedArguments {1}' -f [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd)), [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($serializedArgs)))
        } else {
            sudo $psExe -encodedCommand ([Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))) -encodedArguments ([Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($serializedArgs)))
        }
    
    } else {
        # NO ARGUMENTS were passed - simple reinvocation of the script with -c (-Command) is sufficient.
        # Note: While -f (-File) would normally be sufficient, it leaves $args undefined, which could cause the calling script to break.
        # Also, on WinPS we must set the working dir.
    
        if ($isWin) {
            Start-Process -Verb RunAs $psExe ($NoExitString+'-c Set-Location "{0}"; & "{1}"' -f (Get-Location -PSProvider FileSystem).ProviderPath, $scriptPath)
        } else {
            # Note: On Unix, the working directory is always automatically inherited.
            sudo $psExe -c "& `"$scriptPath`"; exit $LASTEXITCODE"
        }
    
    }
    
    # EXIT after reinvocation, passing the exit code through, if possible:
    # On Windows, since Start-Process was invoked asynchronously, all we can report is whether *it* failed on invocation.
    exit ($LASTEXITCODE, (1, 0)[$?])[$isWin]

}