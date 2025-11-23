<#
.SYNOPSIS
    Calculates and displays supported hashes for a specified file, with optional VirusTotal search.

.DESCRIPTION
    Calculates all supported hashes for a given file, displaying the output in the console. Prompts for
	filepath within script if omitted.
	Optional parameters allow saving the hash output to a .txt file or automatically launching a VirusTotal
	search. There are options for self testing and also running in debug mode

.PARAMETER File
    Mandatory. Specify the file to check. File paths with spaces must be enclosed in quotes.
	
.PARAMETER VT
	Optional. After calculating the hashes, searches VirusTotal for the SHA1 hash using the default browser.
		
.PARAMETER Test
	Optional. Performs a self-test by calculating the SHA256 of a file and comparing it against a value stored in $ExpectedHash
	
.PARAMETER Debug
	Optional. Uses PowerShell's built in debugging functionality, with additional context provided.

.EXAMPLE
    Get-Hashes -File "C:\My Files\file.exe"
	Calculate hashes for file.exe and display the output in the console.
	
	Get-Hashes -File "C:\My Files\file.exe" -VT
	Calculate and display hashes for file.exe and then launch a VirusTotal search.

.NOTES
    Author: 	Geekujin
	Contact: 	hello [at] geekujin [dot] net
    Version: 	2.0
	About: 		overhaul of a script I created for a uni exam. future versions will likely include the ability to directly check the file on
				VirusTotal using the API, and the ability to return a single raw hash string for a given algorithm.
#>

# Parameters and enabling of native debug support
[CmdletBinding(SupportsShouldProcess=$true)]
param(
	[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
	[string]$File,
		
	[Parameter(Mandatory=$false)]
	[switch]$Test,
	
	[Parameter(Mandatory=$false)]
	[switch]$VT
	)
	
# Variables #

# Array of supported hashtypes
$HashType = @("SHA1", "SHA256", "SHA384", "SHA512", "MACTripleDES", "MD5", "RIPEMD160")

# Path of the test file and it's SHA256 hash.
$TestFile = ".\testfile.txt"
$TestHash = "A0151E1B63C7410CB03D9DD4FCD5371632F28E8E97D1E402ED73774D5B8480F1"

# Functions #

function Test-Hashing {
	
	Write-Debug "Starting self-test function."
	
    if (Test-Path -Path $TestFile -PathType Leaf) {
        Write-Host "Test file found..."
        Write-Host "Calculating hash of test file..."
        $CalculatedHash = Get-FileHash -Path $TestFile -Algorithm SHA256 | select-object -ExpandProperty Hash
        Write-Host " "
        Write-Host "Expected hash: " -nonewline -foregroundcolor yellow
        $TestHash
	    Write-Host "Computed hash: " -nonewline -foregroundcolor yellow
	    $CalculatedHash
        Write-Host " "
        if ($CalculatedHash -ne $TestHash){
		    Write-Host " "
		    Write-Warning "File hashes do not match!" -foregroundcolor red
		    Write-Host " "
	    } else {
		    Write-Host "File hashes match!" -foregroundcolor Green
	    }
        Write-Host " "
        Write-Host "Testing completed" -foregroundcolor yellow
		exit 0
    } else {
        Write-Warning 'Test file not found. Please ensure the $TestFile variable contains the correct path.'
		exit 1
    }
}

function Get-FilePath {
	Write-Debug "Starting Get-FilePath function."
	
	# Check if file has been provided by -File switch, if not, prompt for file.
	if (-not [string]::IsNullOrEmpty($File)) {
		Write-Debug "File path provided via -File parameter: '$File'"
		
		$File = Read-Host "Please enter the full path to the file you would like to check"
	} else {
	}
	
	# Check if the file exists
	Write-Debug "Checking if $File exists"
	
	if (!(Test-Path -Path $File -PathType Leaf)){
        Write-Host " "
        Write-Warning "File '$File' does not exist! Exiting..."
        Write-Host " "
        exit 1
    } 

    return $File
}

function Get-HashValues {
	[CmdletBinding(SupportsShouldProcess=$true)]
    param(
		[Parameter(Mandatory=$true)]
        [string]$FilePath
	)
	Write-Debug "Starting Get-HashValues function for file $Flie"
	
	# Initialise a local hashtable for storing key/value pairs of each hashing algorithm.
	$Hashes = @{}
	
	foreach ($HashKey in $HashType) {
		Write-Debug "Processing hash type: $HashKey"
		
		$HashValue = Get-FileHash -Path $File -Algorithm $HashKey | Select-Object -ExpandProperty Hash
		
		$Hashes.Add($HashKey, $HashValue)
	}
	Write-Debug "Finished processing all hash types."
	
	return $Hashes
}

function Show-Info {
	$FileName = Split-Path $File -leaf
	Write-Host " "
	Write-Host "Hash values for file: " -foregroundcolor white -nonewline
	Write-Host "'$FileName'" -foregroundcolor DarkCyan
	Write-Host " "	
}

function Show-Output {
	[CmdletBinding(SupportsShouldProcess=$true)]
    param(
		[Parameter(Mandatory=$true)]
        [string]$FilePath,
		
		[Parameter(Mandatory=$true)]
        [hashtable]$HashData,
		
		[Parameter(Mandatory=$false)]
        [switch]$VT 
	)
	
	Write-Debug "Starting Show-Output function with filepath: $File"
	
	# Display the hash data stored in the table
	foreach ($Key in $HashType) {
		Write-Host $key -nonewline -foregroundcolor DarkGreen
        Write-Host ": " -nonewline -foregroundcolor DarkGreen
        Write-Host $HashData[$key] -foregroundcolor DarkYellow
    }
	
	
	Write-Debug "Creating VirusTotal link using SHA1 hash: $SHA1Hash"
	$SHA1Hash = $HashData.SHA1
    $VTUrl = "https://www.virustotal.com/gui/search/$SHA1Hash"
	
	if ($VT) {
		Write-Host "`nLaunching VirusTotal search in default browser..." -foregroundcolor Cyan
		# Start-Process launches the default application for the given URL
		Start-Sleep -Seconds 2
        Start-Process $VTUrl
	}	
}


# Main script execution

if ($Test) {
    # If the -Test switch is present, run the self-test function and stop.
	Write-Debug "-Test switch detected. Running self-test."
    Test-Hashing
} else {
	Write-Debug "Running standard hash check mode."
	$HashResults = Get-HashValues -FilePath $File
	Show-Info
	Show-Output -FilePath $file -HashData $HashResults -VT:$VT
	Write-Host " "
}