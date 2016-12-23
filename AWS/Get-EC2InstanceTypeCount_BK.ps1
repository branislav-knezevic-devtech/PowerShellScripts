Function Get-EC2InstanceTypeCount_BK
{
    <# 
        .SYNOPSIS 
            This advanced function will return the AWS Instance Types used in an AWS account. .DESCRIPTION This advanced function will return the AWS Instance Types used in an AWS account. It will return a name property, such as t2.medium, m4.large, etc., and a Count property. The results are sorted on the count, as they are produced using the Sort-Object cmdlet. .EXAMPLE PS > Get-EC2InstanceTypeCount
            This example returns the EC2 Instance Types and how many of each are being used.
 
            Count Name
            ----- ----
            32    t2.medium
            18    t2.micro
             6    c3.large
             6    m4.large
             7    t2.small
             2    r3.large
             4    r3.xlarge
             5    g2.2xlarge
             5    t2.large
             1    t2.nano
 
        .EXAMPLE
            PS > Get-EC2InstanceTypeCount | Sort-Object -Property Name
            This example returns the EC2 Instance Types and how many of each are being used, sorted by Name.
 
        .EXAMPLE
            PS > Get-EC2InstanceTypeCount | Where-Object -Property Name -like *large*
            This example returns the EC2 Instance Types that include the term "large" in the Name property.
 
            Count Name
            ----- ----
                6 c3.large                 
                6 m4.large                 
                2 r3.large                 
                4 r3.xlarge                
                5 g2.2xlarge               
                5 t2.large
 
        .NOTES
            NAME: Get-EC2InstanceTypeCount
            AUTHOR: Tommy Maynard
            COMMENTS: --
            LASTEDIT: 09/27/2016
            VERSION 1.0
    
    #>
    [CmdletBinding()]
    Param ()
 
    BEGIN 
    {
        $Instances = Get-EC2Instance
    }
 
    PROCESS 
    {
        Foreach ($Instance in $Instances) 
        {
            [array]$Types += $Instance.Instances.InstanceType
        }
        $Types | Group-Object -NoElement
    }
 
    END {}
}