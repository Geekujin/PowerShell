<#
Title:		Online Host Checker
Created by: 	Marc Jones
Version:	1.0

About:		
This script runs through a list of computers specified in a file list and checks to see if they respond to a "Test Connection" ping. The status is then shown and updated every minute.


#>

# Enter the filepath to the file containing the hostnames. Each host should be on a separate line.

[Array] $Servers = Get-Content -Path "\path\to\serverlist.txt"



# DO NOT MODIFY BELOW THIS LINE



#Tests the connection to see if response received. If not, reports as offline, else shows as online
$i = 1
Write-Host " "
While ($i -lt 9999) {
Write-Host "Update $i -" (Get-Date).ToString("T")  -BackgroundColor Black -ForegroundColor Yellow
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
Start-Sleep -Second 10
}