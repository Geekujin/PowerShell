<#
Title: Get-ServerStatus
Version: 1.0
Author: DrGeekthumb
Info: Runs through a list of servers and checks to see if they respond to a "Test Connection" ping, outputting the status. Re-checks every minute
#>

# Enter list of hostnames to check here, separated by a comma
$servers = "SERVER1","SERVER2","SERVER3"


#Tests the connection to see if response received. If not, reports as offline, else shows as online
$i = 1
Write-Host " "
While ($i -lt 9999) {
Write-Host "Attempt $i - " (Get-Date).ToString("T")
Write-Host " "
Foreach($s in $servers)
{
if(!(Test-Connection -Cn $s -Buffersize 16 -Count 1 -ea 0 -quiet))

	{
	Write-Host "OFFLINE" -BackgroundColor Red -nonewline
	Write-Host " $s"
	}
ELSE 	
	{
	Write-Host "ONLINE " -Backgroundcolor DarkGreen -nonewline
	Write-Host " $s"
	}
} # end foreach
Write-Host " " 
$i++
Start-Sleep -Second 5
}