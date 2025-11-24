<#
################################################################################

.SYNOPSIS
    Pings machines every 10s and shows colourful online status.

.DESCRIPTION
    Iterates through a list of machine names or IP addresses and pings them.
	Edit the $Servers variable to point to a txt file containing the machines,
	or use an array instead.
	Status is shown as online or offline in a table.
	
.NOTES
    Author: Geekujin
    Version: 1.0
	Created: 2022-08-08
	
################################################################################
#>

# Uncomment the source you wish to use below 

# Read machines from a txt file. Each host should be on a separate line.
#[Array] $Hosts = Get-Content -Path "PATH\TO\hosts.txt"

# Read machines from a specified array
[Array] $Hosts = ("192.168.1.1", "127.0.0.1", "8.8.8.8", "192.168.1.69")

$i = 1
Write-Host "`nTesting connection to servers`n" -ForegroundColor Cyan
Write-Host "Press " -noNewLine
Write-Host "CTRL+C " -ForeGroundColor Yellow -noNewLine
Write-Host "to quit`n"

While ($True) {
	Write-Host "Test $i" -noNewLine -ForegroundColor Magenta
	Write-Host ": " (Get-Date -Format "dd-MM-yy HH:mm:ss") -ForegroundColor Magenta
	Foreach($h in $Hosts){
		if(!(Test-Connection -Cn $h -Buffersize 16 -Count 1 -ea 0 -quiet)){
			Write-Host "[OFFLINE]" -ForegroundColor Red -nonewline 
			Write-Host " $h"
		} else {
			Write-Host "[ONLINE] " -ForegroundColor DarkGreen -nonewline
			Write-Host " $h"
		}
	}
	Write-Host " " 
	$i++
	Start-Sleep -Second 10
}