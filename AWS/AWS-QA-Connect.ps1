$env:PSModulePath = $env:PSModulePath + ";C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell"
Set-AWSCredentials -AccessKey AKIAJSG2IOYDHTDEG7DA -SecretKey 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 -StoreAs Branislav.admin-QA
Set-DefaultAWSRegion eu-central-1 -verbose
