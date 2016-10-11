$env:PSModulePath = $env:PSModulePath + ";C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell"
# old ceredentials
# Set-AWSCredentials -AccessKey AKIAIHOSD7ETH4OGJ6TQ -SecretKey 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 -StoreAs Branislav.admin-QA
Set-AWSCredentials -AccessKey AKIAJNNBC5XG3D5JEM5A -SecretKey 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 -StoreAs Branislav.admin-QA
Set-DefaultAWSRegion eu-central-1 -verbose

# if credentials stop working check key on AWS and file in C:\Users\branislav.knezevic\.aws