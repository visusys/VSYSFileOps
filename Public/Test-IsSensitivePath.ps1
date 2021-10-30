function Test-IsSensitivePath {
	[CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]  [string]$Path
    )

    if(!(Test-Path $Path -IsValid)){
        throw [System.ArgumentException]"Invalid path passed. Likely specified incorrect drive letter."
    }

    if(($Path -eq "") -or ($Path -eq " ") -or ($Path -eq $null)){
        throw [System.ArgumentException]"Invalid path passed. (Empty string or null)"
    }

    if ([System.IO.Path]::IsPathRooted($Path)) {
        # this will throw an exception if the path can't be used
        # for example Z:\whatever is accepted, ZZ:\whatever is not
        # $validatedPath = ([System.IO.DirectoryInfo]$path).FullName
    } else {
        throw [System.ArgumentException]"Only fully-qualified paths are accepted."
    }

    $OSDrive = $((Get-WmiObject Win32_OperatingSystem).SystemDrive)
    if(($OSDrive -eq "") -or ($OSDrive -eq " ") -or ($OSDrive -eq $null)){
        throw "Could not determine the system drive."
    }

    ################### TODO #####################
    # Include \\ or / or // as path separators
    # Convert intelligently to single backslashes
    # and then continue to below.


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
        if(($Path -eq $dir) -or ($Path -eq $($dir + '\'))){
            $IsSensitive = $true
            Write-Warning "$Path is within a sensitive path! (Unsafe Directory)"
            break
        }
    }
    # Test for unsafe directories within specific unsafe directories
    # IE: C:\Windows\System32
    if ($IsSensitive -eq $false){
        foreach ($dir in $UnsafeDirectoriesRecurse){
            if($Path -like "$dir*"){
                $IsSensitive = $true
                Write-Warning "$Path is within a sensitive path! (Within Unsafe Directory)"
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
                Write-Warning "$Path is within a sensitive path! (Unsafe Directory any Drive)"
                break
            }
        }
    }

    # Test whether the path is exactly a drive letter
    if ($IsSensitive -eq $false){
        if($Path -match '^[a-zA-Z]:\\$' -or $Path -match '^[a-zA-Z]:$'){
            $IsSensitive = $true
            Write-Warning "$Path is a drive letter!"
        }
    }
    
    #If we made it this far, path isn't sensitive
    if($IsSensitive -eq $false){
        Write-Verbose "$Path is not a sensitive path."
    }

    return $IsSensitive
}