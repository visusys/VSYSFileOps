<#
.SYNOPSIS
    Demuxes (Separates) all audio source files from an array of videos.
    
    Requires ffmpeg to be installed and available in your system PATH
    environment variable.

.DESCRIPTION
    Demuxes (Separates) all audio source files from an array of videos.
    This function analyzes all video files to identify what codecs
    and file formats are being used, and then extracts the original
    audio source files. This process is completely lossless since no
    transcoding is taking place.

    There is an exception for the 'adpcm_ima_qt' codec as I couldn't
    get ffmpeg to output non-distorted files. This is handled by
    simply converting to wav, instead of aiff.

.PARAMETER SourceFiles
    An array of videos to demux audio from.

.PARAMETER OutputPath
    An optional path for demuxed output. By default all output is
    saved in the same directory as the target video file.

.EXAMPLE
    Convert-VideoDemuxAudio -SourceFiles $ArrayOfVideos

.EXAMPLE
    Convert-VideoDemuxAudio -SourceFiles $ArrayOfVideos -OutputPath "C:\Temp"

.INPUTS
    String Array

.OUTPUTS
    Nothing.

.NOTES
    Name: Convert-VideoDemuxAudio
    Author: Visusys
    Release: 1.0.0
    License: MIT License
    DateCreated: 2021-12-10

.LINK
    https://github.com/visusys

.LINK
    Get-VideoAudioStreams

.LINK
    Convert-VideoToAudio
    
#>
Function Convert-VideoDemuxAudio {
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
        $SourceFiles,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [String]
        $OutputPath 
    )
    
    # ffmpeg Cheat Sheat
    # 
    # -vcodec codec (output)
    # Set the video codec. This is an alias for -codec:v.
    # -codec is the same as -c
    # -c[:stream_specifier] codec (input/output,per-stream)
    # -codec[:stream_specifier] codec (input/output,per-stream)
    # :v, :a, :s are Stream Specifiers (http://ffmpeg.org/ffmpeg-all.html#Stream-specifiers)
    # 
    # -acodec is a subset that automatically scopes to Audio streams
    # -acodec:1 is the same as -codec:a:1 and indicates you are setting the codec 
    # for the second audio stream (the first audio stream is 0).
    # 
    # -c copy       = -acodec copy -vcodec copy
    # -c:a copy     = -acodec copy
    # -c:v copy     = -vcodec copy
    # -codec:a copy = -c:a copy
    # 
    # -copy
    # Stream copy is a mode selected by supplying the copy parameter to the -codec option. 
    # It makes ffmpeg omit the decoding and encoding step for the specified stream, 
    # so it does only demuxing and muxing. It is useful for changing the container 
    # format or modifying container-level metadata.
    # 
    # -c:a copy means that the input audio will be copied as is, without any transcoding. 
    # So if your input has mp3 audio, the output will also be mp3, an exact copy of the input.
    # 
    # The -vn / -an / -sn / -dn options can be used to skip inclusion of 
    # video, audio, subtitle and data streams respectively
    # 
    # ffmpeg -i INPUT -map 0 -c copy -c:v:1 libx264 -c:a:137 libvorbis OUTPUT
    # This is saying use the original codec for all the steams (-c copy), but for the 
    # second video stream use libx264 (-c:v:1 libx264), and for the 138th audio stream 
    # use libvorbis (-c:a:137 libvorbis).
    # 

    $FileFormats = [ordered]@{
        aac		        = "m4a"
        truehd	        = "thd"
        ac3             = "ac3"
        mp3             = "mp3"
        opus            = "opus"
        flac            = "flac"
        vorbis          = "oga"
        wmav2           = "wma"
        pcm_s16le       = "wav"
        mp2             = "mp2"
        adpcm_ima_qt    = "wav"
        adpcm_ms        = "wav"
        pcm_u8          = "wav"
        eac3            = "eac3"
    }
    
    $Duplicates = @{}
    $SourceFiles | ForEach-Object {

        $OriginalFile = [System.IO.Path]::GetFullPath($_)
        $FileDetails = ffprobe -loglevel 0 -print_format json -show_format -show_streams "$OriginalFile" | ConvertFrom-Json

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

        if($AudioStreamsList.Count -gt 0){
            for ($i = 0; $i -lt $AudioStreamsList.Count; $i++) {

                if($OutputPath){
                    if(!(Test-Path -LiteralPath $OutputPath)){
                        New-Item -Path $OutputPath -ItemType Directory -Force
                    }
                }
            
                $OriginalFileFolder = [System.IO.Path]::GetDirectoryName($OriginalFile)
                $FileBaseName = [System.IO.Path]::GetFileNameWithoutExtension($OriginalFile)
                
                $AudioStream = $AudioStreamsList[$i]
                $NewExtension = $FileFormats[$AudioStream.CodecName]
                if(!($NewExtension)) {
                    Write-Warning "Codec "$AudioStream.CodecName" has not been implemented yet. Skipping this file."
                    Break
                }

                if($AudioStream.Language){
                    $FileBaseName = $FileBaseName+" "+$AudioStream.Language.toUpper()
                    if($AudioStream.Title){
                        $FileBaseName = $FileBaseName+" "+$AudioStream.Title
                    }
                }

                if($OutputPath){
                    $NewAudioFile = ([System.IO.Path]::Combine($OutputPath, $FileBaseName)) + ".$NewExtension"
                }else{
                    $NewAudioFile = ([System.IO.Path]::Combine($OriginalFileFolder, $FileBaseName)) + ".$NewExtension"
                }

                if($Duplicates.Contains($NewAudioFile)){
                    if($OutputPath){
                        $BasePath = [System.IO.Path]::Combine($OutputPath, $FileBaseName)
                    }else{
                        $BasePath = [System.IO.Path]::Combine($OriginalFileFolder, $FileBaseName)
                    }
                    $NewName = ('{0}_{1}{2}' -f @(
                    $BasePath
                    ($Duplicates[$NewAudioFile].ToString().PadLeft(2, '0')) + '.'
                    $NewExtension
                ))} else {
                    $NewName = $NewAudioFile
                }

                $Duplicates[$NewName]++

                $NewName = '"{0}"' -f $NewName
                
                Write-Verbose "`$OriginalFile:              $OriginalFile" 
                Write-Verbose "`$OriginalFileFolder:        $OriginalFileFolder"
                Write-Verbose "`$FileBaseName:              $FileBaseName"
                Write-Verbose "`$NewExtension:              $NewExtension" 
                Write-Verbose "`$NewAudioFile:              $NewAudioFile"
                Write-Verbose "`$NewName:                   $NewName"  
                Write-Verbose "`$AudioStream.CodecName:     $($AudioStream.CodecName)"
                Write-Verbose "`$AudioStream.CodecLongName: $($AudioStream.CodecLongName)"
                Write-Verbose "`r`n"
                

                switch ($AudioStream.CodecName) {
                    'truehd' { 
                        & ffmpeg -loglevel fatal -vn -sn -dn -i $OriginalFile -map 0:a:$i -bsf:a truehd_core -c:a copy $NewName
                    }
                    # adpcm_ima_qt is broken, so we convert to .wav
                    'adpcm_ima_qt' {
                        & ffmpeg -loglevel fatal -vn -sn -dn -i $OriginalFile -map 0:a:$i $NewName
                    }
                    default {
                        & ffmpeg -loglevel fatal -vn -sn -dn -i $OriginalFile -map 0:a:$i -c:a copy $NewName
                    }
                } 
            }
        }
    }
}