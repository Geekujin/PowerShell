<#
################################################################################

.SYNOPSIS
    Displays a random quote from a quotes.txt file.

.DESCRIPTION
    Quotes in quotes.txt should be one per line and formatted "quote" - Source
	Quotes are split into the quote and source to be displayed separately.

.NOTES
    Author: Geekujin
    Version: 1.0
	Created: 2025-11-04
	
################################################################################
#>

# Set the path of the file containing your quotes
$QuotesFile = "..\quotes.txt"

$QuoteColor = Blue
$SourceColor = DarkYellow


# Check if the file exists
if (Test-Path $quotesFile) {
    $quotes = Get-Content $quotesFile | Where-Object { $_.Trim() -ne "" }
    if ($quotes.Count -gt 0) {
        $randomQuote = Get-Random -InputObject $quotes

        if ($randomQuote -match '^"(.+)"\s*-\s*(.+)$') {
            $quote = $matches[1]
            $source = $matches[2]

			Write-Host "[Quote of the Day]" -ForegroundColor $QuoteColor
			Write-Host "`"$quote`""
			Write-Host " - $source`n" -ForegroundColor $SourceColor
		} else {
			Write-Host "`n$randomQuote`n"
        }
    } else {
        Write-Warn "No quotes found in the file."
    }
} else {
    Write-Warn "Quotes file not found at $quotesFile"
}