[system.reflection.assembly]::loadwithpartialname('Microsoft.VisualBAsic') | Out-Null
$computername = [Microsoft.Visualbasic.interaction]::inputbox('Enter a computer name','Computer?','localhost')

# $computername - variable which stores the data
# 'Enter a computer name' - prompt in the box
# 'Computer?' - title of the box
# 'localhost' - default value in the box (it is optional)