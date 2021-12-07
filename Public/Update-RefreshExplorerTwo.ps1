function Update-RefreshExplorerTwo {
    $code = @'
[System.Runtime.InteropServices.DllImport("Shell32.dll")] 
private static extern int SHChangeNotify(int eventId, int flags, IntPtr item1, IntPtr item2);

public static void Refresh()  {
    SHChangeNotify(0x8000000, 0x1000, IntPtr.Zero, IntPtr.Zero);    
}
'@

    Add-Type -MemberDefinition $code -Namespace WinAPI -Name Explorer 
    [WinAPI.Explorer]::Refresh()

}

