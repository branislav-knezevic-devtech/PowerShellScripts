# save password as encrypted
	
Read-Host -Prompt "Enter your tenant password" -AsSecureString | ConvertFrom-SecureString | Out-File "d:\Credentials\Username.txt"


