function Invoke-GUIMessageBox {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [String]
        $Message,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [String]
        $Title="Notification",

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [ValidateSet('AbortRetryIgnore', 'CancelTryContinue', 'OK', 'OKCancel', 'RetryCancel', 'YesNo', 'YesNoCancel', IgnoreCase = $true)]
        [String]
        $Buttons='OKCancel',

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [ValidateSet('None', 'Error', 'Question', 'Warning', 'Information', IgnoreCase = $true)]
        [String]
        $Icon='Information',

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [ValidateSet('Button1', 'Button2', 'Button3', 'Button4', IgnoreCase = $true)]
        [String]
        $DefaultButton='Button1'
    )

    Begin {
        Add-Type -AssemblyName PresentationCore,PresentationFramework
        [System.Windows.Forms.Application]::EnableVisualStyles()
    }

    Process {
        $Result = [System.Windows.Forms.MessageBox]::Show($Message, $Title, $Buttons, $Icon, $DefaultButton)
        $Result
    }

    End {

    }
}
