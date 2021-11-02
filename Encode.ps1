function Encode ($dir){
	$vbitrate='300k'
	$abitrate='32k'
	$inFile=(Get-Item $PSCommandPath).Basename + ".mkv"
	$outPrefix= (Get-Item $inFile).Basename
	$vfilters='fps=30,scale="1280:-1"'
	$afilters='lowpass=12000,loudnorm=tp=0,aresample=48000'

	if ($vfilters -ne "") { $vfilters = "-vf $($vfilters)" }
	if ($afilters -ne "") { $afilters = "-af $($afilters)" }
	
	$commonParams = "-i `"$($inFile)`"","-y","-b:v $vbitrate","-b:a $abitrate",$afilters,"-ac 1",$vfilters,"-pix_fmt yuv420p","-g 300"
	
	# Encode an x264+aac MP4 video with abr. Nothing fancy. Needed for lame-o devices that don't support webm.
	$encodeMp4 = {
		param($commonParams, $outPrefix, $dir )
		Push-Location $dir
		$logfile = "$env:temp\ffmpeg-mp4-" + (Get-Random) + ".log"
		$mp4Params = "-passlogfile `"$logfile`"","-profile:v baseline","-preset:v placebo","-movflags +faststart"

		Start-Process -wait -filepath "ffmpeg" -WindowStyle Minimized -ArgumentList ($commonParams + $mp4Params + "-pass 1" + "`"$($outPrefix).mp4`"")
		Start-Process -wait -filepath "ffmpeg" -WindowStyle Minimized -ArgumentList ($commonParams + $mp4Params + "-pass 2" + "`"$($outPrefix).mp4`"")
	}

	# Encode vp9 webm using constrained quality. Shoots for crf target but limits to the specified bitrate.
	$encodeVp9 = {
		param( $commonParams, $outPrefix, $dir )
		
		Push-Location $dir
		$logfile = "$env:temp\ffmpeg-vp9-" + (Get-Random) + ".log"
		$vp9Params = "-passlogfile `"$logfile`"","-threads 8","-speed 1","-tile-columns 6","-frame-parallel 1","-auto-alt-ref 1","-lag-in-frames 25","-row-mt 1","-crf 33"

		Start-Process -wait -filepath "ffmpeg" -WindowStyle Minimized -ArgumentList ($commonParams + $vp9Params + "-pass 1" + "`"$($outPrefix).webm`"")
		Start-Process -wait -filepath "ffmpeg" -WindowStyle Minimized -ArgumentList ($commonParams + $vp9Params + "-pass 2" + "`"$($outPrefix).webm`"")
	}

	# Encode av1+opus webm using constrained quality. Shoots for crf target but limits to the specified bitrate.
	$encodeAv1 = {
		param( $commonParams, $outPrefix, $dir )
		Push-Location $dir
		$logfile = "$env:temp\ffmpeg-av1-" + (Get-Random) + ".log"
		$av1Params = "-c:v libaom-av1","-passlogfile `"$logfile`"","-row-mt 1","-tiles 2x2","-crf 30","-threads 8","-c:a libopus"
		
		Start-Process -wait -filepath "ffmpeg" -WindowStyle Minimized -ArgumentList ($commonParams + $av1Params  + "-pass 1" + "`"$($outPrefix).webm`"")
		Start-Process -wait -filepath "ffmpeg" -WindowStyle Minimized -ArgumentList ($commonParams + $av1Params  + "-pass 2" + "`"$($outPrefix).webm`"")
	}

	Start-Job $encodeMp4 -ArgumentList $commonParams,$outPrefix,$dir
	# Start-Job $encodeVp9 -ArgumentList $commonParams,$outPrefix,$dir
	Start-Job $encodeAv1 -ArgumentList $commonParams,$outPrefix,$dir

	Get-Job | Receive-Job -wait -AutoRemoveJob
}

Encode $PSScriptRoot