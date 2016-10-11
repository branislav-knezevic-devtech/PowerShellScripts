$groupname = (Get-EC2SecurityGroup -GroupName 'group-name','group-name').GroupId
$instanceid = (Get-EC2Instance -InstanceId 'instance id').instances.instanceid
Edit-EC2InstanceAttribute -InstanceId $instanceid -Group $groupname
#all groups must be listed or the command will overrite the existing ones