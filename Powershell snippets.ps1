# Useful PowerShell snippets

# Change the colour of error messages in the shell
$opt = (Get-Host).PrivateData
$opt.WarningBackgroundColor = "darkyellow"
$opt.WarningForegroundColor = "white"
$opt.ErrorBackgroundColor = "red"
$opt.ErrorForegroundColor = "white"