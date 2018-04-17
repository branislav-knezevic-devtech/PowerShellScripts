# List all users which are members of the Global Address list

$filter = (Get-GlobalAddressList 'Default Global Address List').RecipientFilter
Get-Recipient -ResultSize unlimited -RecipientPreviewFilter $filter | Select-Object Name,PrimarySmtpAddress, Phone | Sort-Object name