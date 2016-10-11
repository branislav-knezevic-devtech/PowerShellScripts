$B = 1..5
$B
$Elements = for ($i = 0; $i -le ($niz.Length - 1); $i += 2) {$niz[$i]}
foreach ($element in $elements) {$niz.SetValue("svaki drugi",$element)}

for ($i = 0; $i -le ($niz.Length - 1); $i += 2) {$niz.SetValue("Second",$i)}
$niz = @(1..10)
