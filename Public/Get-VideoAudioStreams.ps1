function Get-VideoAudioStreams {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript({
                if (!(Test-Path -LiteralPath $_)) {
                    throw [System.ArgumentException] "File does not exist." 
                }
                if (!(Test-Path -LiteralPath $_ -PathType Leaf)) {
                    throw [System.ArgumentException] "A folder was passed when a file was expected." 
                }
                if ($_ -notmatch "(\.mp4|\.m4v|\.mkv|\.webm|\.avi|\.mpeg|\.mpg|\.mov|\.wmv|\.flv)") {
                    throw [System.ArgumentException] "The file specified ($_) must be a supported video filetype."
                }
                return $true
            })]
        [String[]]
        $SourceFiles
    )

    $SourceFiles | ForEach-Object {

        $OriginalFile = [System.IO.Path]::GetFullPath($_)
        $OriginalFile = '"{0}"' -f $OriginalFile

        $FileDetails = ffprobe -loglevel 0 -print_format json -show_format -show_streams $OriginalFile | ConvertFrom-Json

        $AudioStreamsList = [System.Collections.Generic.List[object]]@()
        for ($i = 0; $i -lt $FileDetails.streams.Count; $i++) {
            if(($FileDetails.streams[$i].codec_type) -eq 'audio'){
                $Obj = [PSCustomObject][ordered]@{
                    CodecName       = $FileDetails.streams[$i].codec_name
                    CodecLongName	= $FileDetails.streams[$i].codec_long_name
                    SampleRate	    = $FileDetails.streams[$i].sample_rate
                    BitDepth	    = $FileDetails.streams[$i].sample_fmt
                    Channels	    = $FileDetails.streams[$i].channels
                    ChannelLayout   = $FileDetails.streams[$i].channel_layout
                    BitRate         = $FileDetails.streams[$i].bit_rate
                    Language        = $FileDetails.streams[$i].tags.language
                    Title           = $FileDetails.streams[$i].tags.title
                }
                $AudioStreamsList.Add($Obj)
            }
        }
        $AudioStreamsList
    }
}
