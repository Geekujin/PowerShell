<#
################################################################################
.SYNOPSIS
	Search and display emoji with their name and unicode number in the terminal. 

.DESCRIPTION
	This script reads emoji data from a local file path, prompting to download
	if it is missing. Options to display all emoji, or filter by groups and 
	subgroups. Script also has the ability to search emoji by name.

.PARAMETER -All
	Shows all emoji in a paged list.
	
.PARAMETER -List
	Displays a list of every group and subgroup available.
	
.PARAMETER -Group <string>
	Filters the output to only show emojis from a specified category.

.PARAMETER -SubGroup <string>
	Filters the output to only show emojis from a specified sub-category.

.PARAMETER -Search <string>
	Return emoji whose name includes this string.
################################################################################
#>

# Sets the script encoding to UTF8 for handling emoji
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Configuration
$EmojiUrl = "https://www.unicode.org/Public/17.0.0/emoji/emoji-test.txt"
$LocalFilePath = "PATH\TO\emoji-test.txt"


# Displays the Comment Based Help block
function Show-ScriptHelp {
    param(
        [string]$Path = $PSCommandPath
    )

    # Read all content of the script file
    $Content = Get-Content -Path $Path

    # Find the start and end of the Comment-Based Help block
    $StartLine = 0
    $EndLine = 0

    for ($i = 0; $i -lt $Content.Length; $i++) {
        if ($Content[$i].Trim() -eq '<#') {
            $StartLine = $i + 1
        } elseif ($Content[$i].Trim() -eq '#>') {
            $EndLine = $i - 1
            break
        }
    }

    if ($StartLine -le $EndLine) {
        Write-Host "`nAbout this script`n" -ForegroundColor Yellow
        # Output the content line by line, removing leading whitespace
        $Content[$StartLine..$EndLine] | ForEach-Object {
            $Line = $_.TrimStart()
            if ($Line.StartsWith('.')) {
                # Highlight Section Headers (.SYNOPSIS, .PARAMETER, etc.)
                 Write-Host $Line -ForegroundColor Cyan
            } elseif ($Line.StartsWith('#')) {
				# Skips printing of lines beginning with '#'
            } else {
                # Display other content (empty lines, etc.)
                Write-Host $Line
            }
        }
        Write-Host ""
    } else {
        Write-Host "[ERROR] Could not parse help block." -ForegroundColor Red
    }
}

