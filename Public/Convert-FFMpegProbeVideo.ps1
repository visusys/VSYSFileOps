function Convert-FFMpegProbeVideos {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [String[]]
        $Videos,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [ValidateSet('All', 'Video', 'Audio', 'Subtitles', 'Data', 'Attachments', IgnoreCase = $true)]
        [Alias('Format','Type', 'f')]
        [String]
        $StreamType='All',

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [ValidateSet('Default','JSON','CSV','Flat','Ini','XML', IgnoreCase = $true)]
        [String]
        $PrintFormat='json'

    )

    Process {

        $PrintFormat = $PrintFormat.ToLower()

        $StreamTypes = @{
            Video		= 'v'
            Audio	    = 'a'
            Subtitles	= 's'
            Data        = 'd'
            Attachments = 't'
        }

        foreach ($Video in $Videos) {
            switch ($StreamType) {
                'All' { 
                    $StreamDetails = ffprobe -loglevel 0 -print_format $PrintFormat -show_format -show_streams $Video
                }
                Default {
                    $StreamDetails = ffprobe -loglevel 0 -print_format $PrintFormat -show_format -show_streams -select_streams $StreamTypes[$StreamType] $Video
                }
            }
            $StreamDetails
        }
    }
}