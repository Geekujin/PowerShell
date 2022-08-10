<#
Title: Get-NewADAccounts
Version: 0.9
Author: Geekthumb
Info: Returns Active Directory accounts which have been created within the past $daysback days
#>

import-module activedirectory
$daysback = read-host "Go back how many days?"
Get-ADUser -Filter * -Property whenCreated | Where {$_.whenCreated -gt (Get-Date).AddDays(-$daysback)} | FT Name, whenCreated -Autosize
