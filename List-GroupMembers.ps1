<#
Title: List-GroupMembers
Version: 1
Author: DrGeekthumb
Info: Lists all members of a domain group
#>

$ADGrp = Read-Host -Prompt 'Enter the AD Group Name'
Get-ADGroupMember  -Identity "$ADGrp" | Select Name