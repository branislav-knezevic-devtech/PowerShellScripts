BEGIN {}
PROCESS 
{
    $Regions = Get-AWSRegion
    ForEach ( $Region in $Regions ) 
    {
        try 
        {
            $RegionName = $Region.Region
            #Set-DefaultAWSRegion -Region $RegionName -ErrorAction Stop
            if ( (Get-EC2Instance -Region $RegionName) -eq $null )
            {
                $noInstances = "There are no instances in region: $RegionName"
            }
            else
            {
                $Instances = Get-EC2Instance -Region $regionName
                $InstancesCount = $Instances.instances.Count
                foreach ($i in $Instances)
                {
                    #$InstanceState = 
                    $instanceDetail = (Get-EC2Instance $i).instances
                    $instanceProperties = @{ InstanceID = $instanceDetail.instanceID
                                             InstanceType = $instanceDetail.instanceType
                                             KeyName = $instanceDetail.keyname
                                             LaunchTime = $instanceDetail.launchTime
                                             InstanceState = ($instanceDetail).state.name }
                    Write-Output $instanceProperties `n -ErrorAction SilentlyContinue
                }
            }

        }
        catch
        {
            Write-Warning "AWS is having problems to connect to region $RegionName"
            $loggedError = $_
            # Write-Output "Connection has failed"
            Write-Output "LoggedError is:" $loggedError.exception.message
            Write-Output "Number of the line which contans the error:" $loggedError.invocationInfo.scriptLineNumber
            Write-Output "Line where the error occured:" $loggedError.invocationInfo.line
        }
        finally
        {
            if ( (Get-EC2Instance -Region $RegionName) -ne $null )
            {
                if ($InstancesCount -eq 1)
                {
                    Write-Output "$InstancesCount instance found in $RegionName"
                }
                else
                {
                    Write-Output "$InstancesCount instances found in $RegionName"
                }
                #Write-Output $InstanceProperties
            }
            Else
            {
                Write-Output $noInstances
            }
        }
    }
}
END {}

# script is failing in the properties part, it needs to be tested thre