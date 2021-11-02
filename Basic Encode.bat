pushd %~dp0

set bitrate=150k 
set inFile=Add Personal Printer.mkv
set outPrefix=Add Personal Printer
set filters=fps=30,scale="1280:-1"

ffmpeg -i "%inFile%" -y -pass 1 -b:v %bitrate% -tune stillimage -profile:v baseline -b:a 32k -af lowpass=12000 -ac 1 -preset:v placebo -vf %filters% -pix_fmt yuv420p "%outPrefix%.mp4"
ffmpeg -i "%inFile%" -y -pass 2 -b:v %bitrate% -tune stillimage -profile:v baseline -b:a 32k -af lowpass=12000 -ac 1 -movflags +faststart -preset:v placebo -vf %filters% -pix_fmt yuv420p "%outPrefix%.mp4"

ffmpeg -i "%inFile%" -y -pass 1 -b:v %bitrate% -pix_fmt yuv420p -threads 8 -b:a 32k -ac 1 -speed 4 -tile-columns 6 -vf %filters% -af lowpass=12000 -frame-parallel 1 "%outPrefix%.webm"
ffmpeg -i "%inFile%" -y -pass 2 -b:v %bitrate% -pix_fmt yuv420p -threads 8 -b:a 32k -ac 1 -speed 1 -tile-columns 6 -vf %filters% -af lowpass=12000 -frame-parallel 1 -auto-alt-ref 1 -lag-in-frames 25 "%outPrefix%.webm"