# Fetch and parse emoji information from local file, or prompt to download it
function Get-Emoji {
    param(
        [Parameter(Mandatory=$false)]
        [string]$Group,

        [Parameter(Mandatory=$false)]
        [string]$SubGroup,
		
		[Parameter(Mandatory=$false)]
        [switch]$List,
		
		[Parameter(Mandatory=$false)]
        [switch]$All,
		
		[Parameter(Mandatory=$false)]
        [string]$Search
    )
        
	# Data Retrieval and Parsing
    function Get-EmojiData {
        # Check if data is already cached in the session
        if ($script:EmojiData) {
            return $script:EmojiData
        }

        # Check for local file existence
        if (-not (Test-Path $LocalFilePath)) {
            Write-Host "[ERROR]: FILE NOT FOUND!" -ForegroundColor Red
            Write-Host "Emoji data file not found at: $LocalFilePath" -ForegroundColor Yellow
            
            # Prompt user for download
            $DownloadResponse = Read-Host "Would you like to download the file now? (Y/N)"
            
            if ($DownloadResponse -ne 'Y' -and $DownloadResponse -ne 'y') {
                Write-Host "Download skipped. Please download the file manually from $EmojiUrl and place it in $LocalFilePath" -ForegroundColor DarkGray
                exit 1
            }

            Write-Host "Attempting download from $EmojiUrl..." -ForegroundColor Cyan
            
            try {
                # Ensure the directory exists
                $ScriptDir = Split-Path -Parent $LocalFilePath
                if (-not (Test-Path $ScriptDir)) {
                    New-Item -Path $ScriptDir -ItemType Directory | Out-Null
                }

                # Download the file content
                Invoke-WebRequest -Uri $EmojiUrl -OutFile $LocalFilePath -UseBasicParsing
                Write-Host "Download successful! File saved to $LocalFilePath" -ForegroundColor Green

            } catch {
                Write-Host "[ERROR]: Download failed." -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
                exit 1
            }
        }
        
        Write-Host "`nReading emoji data`n" -ForegroundColor DarkGray
        
        try {
            # Read the local content and parse the data
            $content = Get-Content -Path $LocalFilePath -Encoding UTF8
			# Initialise variables 
            $CurrentGroup = "N/A"
            $CurrentSubGroup = "N/A"
            $EmojiList = @()
            
            $content | ForEach-Object {
                $line = $_.Trim()
                if ($line -like "# group:*") {
                    $CurrentGroup = $line.Substring(9).Trim()
                }
                elseif ($line -like "# subgroup:*") {
                    $CurrentSubGroup = $line.Substring(12).Trim()
                }
                elseif ($line -match '^([\da-f\s]+);.*?#\s*(\S+)\s*E.*?\s(.*?)$') {
                    # Regex captures: 1. Code Points, 2. Emoji Character, 3. Emoji Name
                    $EmojiList += [PSCustomObject]@{
                        Code     = $Matches[1].Trim()
                        Emoji    = $Matches[2]
                        Name     = $Matches[3]
                        Group    = $CurrentGroup
                        SubGroup = $CurrentSubGroup
                    }
                }
            }
            # Cache the data for subsequent calls
            $script:EmojiData = $EmojiList
            return $EmojiList
            
        } catch {
            Write-Host "[ERROR]: Could not read or parse local file. Please check file integrity." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            exit 1
        }
    }

	# Retrieve the parsed data
    $Data = Get-EmojiData

    # Filtering and Output Logic

	# Search for text within the Name property
    if ($Search) {
        $SearchData = $Data | Where-Object { $_.Name -like "*$Search*" }
        
        if (-not $SearchData) {
            Write-Host "No emojis found matching '$Search'."
            return
        }

        Write-Host "Search Results for '$Search'"
        
        # Find the length of the longest code string in the search results to calculate column width
        $MaxCodeLength = ($SearchData | Select-Object -ExpandProperty Code | Measure-Object -Maximum -Property Length).Maximum
        
        # Add a buffer for padding after the longest code
        $CodeWidth = $MaxCodeLength + 1

        # Display results using the calculated fixed width via PadRight()
        $SearchData | Select-Object @{N='Code'; E={$_.Code.PadRight($CodeWidth)}},
                                 @{N='Emoji & Name'; E={"{0} {1}" -f $_.Emoji, $_.Name}} | 
        Format-Table -AutoSize | Out-Host

        return
    }
	
    # Start with all data and apply filters if Group or SubGroup are specified
    $FilteredData = $Data
    $OutputTitle = ""
    $IsFiltered = $false

    # Apply Group Filter
    if ($Group) {
        $FilteredData = $FilteredData | Where-Object { $_.Group -eq $Group }

        if (-not $FilteredData) {
            Write-Host "[ERROR]: Group '$Group' not found." -ForegroundColor Red
            $GroupNames = $Data | Select-Object -ExpandProperty Group -Unique | Sort-Object
            Write-Host "`nAvailable Groups: " -foregroundColor Cyan -nonewline
			Write-Host "$($GroupNames -join ', ')"
            return
        }
        $OutputTitle = "Group: $Group"
        $IsFiltered = $true
    }

    # Apply SubGroup Filter
    if ($SubGroup) {
        $FilteredData = $FilteredData | Where-Object { $_.SubGroup -eq $SubGroup }

        if (-not $FilteredData) {
            # If Group was specified, list only its subgroups; otherwise, list all
            if ($Group) {
				Write-Host "[ERROR]: Sub-group '$SubGroup' not found in group '$Group'." -ForegroundColor Red
                $SubGroupNames = ($Data | Where-Object { $_.Group -eq $Group } | Select-Object -ExpandProperty SubGroup -Unique | Sort-Object)
                Write-Host "Available SubGroups in '$Group': " -foregroundColor Cyan -nonewline
				Write-Host "$($SubGroupNames -join ', ')"
            } else {
				Write-Host "[ERROR]: Sub-group '$SubGroup' not found." -ForegroundColor Red
                $SubGroupNames = $Data | Select-Object -ExpandProperty SubGroup -Unique | Sort-Object
                Write-Host "Available SubGroups: " -foregroundColor Cyan -nonewline
				Write-Host "$($SubGroupNames -join ', ')"
            }
            return
        }
        $OutputTitle = "$Group > $SubGroup"
        $IsFiltered = $true
    }

	# Display all available emoji
    if ($All) {
		# Change the length of the page size if desired
        $PageSize = 50
    
        # Prepare data and formatting
        $MaxCodeLength = ($Data | Select-Object -ExpandProperty Code | Measure-Object -Maximum -Property Length).Maximum
        $CodeWidth = $MaxCodeLength + 2
        
        # Format the data into a list of strings
        $FormattedData = $Data | ForEach-Object {
            $CodePart = $_.Code.PadRight($CodeWidth)
            $EmojiNamePart = "{0} {1}" -f $_.Emoji, $_.Name
            "$CodePart$EmojiNamePart"
        }

        # Manual Paging Loop
        $CurrentLine = 0
        $PageNumber = 1
        
        do {
            Write-Host "Full Emoji List (Page $PageNumber, $PageSize items)" -ForegroundColor Yellow
            
            # Display the page content
            $FormattedData | Select-Object -Skip $CurrentLine -First $PageSize | ForEach-Object {
                Write-Host $_
            }
            
            $Remaining = $FormattedData.Count - ($CurrentLine + $PageSize)
            
            if ($Remaining -gt 0) {
                Write-Host "`n-- Press SPACEBAR or ENTER to continue, ESC or Q to quit --" -ForegroundColor Green
                Write-Host "      ($Remaining remaining)" -ForegroundColor DarkGreen
                # Capture a single keypress instantly
                $KeyInfo = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                $Key = $KeyInfo.Character
                
                # Check for Escape (Key code 27) or 'Q'/'q'
                if ($KeyInfo.VirtualKeyCode -eq 27 -or $Key -eq 'Q' -or $Key -eq 'q') {
                    Write-Host "`nList viewer closed." -ForegroundColor DarkGray
                    return
                }
                
                # Check for Spacebar (Key code 32) or Enter (Key code 13) to advance
                if ($KeyInfo.VirtualKeyCode -eq 32 -or $KeyInfo.VirtualKeyCode -eq 13) {
                    # Advance page
                    $CurrentLine += $PageSize
                    $PageNumber++
                }
                # If any other key is pressed, the loop simply repeats the current page.
            } else {
                Write-Host "`n--- End of List. Press any key to exit. ---" -ForegroundColor Green
                $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") # Wait for keypress
                return
            }
        } while ($CurrentLine -lt $FormattedData.Count)

        return
    }


	# Displays results filtered by group and/or subgroup
    if ($IsFiltered) {
        Write-Host "`nEmojis for $OutputTitle" -ForegroundColor Yellow
        
        # Calculate the required width for the Code column
        $MaxCodeLength = ($FilteredData | Select-Object -ExpandProperty Code | Measure-Object -Maximum -Property Length).Maximum
        $CodeWidth = $MaxCodeLength + 1
        
        # Display results using tFormat-Table
        $FilteredData | Select-Object @{N='Code'; E={$_.Code.PadRight($CodeWidth)}},
                                     @{N='Emoji & Name'; E={"{0} {1}" -f $_.Emoji, $_.Name}} | 
        Format-Table -AutoSize | Out-Host

        return
    }

	# Returns a list of all group and sub-group names
    if ($List) {
		Write-Host "`nAvailable Emoji Groups and Sub-groups`n" -ForegroundColor Green

		
		# Iterate through unique Groups
		$Groups = $Data | Select-Object -ExpandProperty Group -Unique | Sort-Object
		
		foreach ($GroupItem in $Groups) {
			Write-Host "GROUP: $($GroupItem)" -ForegroundColor Cyan
			
			# Find unique SubGroups within the current Group
			$SubGroups = $Data | Where-Object { $_.Group -eq $GroupItem } | 
								Select-Object -ExpandProperty SubGroup -Unique | 
								Sort-Object
		
			# Display the SubGroups with indentation
			$SubGroups | ForEach-Object {
				Write-Host " - $_" -Foregroundcolor darkcyan
			}
			Write-Host ""
		}
			
		Write-Host "`nSelect a " -NoNewLine
		Write-Host "Group" -ForegroundColor Cyan -NoNewLine
		Write-Host " or " -NoNewLine
		Write-Host "sub-group" -ForegroundColor DarkCyan -NoNewLine
		Write-Host " using the " -NoNewLine
		Write-Host "-Group" -ForegroundColor Yellow -NoNewLine
		Write-Host " or " -NoNewLine
		Write-Host "-SubGroup" -ForegroundColor Yellow -NoNewLine
		Write-Host " flags, or use " -NoNewLine
		Write-Host "-Search" -ForegroundColor Yellow -NoNewLine
		Write-Host " or " -NoNewLine
		Write-Host "-List" -ForegroundColor Yellow -NoNewLine
		Write-Host "."
		Write-Host ""
	}
}

# Script Execution
if ($MyInvocation.BoundParameters.Count -gt 0 -or $args.Count -gt 0) {
    # If arguments are present, call the function.
    Get-Emoji @args
} else {
	Show-ScriptHelp
    Write-Host ".EXAMPLES" -Foregroundcolor Cyan
    # Example 1
	Write-Host "Get-Emoji " -Foregroundcolor yellow -nonewline
	Write-Host "-Group " -ForegroundColor DarkGray -nonewline
	Write-Host "'Animals & Nature' " -nonewline
	Write-Host "-SubGroup " -ForegroundColor DarkGray -nonewline
    Write-Host "animal-marine"
    Write-Host "  Return all emoji from the animal-marine subcategory within 'Animals & Nature`n"
	# Example 2
	Write-Host "Get-Emoji " -Foregroundcolor yellow -nonewline
	Write-Host "-Search " -ForegroundColor DarkGray -nonewline
	Write-Host "rain "
    Write-Host "  Search for emoji that contain 'rain' in the name`n"
}
