#Starts new t2.nano instance and adds it to Developer access security group
$Image = Get-EC2ImageByName -name 'windows_2012r2_base'
New-EC2Instance -ImageId $Image.ImageId -KeyName devtech -InstanceType t2.nano -Region Eu-Central-1 -Verbose -SecurityGroupId sg-8964d4e1

$Image = Get-EC2ImageByName -name 'windows_2008r2_base'
New-EC2Instance -ImageId $Image.ImageId -KeyName devtech -InstanceType t2.nano -Region Eu-Central-1 -Verbose -SecurityGroupId sg-8964d4e1

$Image = Get-EC2ImageByName -name 'windows_2008rtm_base'
New-EC2Instance -ImageId $Image.ImageId -KeyName devtech -InstanceType t2.nano -Region Eu-Central-1 -Verbose -SecurityGroupId sg-8964d4e1