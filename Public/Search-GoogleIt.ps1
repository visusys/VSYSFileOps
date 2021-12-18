function Search-GoogleIt {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [string[]]
        $Query,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [Switch]
        $ImageSearch,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [ValidateSet('', 'Any', '2mp', '4mp', '6mp', '8mp', '10mp', '12mp', '15mp', '20mp', '40mp', '70mp', IgnoreCase = $true)]
        [String]
        $ImageSearchSize = 'Any',

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [ValidateSet('', 'jpg', 'gif', 'png', 'bmp', 'svg', 'webp', 'ico', 'raw', IgnoreCase = $true)]
        [String]
        $ImageFileType = '',

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [ValidateScript({
            if($_ -eq ''){
                return $true
            }
            if (!(Confirm-ValidURL -URL $_)) {
                throw [System.ArgumentException] "Passed URL is not valid."
            }
            return $true
        })]
        [String]
        $SiteOrDomain = ''
    )

    process {

        if($ImageSearchSize -eq 'Any'){
            $ImageSearchSize = ''
        }
        if($SiteOrDomain){
            $SiteOrDomain = "site:$SiteOrDomain"
        }
        if($FileType){
            $FileType = "filetype:$FileType"
        }
        if($ImageFileType){
            $ImageFileType = $ImageFileType.ToLower()
        }


        $DefaultBrowserPath = (Get-DefaultBrowser).ImagePath
        $GetBrowser = Get-Process | Where-Object Path -eq $DefaultBrowserPath
        if(!($GetBrowser)){
            Start-Process $DefaultBrowserPath
            do {
                Start-Sleep 1
                $BrowserProcess = Get-Process | Where-Object Path -eq $DefaultBrowserPath -ErrorAction SilentlyContinue
            } Until ( $BrowserProcess )
            
        }
        foreach ($Q in $Query) {
            $Q = $Q -replace ' ','+'
            if($ImageSearch){
                $SearchString =  "https://www.google.com/search?as_st=y&tbm=isch&as_q=$Q+$SiteOrDomain&as_epq=&as_oq=&as_eq=&cr=&as_sitesearch=&safe=images&tbs=isz:lt,islt:$ImageSearchSize,ift:$ImageFileType"
            }else{
                $SearchString = "https://www.google.com/search?q=$Q+$SiteOrDomain"
            }
            Start-Sleep .1
            Start-Process $SearchString
        }
    }
}
