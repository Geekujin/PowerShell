# Title: Send2Discord
# Author: DrGeekthumb
# About: Uploads a file to your Discord server via a webhook. More info on webhooks can be found here: https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks
# Usage ./Send2Discord.ps1 "path/to/file"


$file = $args[0]
$url="WEBHOOK URL GOES HERER"
$Body=@{ content = "File uploaded from $env:computername "}
Invoke-RestMethod -ContentType 'Application/Json' -Uri $url  -Method Post -Body ($Body | ConvertTo-Json)
curl.exe -F "file1=@$file" $url
