<#
 .SYNOPSIS
  Displays a visual representation of a calendar.

.DESCRIPTION
  Displays a visual representation of a calendar. This function supports multiple months
  and lets you highlight specific date ranges or days.

.PARAMETER Start
  The first month to display.

.PARAMETER End
  The last month to display.

.PARAMETER FirstDayOfWeek
  The day of the month on which the week begins.

.PARAMETER HighlightDay
  Specific days (numbered) to highlight. Used for date ranges like (25..31).
  Date ranges are specified by the Windows PowerShell range syntax. These dates are
  enclosed in square brackets.

.PARAMETER HighlightDate
  Specific days (named) to highlight. These dates are surrounded by asterisks.

.EXAMPLE
   # Show a default display of this month.
   Show-Calendar

.EXAMPLE
   # Display a date range.
   Show-Calendar -Start "March, 2010" -End "May, 2010"

.EXAMPLE
   # Highlight a range of days.
   Show-Calendar -HighlightDay (1..10 + 22) -HighlightDate "2008-12-25"
#>
function Show-Calendar {
    param(
        [datetime] $Start = [datetime]::Today,
        [datetime] $End = $Start,
        $FirstDayOfWeek,
        [int[]] $HighlightDay,
        [string[]] $HighlightDate = [datetime]::Today.ToString('yyyy-MM-dd')
        )
    
    ## Determine the first day of the start and end months.
    $Start = New-Object DateTime $Start.Year,$Start.Month,1
    $End = New-Object DateTime $End.Year,$End.Month,1
    
    ## Convert the highlighted dates into real dates.
    [datetime[]] $HighlightDate = [datetime[]] $HighlightDate
    
    ## Retrieve the DateTimeFormat information so that the
    ## calendar can be manipulated.
    ## Clone it: the current culture's format object is read-only.
    $dateTimeFormat  = (Get-Culture).DateTimeFormat.Clone()
    if($FirstDayOfWeek)
    {
        $dateTimeFormat.FirstDayOfWeek = $FirstDayOfWeek
    }
    
    $currentDay = $Start
    
    ## Process the requested months.
    while($Start -le $End)
    {
        ## Return to an earlier point in the function if the first day of the month
        ## is in the middle of the week.
        while($currentDay.DayOfWeek -ne $dateTimeFormat.FirstDayOfWeek)
        {
            $currentDay = $currentDay.AddDays(-1)
        }
    
    ## Prepare to store information about this date range.
        $currentWeek = New-Object PsObject
        $dayNames = @()
        $weeks = @()
    
    ## Continue processing dates until the function reaches the end of the month.
        ## The function continues until the week is completed with
        ## days from the next month.
        while(($currentDay -lt $Start.AddMonths(1)) -or
            ($currentDay.DayOfWeek -ne $dateTimeFormat.FirstDayOfWeek))
        {
            ## Determine the day names to use to label the columns.
            $dayName = "{0:ddd}" -f $currentDay
            if($dayNames -notcontains $dayName)
            {
                $dayNames += $dayName
            }
    
    ## Pad the day number for display, highlighting if necessary.
            $displayDay = " {0,2} " -f $currentDay.Day
    
    ## Determine whether to highlight a specific date.
            if($HighlightDate)
            {
                $compareDate = New-Object DateTime $currentDay.Year,
                    $currentDay.Month,$currentDay.Day
                if($HighlightDate -contains $compareDate)
                {
                    $displayDay = "*" + ("{0,2}" -f $currentDay.Day) + "*"
                }
            }
    
    ## Otherwise, highlight as part of a date range.
            ## Only days of the month being drawn count (not the padding
            ## days from neighbouring months), and they can be in any order.
            if($HighlightDay -and ($currentDay.Month -eq $Start.Month) -and
                ($HighlightDay -contains $currentDay.Day))
            {
                $displayDay = "[" + ("{0,2}" -f $currentDay.Day) + "]"
            }
    
    ## Add the day of the week and the day of the month as note properties.
            $currentWeek | Add-Member NoteProperty $dayName $displayDay
    
    ## Move to the next day of the month.
            $currentDay = $currentDay.AddDays(1)
    
    ## If the function reaches the next week, store the current week
            ## in the week list and continue.
            if($currentDay.DayOfWeek -eq $dateTimeFormat.FirstDayOfWeek)
            {
                $weeks += $currentWeek
                $currentWeek = New-Object PsObject
            }
        }
    
    ## Format the weeks as a table.
        $calendar = $weeks | Format-Table $dayNames -AutoSize | Out-String
    
    ## Add a centered header.
        $width = ($calendar.Split("`n") | Measure-Object -Maximum Length).Maximum
        $header = "{0:MMMM yyyy}" -f $Start
        $padding = " " * (($width - $header.Length) / 2)
        $displayCalendar = " `n" + $padding + $header + "`n " + $calendar
        $displayCalendar.TrimEnd()
    
    ## Move to the next month.
        $Start = $Start.AddMonths(1)
    
    }
    }
    Export-ModuleMember -Function Show-Calendar