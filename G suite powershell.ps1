customerID = C025tbhc1 # it can be used as my_customer
(Get-GACustomers -CustomerKey my_customer).id
UserKey = ime.prezime
UserId = me

#############

Get-GAUser -UserKey bojan.popovic | fl

Get-GAUser -all | fl

Get-GAUser goran.manot themigrationmagic.com | gm

Get-GAGroup themigrationmagic.com 

Get-GShellDomain
Get-GShellUser | fl
Get-GAdminSettingsAdminSecondaryEmail -Domain "themigrationmagic.com"
Invoke-GShellScopeManager

##############

Get-GAdminSettingsCountryCode -Domain themigrationmagic.com

help New-GACalendar -Examples
Get-GCalendarAcl -All
(Get-GACustomers -CustomerKey my_customer).id
help Get-GAAsp
Get-GACalendar -All
help New-GCalendar -Examples

New-GCalendar -CalendarBody PowerShell_calendar
help Get-GGmailLabel -Examples
Get-GGmailLabel -UserId 112483620493402600420 -all | where {$_.type -like "system"} 

Get-GShellDomain
Get-GADomain