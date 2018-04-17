for /f %%i in ('powershell.exe -Command "[guid]::NewGuid().ToString()"') do set guid=%%i
for /f %%i in ('powershell.exe -Command "(Get-ChildItem -Path Cert:\LocalMachine\My).Thumbprint"') do set thumbprint=%%i
netsh http add sslcert ipport=0.0.0.0:8000 certhash=%thumbprint% appid={%guid%}