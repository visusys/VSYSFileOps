<#
.SYNOPSIS
    Demuxes (Separates) all audio source files from an array of videos.
    
    Requires ffmpeg to be installed and available in your system PATH
    environment variable.

.DESCRIPTION
    Demuxes (Separates) all audio source files from a video or array 
    of videos. This function analyzes all video files to identify what 
    codecs and file formats are being used, and then extracts the original
    audio source files. This process is completely lossless (for the
    exception of some old codecs) since no transcoding is taking place.

    Old codecs that will not demux properly:
    adpcm_ima_qt
    qdm2

.PARAMETER SourceFiles
    An array of videos to demux audio from.

.PARAMETER OutputPath
    An optional path for demuxed output. By default all output is
    saved in the same directory as the target video file.

.PARAMETER PCMCodec
    The file format to demux raw PCM files to. 
    Must be either FLAC or WAV.

.PARAMETER OldCodec
    The file format to convert old and/or broken audio codecs to.
    Must be either FLAC or WAV.

.PARAMETER AddLanguageTag
    If set, and if the tag exists, the language tag will be added
    to the end of output filenames.

.PARAMETER AddTitleTag
    If set, and if the tag exists, the title tag will be added
    to the end of output filenames.

.EXAMPLE
    Convert-FFMpegDemuxAudio -SourceFiles $ArrayOfVideos

.EXAMPLE
    Convert-FFMpegDemuxAudio -SourceFiles $ArrayOfVideos -OutputPath "C:\Temp"

.INPUTS
    String Array

.OUTPUTS
    Nothing.

.NOTES
    Name: Convert-FFMpegDemuxAudio
    Author: Visusys
    Release: 1.0.0
    License: MIT License
    DateCreated: 2021-12-10

.LINK
    https://github.com/visusys

.LINK
    Convert-FFMpegProbeVideo

.LINK
    Convert-FFMpegGetVideoStreams
#>

