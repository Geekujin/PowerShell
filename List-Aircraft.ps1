<#
################################################################################

.SYNOPSIS
    Display aircraft from an ADS-B receiver usinf the aircraft.JSON file.

.DESCRIPTION
    The script displays aircraft seen by the ADSB receiver, sorted by last seen.
    Any aircraft not seen in last 10 minutes show as a darker gray. Aircraft of 
	interest can be added in the config section. Police show as blue, Coast 
	Guard as Magenta and Air Ambulance as Green. Squawks 7500, 7600 and 7700 
    will show with a bright red background.	

################################################################################
#>

# CONFIGURATION
# You can customise the table display by changing the values in this section.

# The url of your Tar1090 instance - including the https(s) prefix - followed by the path to the aircraft.json file
# (usually /data/aircraft.json).
$url = "https://example.com/data/aircraft.json"

# Field to sort table by. Supported fields are icao, Call, Tail, Type, Alt, Dist and Seen
$sortProperty = "seen"

# The maximum number of aircraft to display. Set to 0 to show all results.
$resultLimit = 30

# The time in seconds between each data refresh.
$refreshRate = 15

# List of tail numbers to highlight. v2 will likely move this to an external text file.
$highlightedTails = @(
    'G-ABCD', # Comments / notes can go here
    "PA474" # 1 of 2 remaining airworthy Lancaster Bombers
)

# Pre-populated lists of known aircraft.
$policeTails = @(
    "G-CPAO", "G-CPAS", "G-DCPB", "G-EMID", "G-HEOI", "G-MCSI", "G-MPSA", "G-MPSB", "G-MPSC", "G-NWOI", "G-POLA", "G-POLB", "G-POLC", "G-POLD", "G-POLF", "G-POLG", "G-POLH", "G-POLJ", "G-POLS", "G-POLU", "G-POLV", "G-POLW", "G-POLX", "G-POLZ", "G-PSHU", "G-SUFK", "G-TVHB", "ZM498", "ZM502"
)
$airambTails = @(
    "G-BZRS", "G-CPTZ", "G-CRWL", "G-DSAA", "G-EMAA", "G-EMSS", "G-GWAC", "G-HEMC", "G-HEMN", "G-HEMZ", "G-HIOW", "G-HMAA", "G-HWAA", "G-LNAC", "G-LOYW", "G-MGPS", "G-NHAD", "G-NSCA", "G-NWAA", "G-NWAE", "G-NWEM", "G-PSCA", "G-RESU", "G-SCAA", "G-SPHU", "G-SPHU", "G-WLTS", "G-WOBR", "G-YAAA", "G-YAIR", "G-YORX"
)
$coastTails = @(
    "G-MCGE", "G-MCGF", "G-MCGG", "G-MCGH", "G-MCGI", "G-MCGJ", "G-MCGK", "G-MCGL", "G-MCGM", "G-MCGO", "G-MCGP", "G-MCGR", "G-MCGS", "G-MCGT", "G-MCGU", "G-MCGV", "G-MCGW", "G-MCGX", "G-MCGY", "G-MCGZ"
)

# Define the colors for different types of highlights.
$colors = @{
    Police       = @{ Background = 'DarkBlue';  Foreground = 'White' }
    AirAmbulance = @{ Background = 'DarkGreen'; Foreground = 'White' }
    Coastguard   = @{ Background = 'Magenta';   Foreground = 'White' }
    Tracked      = @{ Background = 'Yellow';    Foreground = 'Black' }
    OldAircraft  = @{ Background = 'Black';     Foreground = 'DarkGray' }
    Emergency    = @{ Background = 'Red';       Foreground = 'White' }
}

# MAIN SCRIPT

