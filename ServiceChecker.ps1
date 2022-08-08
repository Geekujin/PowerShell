<#
Title:		Service Checker Powershell Script
Created by: Marc Jones (@DrGeekthumb)

About:
This script will Report the status of any specified services from a specific server, and will then start any stopped services from the list if requested.

Usage:
.\Check-Services.ps1 -srv <hostname>

For each server you wish to check, there must be a <hostname>.txt file in the path specified below which contains the name of each service on a seperate line.
#>

# Code may not 100% correct. Use at own risk

param(
[string]$srv
)
#Set your variables here

#Add the name of the server here, in quotes
$ServerName = $srv

#Add the path to a text file containing a list of each service to check on a different line
$SrvList = "\path\to\$srv.txt"
#Add the NAME of each service here in quotes. Each service must be separated by a comma
[Array] $Services = Get-Content -Path $SrvList

# DO NOT MODIFY BELOW THIS LINE

Function List-Svc {
Write-Host " "
Write-Host "Status   Name"
Write-Host "=======  ===="
Write-Host " "

#Checks each service from the array above and starts it if it isn't running
Foreach($serviceName in $Services)
{

	$arrService = Get-Service -Name $ServiceName -ComputerName $ServerName
		If ($arrService.Status -eq "Running") {
		$BGCol = "DarkGreen"
		}
		Else {
		$BGCol = "Red"
	}
	Write-Host $arrService.status -nonewline -Backgroundcolor $BGCol
	Write-Host " " $ServiceName

}
Write-Host " "
}

Function Start-Svc {
Write-Host " "
Write-Host "Starting stopped services"
Write-Host " "
Start-Sleep -Second 2
Foreach($serviceName in $Services)
{
	$arrService = Get-Service -Name $ServiceName -ComputerName $ServerName
#		Write-Host $ServiceName
		While ($arrService.Status -ne "Running")
		{
			Write-Host $ServiceName "is" $arrService.Status
			Start-Sleep -Second 2
			Write-Host " "
			Write-Host "Attempting to start" $ServiceName
			Write-Host " "
			$arrService | Set-Service -Status Running
		#	Start-Service -Name $ServiceName -ComputerName $ServerName
			Start-Sleep -seconds 15
			$arrService.Refresh()
			If ($arrService.Status -eq "Running"){
			Write-Host $ServiceName "is now " $arrService.Status
			} 
			Else {
			Write-Host "Unable to start" $ServiceName
			}
		Write-Host " "
		Write-Host "=============================="
		Write-Host " "
		}
}
}
Write-Host $srv
List-Svc
Start-Sleep -Second 5
$title = Start Services
$question = "Do you want to start stopped services?"
$choices = "&Yes", "&No"

$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)

if ($decision -eq 0) {
Start-Svc
List-Svc
} else {
Write-Host " "
Write-Host "Exiting..."
Write-Host " "
break
}