Function Convert-FFMpegDemuxAudio {
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
        [String[]]
        $SourceFiles,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName)]
        [String]
        $OutputPath,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName)]
        [ValidateSet('Wav','FLAC', IgnoreCase = $true)]
        [String]
        $PCMCodec = 'FLAC',

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName)]
        [ValidateSet('Wav','FLAC', IgnoreCase = $true)]
        [String]
        $OldCodec = 'FLAC',

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [Switch]
        $AddLanguageTag,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [Switch]
        $AddTitleTag
    )

    process {

        $PCMCodec = $PCMCodec.ToLower()
        $OldCodec = $OldCodec.ToLower()

        $FileFormats = @{
            aac          = "m4a"
            truehd       = "thd"
            ac3          = "ac3"
            mp3          = "mp3"
            opus         = "opus"
            flac         = "flac"
            vorbis       = "oga"
            wmav2        = "wma"
            mp2          = "mp2"
            adpcm_ms     = "wav"
            eac3         = "eac3"
            pcm_alaw     = $PCMCodec
            pcm_f32be    = $PCMCodec
            pcm_f32le    = $PCMCodec
            pcm_f64be    = $PCMCodec
            pcm_f64le    = $PCMCodec
            pcm_mulaw    = $PCMCodec
            pcm_s16be    = $PCMCodec
            pcm_s16le    = $PCMCodec
            pcm_s24be    = $PCMCodec
            pcm_s24le    = $PCMCodec
            pcm_s32be    = $PCMCodec
            pcm_s32le    = $PCMCodec
            pcm_s8       = $PCMCodec
            pcm_u16be    = $PCMCodec
            pcm_u16le    = $PCMCodec
            pcm_u24be    = $PCMCodec
            pcm_u24le    = $PCMCodec
            pcm_u32be    = $PCMCodec
            pcm_u32le    = $PCMCodec
            pcm_u8       = $PCMCodec
        }

        $OldFileFormats = @{
            adpcm_ima_qt = $OldCodec
            qdm2         = $OldCodec
        }
        
        $ConversionMap = [PSCustomObject]@{
            Demux       = 1
            DemuxTrueHD = 2
            Convert     = 3
        }

        $Duplicates = @{}
        $SourceFiles | ForEach-Object {
    
            $OriginalFile = [System.IO.Path]::GetFullPath($_)
            $AudioStreamsList = Convert-FFMpegGetVideoStreams $OriginalFile -StreamType 'Audio'

            if ($AudioStreamsList.Count -eq 0) {
                Write-Verbose "No audio streams exist in $OriginalFile. Skipping."
            }
            if ($AudioStreamsList.Count -gt 0) {
                for ($i = 0; $i -lt $AudioStreamsList.Count; $i++) {

                    $ConversionRoutine = $ConversionMap.Demux
                    $FileOrigName   = [System.IO.Path]::GetFileName($OriginalFile)
                    $FileOrigFolder = [System.IO.Path]::GetDirectoryName($OriginalFile)
                    $FileOrigBase   = [System.IO.Path]::GetFileNameWithoutExtension($OriginalFile)
                    
                    $AudioStream = $AudioStreamsList[$i]
                    $FileNewExtension = $FileFormats[$AudioStream.CodecName]

                    if ($AudioStream.CodecName -eq 'truehd') {
                        $ConversionRoutine = $ConversionMap.DemuxTrueHD
                    }elseif ($OldFileFormats.ContainsKey($AudioStream.CodecName)) {
                        $ConversionRoutine = $ConversionMap.Convert
                        $FileNewExtension = $OldFileFormats[$AudioStream.CodecName]
                    }

                    if($AddLanguageTag){
                        If ($AudioStream.LanguageTag) {$FileOrigBase = $FileOrigBase + " " + $AudioStream.LanguageTag.toUpper()}
                    }
                    if($AddTitleTag){
                        if ($AudioStream.TitleTag) {$FileOrigBase = $FileOrigBase + " " + $AudioStream.TitleTag}
                    }

                    if ($OutputPath) {
                        if (!(Test-Path -LiteralPath $OutputPath)) {
                            New-Item -Path $OutputPath -ItemType Directory -Force
                        }
                        $NewAudioFile = ([System.IO.Path]::Combine($OutputPath, $FileOrigBase)) + ".$FileNewExtension"
                    }else{
                        $NewAudioFile = ([System.IO.Path]::Combine($FileOrigFolder, $FileOrigBase)) + ".$FileNewExtension"
                    }

                    if ($Duplicates.Contains($NewAudioFile)) {
                        if ($OutputPath) {
                            $BasePath = [System.IO.Path]::Combine($OutputPath, $FileOrigBase)
                        } else {
                            $BasePath = [System.IO.Path]::Combine($FileOrigFolder, $FileOrigBase)
                        }
                        $NewName = ('{0}_{1}{2}' -f @(
                            $BasePath
                            ($Duplicates[$NewAudioFile].ToString().PadLeft(2, '0')) + '.'
                            $FileNewExtension
                        ))
                    } else {
                        $NewName = $NewAudioFile
                    }
                    $Duplicates[$NewName]++
                    $NewName = '"{0}"' -f $NewName
                    
                    $INFONewFileName = [System.IO.Path]::GetFileName($NewAudioFile)
                    $INFOOriginalFileName = $FileOrigName
                    if($ConversionRoutine -eq $ConversionMap.Demux)      {$INFOConversionType = 'Demux'}
                    if($ConversionRoutine -eq $ConversionMap.DemuxTrueHD){$INFOConversionType = 'Demux TrueHD'}
                    if($ConversionRoutine -eq $ConversionMap.Convert)    {$INFOConversionType = 'Convert'}

                    Write-Verbose "----Starting Conversion---------------------------------------------------------------------------"  
                    Write-Verbose "`$File:                      $INFOOriginalFileName"
                    Write-Verbose "`$New File:                  $INFONewFileName"
                    Write-Verbose "`$Conversion Type:           $INFOConversionType"
                    Write-Verbose "`$AudioStream.CodecName:     $($AudioStream.CodecName)"
                    Write-Verbose "`$AudioStream.CodecLongName: $($AudioStream.CodecLongName)"
                    Write-Verbose "`$Filepath:                  $OriginalFile"
                    Write-Verbose "`$NewAudioFile:              $NewAudioFile"
                        
                    switch ($ConversionRoutine) {
                        $ConversionMap.DemuxTrueHD { 
                            & ffmpeg -loglevel fatal -vn -sn -dn -i $OriginalFile -map 0:a:$i -bsf:a truehd_core -c:a copy $NewName
                        }
                        $ConversionMap.Convert {
                            & ffmpeg -loglevel fatal -vn -sn -dn -i $OriginalFile -map 0:a:$i $NewName
                        }
                        $ConversionMap.Demux {
                            & ffmpeg -loglevel fatal -vn -sn -dn -i $OriginalFile -map 0:a:$i -c:a copy $NewName
                        }
                    }
    
                }
            }
        }
        Write-Output "Completed conversion."
    }
}
