function Test-IsSensitiveWindowsPath {
	[CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)] 
        [String]$Path,

        [Parameter(Mandatory=$false)]
        [Switch]$CheckValid
    )

    # Begin path validation
    #
    if($CheckValid){
        if(!(Test-Path $Path)){
            throw [System.ArgumentException] "The path specified doesn't exist."
        }
        if(!(Test-Path $Path -IsValid)){
            throw [System.ArgumentException] "The path specified is invalid."
        }
        if(Test-Path $Path -PathType leaf){
            throw [System.ArgumentException] "File passed when expected path."
        }
        if(($null -eq $Path) -or ([string]::IsNullOrEmpty($Path.Trim()))){
            throw [System.ArgumentException] "The path specified is either empty or null."
        }
    }

    # Convert to backslash and limit consecutives
    $Path = $Path.Replace('/','\')
    $Path = $Path -replace('\\+','\')

    $OSDrive = $((Get-WmiObject Win32_OperatingSystem).SystemDrive)
    if(($OSDrive -eq "") -or ($OSDrive -eq " ") -or ($null -eq $OSDrive)){
        throw "Could not determine the system drive."
    }

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