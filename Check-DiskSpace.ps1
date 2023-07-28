<#
Title:		Disk Space Checker
Version:	4.1
Author: DrGeekthumb

About:		
This script runs through a list of servers and reports whether the amount of free disk space on Drive C is above or below a specified threshold. 

Notes:
Can be temperamental, some connections randomly error out.

Changelog:
v1.0 initial release
v2.0 updated formatting and allowed credentials to pass through
v3.0 included error handling
v4.0 added variable for disk space threshold
#>



[Array] $Servers = Get-Content -Path "\path\to\serverlist.txt" # list of all servers, including FQDN. One server per line.

$authaccount = "DOMAIN\changeme" # account used to connect to servers
$threshold = 16 # size in GB. Sets what the script determines as Low Disk space


function Format-Color([hashtable] $Colors = @{}, [switch] $SimpleMatch) {
	$lines = ($input | Out-String) -replace "`r", "" -split "`n"
	foreach($line in $lines) {
		$color = ''
		foreach($pattern in $Colors.Keys){
			if(!$SimpleMatch -and $line -match $pattern) { $color = $Colors[$pattern] }
			elseif ($SimpleMatch -and $line -like $pattern) { $color = $Colors[$pattern] }
		}
		if($color) {
			Write-Host -BackgroundColor $color $line
		} else {
			Write-Host $line
		}
	}
}
Function pause ($message)
{
    # Check if running Powershell ISE
    if ($psISE)
    {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("$message")
    }
    else
    {
        Write-Host "$message" -ForegroundColor Yellow
        $x = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}


$tbl = New-Object System.Data.DataTable "Servers"
$col1 = New-Object System.Data.DataColumn Space
$col2 = New-Object System.Data.DataColumn Server
$col3 = New-Object System.Data.DataColumn Resize
$tbl.Columns.Add($col1)
$tbl.Columns.Add($col2)
$tbl.Columns.Add($col3)


Write-Host " "
Write-Host "Geek's Drive Checker"
Write-Host "========================"
Write-Host " "
Write-Host "Key"
Write-Host "   "  -Backgroundcolor DarkGreen -nonewline
Write-Host " = More than or equal to " -nonewline
Write-Host $threshold -nonewline
Write-Host "GB free space"
Write-Host "   " -Backgroundcolor Red -nonewline
Write-Host " = Less than " -nonewline
Write-Host $threshold -nonewline
Write-Host "GB free space"
Write-Host "   " -Backgroundcolor Magenta -nonewline
Write-Host " = Error connecting to server, please investigate"
Write-Host " "
Write-Host "Please enter credentials to connect to the servers when prompted..."
Write-Host " "
Write-Host " "
$creds = $host.ui.PromptForCredential("Authenticate to servers", "Please enter password for account specified in script", $authaccount, ":")
Write-Host "Checking disk space, this may take several minutes..."
Write-Host " "
Write-Host " "
Write-Host " "

#loop through each server and check the disk space
foreach ($i in $Servers)
{
    Try {

    $diskcheck = Invoke-Command -computername $i {Get-PSDrive C} -credential $creds -ErrorAction Stop | select @{n="Free";e={[math]::Round($_.Free/1GB,2)}}, PSComputerName 
    }
    Catch
    {
    $diskcheck.PSComputerName = $i
    $diskcheck.Free = "Error"
    $enoughspace = "Error"
    Write-Host $i " encountered an error"
    }

    if ($diskcheck.Free -ge $threshold) {
	    $enoughspace = "No"
	    }
	    ElseIf ($diskcheck.Free -lt $threshold -and $diskcheck.Free -ge 0) {
	    $enoughspace = "Yes"
        }
        Else {
        $enoughspace = "Err"
        }

#build the table
$row = $tbl.NewRow()
$row.Space = $diskcheck.Free
$row.Server = $diskcheck.PSComputerName
$row.Resize = $enoughspace
$tbl.Rows.Add($row)

}
$tbl | Format-Color @{'No' = 'darkgreen'; 'Yes' = 'red'; 'Error' = 'magenta'}

Write-Host " "
Write-Host "You can connect to any errored server and run the checks manually by entering the following in a PowerShell prompt:"
Write-Host " "
Write-Host " Enter-PSSession -computername <SERVERNAME> " -Backgroundcolor Black -ForegroundColor Yellow -nonewline
Write-Host " and running " -nonewline
Write-host " Get-PSDrive C "  -Backgroundcolor Black -ForegroundColor Yellow
Write-Host " "
Write-Host " "
Pause "Press any key to exit..."