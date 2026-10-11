# The module autoloads when this repo's profile is in use; importing by
# $PSScriptRoot also makes this file runnable on its own, from any folder.
Import-Module (Join-Path $PSScriptRoot 'MyfirstPsScript.psm1') -Force

# Basic usage - shows current month
Show-Calendar

# Show a specific date range
Show-Calendar -Start "January, 2024" -End "March, 2024"

# Highlight specific days (will be shown in [brackets])
Show-Calendar -HighlightDay (1..5) # Highlights days 1-5

# Highlight specific dates (will be shown with *asterisks*)
Show-Calendar -HighlightDate "2024-01-01","2024-01-15"

# Combine multiple parameters
Show-Calendar -Start "January, 2024" `
             -End "February, 2024" `
             -HighlightDay (1..5) `
             -HighlightDate "2024-01-25" `
             -FirstDayOfWeek "Monday"