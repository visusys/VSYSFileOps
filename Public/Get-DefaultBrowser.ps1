<#
.SYNOPSIS
    Returns information about the default browser.

.EXAMPLE
    (Get-DefaultBrowser).Name
    > Firefox

.INPUTS
    Nothing.

.OUTPUTS
    A PSCustomObject with details about the default browser.

.NOTES
    Name: SomeFunction
    Author: Visusys
    Release: 1.0.0
    License: MIT License
    DateCreated: 2021-12-18

.LINK
    https://github.com/visusys
    
#>
function Get-DefaultBrowser {
    [CmdletBinding()]
    param ()

    try {
        $BrowserRegPath     = 'HKCU:\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice'
        $DBrowserProgID     = (Get-Item $BrowserRegPath | Get-ItemProperty).ProgId
        $Command            = Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\$DBrowserProgID\shell\open\command" -ErrorAction Stop
        $DBrowserCommand    = $Command.'(default)'
        $DBrowserImagePath  = ([regex]::Match($DBrowserCommand,'\".+?\"')).Value
        $DBrowserImagePath  = $DBrowserImagePath.Trim('"')
        $DBrowserImage      = [System.IO.Path]::GetFileName($DBrowserImagePath)

    } catch {
        Write-Error $_
    }

    switch ($DBrowserProgID) {
        'IE.HTTP' { 
            $DBrowserName = "Internet Explorer"
        }
        'ChromeHTML' {
            $DBrowserName = "Chrome"
        }
        'MSEdgeHTM' {
            $DBrowserName = "Microsoft Edge"
        }
        'FirefoxURL-308046B0AF4A39CB' {
            $DBrowserName = "Firefox"
        }
        'FirefoxURL-E7CF176E110C211B' {
            $DBrowserName = "Firefox"
        }
        'AppXq0fevzme2pys62n3e0fbqa7peapykr8v' {
            $DBrowserName = "Microsoft Edge"
        }
        'OperaStable' {
            $DBrowserName = "Opera"
        }
        default{
            $DBrowserName = "Unknown Browser"
        }
    }

    [PSCustomObject]@{
        Name           = $DBrowserName
        ProgID	       = $DBrowserProgID
        Image	       = $DBrowserImage
        ImagePath      = $DBrowserImagePath
        DefaultCommand = $DBrowserCommand
    }
}