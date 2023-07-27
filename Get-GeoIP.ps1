<#
Title: GeoIP Checker
Version: 0.9
Author: DrGeekthumb
Info: Uses HackerTarget.com API to return geolocation results for a given IPv4 address.
Usage: ./Get-GeoIP.ps1 <IPv4 address>
#>

$ip=$args[0]
Write-Host " "
curl https://api.hackertarget.com/geoip/?q=$ip -UseBasicParsing | Select-Object -Expand Content
Write-Host " "
