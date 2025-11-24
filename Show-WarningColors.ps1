<#
################################################################################

.SYNOPSIS
    Test and display different colour combinations for ERROR and WARNING text

.DESCRIPTION
    Useful when combined with Set-ErrorColor to set the default error and 
	warning colours in the console.

.NOTES
    Author: Geekujin
    Version: 1.0
	Created: 2025-11-24
	
################################################################################
#>

$WarningBack = "Black" # Background color of warning message
$WarningFore = "DarkYellow" # Foreground color of warning message
$ErrorBack = "DarkRed" # Background color of error message
$ErrorFore = "White" # Foreground color of error message

Write-Host "`nPowerShell Warning Text Colours`n" -foregroundcolor Green

# Display the default warning and error messages
Write-Host "Current colours" -foregroundcolor Black -backgroundcolor Cyan
Write-Host " "

Write-Warning "This is a default warning message"
Write-Host " "

Write-Error "This is a default error message"
Write-Host " "

# Show how the error messages would look using the new colour set
Write-Host "New colours" -foregroundcolor Black -backgroundcolor Cyan
Write-Host " "

Write-Host "WARNING: This is a new warning message" -backgroundcolor $WarningBack -foregroundcolor $WarningFore
Write-Host " "

Write-Host "$($MyInvocation.MyCommand.Path) : This is a new error message" -backgroundcolor $ErrorBack -foregroundcolor $ErrorFore
Write-Host "At line:1 char:1" -backgroundcolor $ErrorBack -foregroundcolor $ErrorFore
Write-Host "+ warn-colors" -backgroundcolor $ErrorBack -foregroundcolor $ErrorFore
Write-Host "+ ~~~~~~~~~~~" -backgroundcolor $ErrorBack -foregroundcolor $ErrorFore
Write-Host "    + CategoryInfo          : NotSpecified: (:) [Write-Error],WriteErrorException" -backgroundcolor $ErrorBack -foregroundcolor $ErrorFore
Write-Host "    + FullyQualifiedErrorId :Microsoft.PowerShell.Commands.WriteErrorException,Show-WarningColors.ps1" -backgroundcolor $ErrorBack -foregroundcolor $ErrorFore
