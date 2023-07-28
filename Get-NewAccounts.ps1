<#
Title: Get-NewAccounts
Version: 1
Author: DrGeekthumb
Info: Returns user accounts which have been created in the past $daysback days
#>

import-module activedirectory

$daysback = read-host "Go back how many days?"
Get-ADUser -Filter * -Property whenCreated | Where {$_.whenCreated -gt (Get-Date).AddDays(-$daysback)} | FT Name, whenCreated -Autosize