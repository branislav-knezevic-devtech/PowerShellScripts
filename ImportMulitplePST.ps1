#change path to location where the .pst files are
$filepath="\\\\pademocas2\c$\temp\vkaminski\vkaminski"
$items=get-childitem -path $filepath
foreach($item in $items){
$location=$filepath+"\"+$item.Name
#set appropriate -mailbox and -TargetRootFolder
New-mailboximportrequest -mailbox Lucretia.sangalli -filepath $location -TargetRootFolder "VKaminski"}