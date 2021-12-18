function Convert-FFMpegGetVideoStreams {
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
                if ($_ -notmatch '(\.mp4|\.m4v|\.mkv|\.webm|\.avi|\.mpeg|\.mpg|\.mov|\.wmv|\.flv)$') {
                    throw [System.ArgumentException] "The file specified ($_) must be a supported video filetype."
                }
                return $true
            })]
        [String]
        $SourceFile,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Video','Audio','Subtitle','Data','Attachments','Format', IgnoreCase = $true)]
        [string]
        $StreamType = 'Video'
    )

    process {
        
        $StreamDetails = Convert-FFMpegProbeVideos $SourceFile | ConvertFrom-Json

        if($StreamType -eq 'Format'){
            [PSCustomObject][ordered]@{
                Filename        = $StreamDetails.format.filename
                FormatName      = $StreamDetails.format.format_name
                FormatLongName  = $StreamDetails.format.format_long_name
                NumberStreams   = $StreamDetails.format.nb_streams
                NumberPrograms  = $StreamDetails.format.nb_programs
                StartTime       = $StreamDetails.format.start_time
                Duration        = $StreamDetails.format.duration
                Size            = $StreamDetails.format.size
                Bitrate         = $StreamDetails.format.bit_rate
                ProbeScore      = $StreamDetails.format.probe_score
                TagsEncoder     = $StreamDetails.format.tags.encoder
            }
        }

        if($StreamType -eq 'Audio'){
            $StreamsList = foreach ($StreamValue in $StreamDetails.streams) {
                if ($StreamValue.codec_type -ne 'audio') {
                    continue
                }
                [PSCustomObject][ordered]@{
                    CodecName     = $StreamValue.codec_name
                    CodecLongName = $StreamValue.codec_long_name
                    SampleRate    = $StreamValue.sample_rate
                    BitDepth      = $StreamValue.sample_fmt
                    Channels      = $StreamValue.channels
                    ChannelLayout = $StreamValue.channel_layout
                    BitRate       = $StreamValue.bit_rate
                    LanguageTag   = $StreamValue.tags.language
                    TitleTag      = $StreamValue.tags.title
                    Duration      = $StreamDetails.format.duration
                }
            }
        }

        if($StreamType -eq 'Video'){
            $StreamsList = foreach ($StreamValue in $StreamDetails.streams) {
                if ($StreamValue.codec_type -ne 'video') {
                    continue
                }
                [PSCustomObject][ordered]@{
                    CodecName           = $StreamValue.codec_name
                    CodecLongName       = $StreamValue.codec_long_name
                    FormatName          = $StreamDetails.format.format_name
                    FormatLongName      = $StreamDetails.format.format_long_name
                    Width               = $StreamValue.width
                    Height              = $StreamValue.height
                    AspectRatio         = $StreamValue.display_aspect_ratio
                    PixelFormat         = $StreamValue.pix_fmt
                    HasBFrames          = $StreamValue.has_b_frames
                    Level               = $StreamValue.level
                    FrameRate           = $StreamValue.r_frame_rate
                    FrameRateAverage    = $StreamValue.avg_frame_rate
                    TimeBase            = $StreamValue.time_base
                    IsAVC               = $StreamValue.is_avc
                    Profile             = $StreamValue.profile
                    FormatDuration      = $StreamDetails.format.duration
                    FormatSize          = $StreamDetails.format.size
                    FormatBitrate       = $StreamDetails.format.bit_rate
                }
            }
        }

        if($StreamType -eq 'Subtitle'){
            $StreamsList = foreach ($StreamValue in $StreamDetails.streams) {
                if ($StreamValue.codec_type -ne 'subtitle') {
                    continue
                }
                [PSCustomObject][ordered]@{
                    CodecName           = $StreamValue.codec_name
                    CodecLongName       = $StreamValue.codec_long_name
                    TimeBase            = $StreamValue.time_base
                    Duration            = $StreamValue.duration
                    DurationTS          = $StreamValue.duration_ts
                    LanguageTag         = $StreamValue.tags.language
                    TitleTag            = $StreamValue.tags.title
                }
            }
        }

        if($StreamType -eq 'Data'){
            $StreamsList = foreach ($StreamValue in $StreamDetails.streams) {
                if ($StreamValue.codec_type -ne 'data') {
                    continue
                }
                [PSCustomObject][ordered]@{
                    CodecName           = $StreamValue.codec_name
                    CodecLongName       = $StreamValue.codec_long_name
                    TimeBase            = $StreamValue.time_base
                    Profile             = $StreamValue.profile
                    Language            = $StreamValue.tags.language
                    Title               = $StreamValue.tags.title
                }
            }
        }

        if($StreamType -eq 'Attachments'){
            $StreamsList = foreach ($StreamValue in $StreamDetails.streams) {
                if ($StreamValue.codec_type -ne 'attachment') {
                    continue
                }
                [PSCustomObject][ordered]@{
                    CodecName           = $StreamValue.codec_name
                    CodecLongName       = $StreamValue.codec_long_name
                    Filename            = $StreamValue.tags.language
                    Mimetype            = $StreamValue.tags.title
                }
            }
        }
        
        $StreamsList
    }
}