# Loop indefinitely to refresh the data.
while ($true) {
    try {
        # Fetch the data from the web service.
        $request = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 5

        # Clear the console for a clean display on each refresh.
        Clear-Host

        # Get the current timestamp for the "Last updated" message.
        $timestamp = Get-Date -Format "HH:mm:ss"

		# Dosplay banner
		Write-Host ""
		Write-Host " ########################"
		Write-Host " # ADSB Terminal Screen #"
		Write-Host " #=      by M6DJY      =#"
		Write-Host " ########################"
		Write-Host ""
		Write-Host ""

        # Check if the 'aircraft' property exists and has data.
        if ($null -ne $request.aircraft -and $request.aircraft.Count -gt 0) {
            
            # Sort data by the specified field.
            $sortedAircraft = $request.aircraft | Sort-Object -Property $sortProperty

            # Limit the number of results if resultLimit is greater than 0
            if ($resultLimit -gt 0) {
                $sortedAircraft = $sortedAircraft | Select-Object -First $resultLimit
            }

            # Table output
			
            # Check if any aircraft have active emergency status. If not, don't display column
            $showEmergencyColumn = $sortedAircraft.Where({$_.emergency -and $_.emergency -ne 'none'}, 'First')

            # Define column properties and fixed widths for alignment.
            $columnsList = [System.Collections.Generic.List[object]]::new(@(
                @{Name='icao';       Expression={param($item) $item.hex}; Width=6},
                @{Name='Call';       Expression={param($item) $item.flight}; Width=8},
                @{Name='Tail';       Expression={param($item) $item.r}; Width=6},
                @{Name='Type';       Expression={param($item) $item.desc}; Width=19},
                @{Name='Alt';        Expression={param($item) $item.alt_baro}; Width=5},
                @{Name='Dist';       Expression={param($item) if ($null -ne $item.r_dst) {"$([Math]::Round($item.r_dst))nm"}}; Width=6},
                @{Name='Seen';       Expression={
                                        param($item)
                                        if ($null -ne $item.seen) {
                                            if ($item.seen -gt 0 -and $item.seen -lt 1) {
                                                "<1s"
                                            } else {
                                                "$([Math]::Round($item.seen))s"
                                            }
                                        }
                                    }; Width=4},
                @{Name='Sqwk';       Expression={param($item) $item.squawk}; Width=4},
                @{Name='Flags';      Expression={
                                        param($item)
                                        if ($policeTails -contains $item.r) { "POLICE" }
                                        elseif ($airambTails -contains $item.r) { "AIRAMB" }
                                        elseif ($coastTails -contains $item.r) { "COAST" }
                                        elseif ($highlightedTails -contains $item.r) { "TRACKD" } 
                                        else {
                                            switch ($item.dbFlags) {
                                                1 { "MILAIR" }
                                                2 { "INTRST" }
                                                4 { "PIA" }
                                                8 { "LADD" }
                                                default { "" }
                                            }
                                        }
                                    }; Width=6}
            ))

            # If an emergency is detected, insert the Emergency column after the Sqwk column.
            if ($showEmergencyColumn) {
                $sqwkIndex = $columnsList.FindIndex({$args[0].Name -eq 'Sqwk'})
                if ($sqwkIndex -ne -1) {
                    $emergencyColumn = @{Name='Emergency';  Expression={param($item) $item.emergency}; Width=10}
                    $columnsList.Insert($sqwkIndex + 1, $emergencyColumn)
                }
            }
            
            # Final columns list for processing.
            $columns = $columnsList.ToArray()

            # 2. Print Headers (Left-aligned for readability)
            foreach ($column in $columns) {
                Write-Host -NoNewline ($column.Name.PadRight($column.Width) + " ")
            }
            Write-Host "" # Newline

            # 3. Print Header Separator
            foreach ($column in $columns) {
                Write-Host -NoNewline ("-".PadRight($column.Width, "-") + " ")
            }
            Write-Host "" # Newline

            # 4. Print Data Rows
            foreach ($aircraft in $sortedAircraft) {
                # Define emergency squawk codes and ANSI escape codes for blinking
                $emergencySquawks = @('7500', '7600', '7700')
                $esc = "$([char]27)"
                $blinkOn = "$esc[5m"
                $blinkOff = "$esc[25m"

                # --- Determine Row Highlighting ---
                $rowBgColor = $host.UI.RawUI.BackgroundColor
                $rowFgColor = $host.UI.RawUI.ForegroundColor
                $isEmergency = $emergencySquawks -contains $aircraft.squawk

                if ($isEmergency) {
                    $rowBgColor = $colors.Emergency.Background
                    $rowFgColor = $colors.Emergency.Foreground
                }
                elseif ($policeTails -contains $aircraft.r) {
                    $rowBgColor = $colors.Police.Background
                    $rowFgColor = $colors.Police.Foreground
                }
                elseif ($airambTails -contains $aircraft.r) {
                    $rowBgColor = $colors.AirAmbulance.Background
                    $rowFgColor = $colors.AirAmbulance.Foreground
                }
                elseif ($coastTails -contains $aircraft.r) {
                    $rowBgColor = $colors.Coastguard.Background
                    $rowFgColor = $colors.Coastguard.Foreground
                }
                elseif ($highlightedTails -contains $aircraft.r) {
                    $rowBgColor = $colors.Tracked.Background
                    $rowFgColor = $colors.Tracked.Foreground
                }
                elseif ($aircraft.seen -gt $refreshRate) {
                    $rowBgColor = $colors.OldAircraft.Background
                    $rowFgColor = $colors.OldAircraft.Foreground
                }
                
                # If it's an emergency, turn on blinking for the whole row
                if ($isEmergency) {
                    Write-Host -NoNewline $blinkOn
                }

                foreach ($column in $columns) {
                    # Invoke the expression scriptblock, passing the current aircraft object as an argument.
                    $value = & $column.Expression $aircraft
                    $valueString = if ($null -ne $value) { $value.ToString() } else { "" }
                    
                    # Truncate the string if it's longer than the column width to maintain alignment.
                    if ($valueString.Length -gt $column.Width) {
                        $valueString = $valueString.Substring(0, $column.Width)
                    }
                    
                    # Align certain columns to the left, and all others to the right.
                    if ($column.Name -eq 'Type' -or $column.Name -eq 'Emergency') {
                        $paddedValue = $valueString.PadRight($column.Width)
                    } else {
                        $paddedValue = $valueString.PadLeft($column.Width)
                    }

                    # Write the padded value with the calculated colors
                    Write-Host -NoNewline $paddedValue -ForegroundColor $rowFgColor -BackgroundColor $rowBgColor
                    
                    # Add a space for padding between columns, with the same background color
                    Write-Host -NoNewline " " -BackgroundColor $rowBgColor
                }
                
                # If blinking was turned on, turn it off to not affect subsequent lines.
                if ($isEmergency) {
                    Write-Host -NoNewline $blinkOff
                }

                Write-Host "" # Newline for the next aircraft
            }
        }
        else {
            Write-Host "No aircraft data currently available."
        }

        # Display status information.
        Write-Host "" # Add a blank line for spacing
        Write-Host "Last updated at $timestamp from" $siteHost
		Write-Host "Refreshing in" $refreshRate "seconds..."

    }
    catch {
        # Handle errors, such as network issues or timeouts.
        Clear-Host
        Write-Warning "Failed to retrieve data at $(Get-Date -Format "HH:mm:ss")."
        Write-Warning "Error: $($_.Exception.Message)"
        Write-Host "Retrying in 10 seconds..."
    }

    # Wait for the specified time before the next refresh.
    Start-Sleep -Seconds $refreshRate
}
