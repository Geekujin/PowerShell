<#
################################################################################

.SYNOPSIS
    Change the ERROR and WARNING text colour inside the terminal

.DESCRIPTION
    Place the function in your PowerShell profile to set this for each session.
	Useful when combined with ShowWarningColors to test new error and 
	warning colours in the console.

.NOTES
    Author: Geekujin
    Version: 1.0
	Created: 2025-11-24
	
################################################################################
#>

function Set-ErrWarnColor {
	# Reads the Warning and Error fore and background from the terminal
	$opt = (Get-Host).PrivateData
	
	# Sets the colours
	$opt.WarningBackgroundColor = "Black"
	$opt.WarningForegroundColor = "Yellow"
	$opt.ErrorBackgroundColor = "Black"
	$opt.ErrorForegroundColor = "DarkRed"
}

# Runs the above function
Set-ErrWarnColor