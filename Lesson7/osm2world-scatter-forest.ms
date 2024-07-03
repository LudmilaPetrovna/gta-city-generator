

fn getNewTree=(
tree=Foliage CanopyMode:0 GenUV:on ShowTrunk:on ShowBranches:on ShowLeaves:on clipu:0 clipv:0 clipw:1 cliph:1 Jitter:1 color1:(color 0 0 0) color2:(color 255 255 255) phase:0 levels:3 thresholdHigh:1 shaderType:1 sampler:3 effect:0
tree.LevelOfDetail = 0
tree.height = 30
tree.density = 0.4
tree.Pruning = 0.5
tree.seed =random 0 1000000
tree.ShowFruit = off
tree.ShowRoots = off
tree.ShowFlowers = off
return tree
)

fn scatterTrees numTrees forestPolygon=(
local q
local bb = nodeLocalBoundingBox forestPolygon
local testpoint
local testray
local intersection
local notValid

for q=1 to numTrees do(
notValid=true
tries=10
	
while notValid and tries>0 do(
testpoint=[random bb[1].x bb[2].x, random bb[1].y bb[2].y, 0]
tries=tries-1
testray = ray testpoint [0, 0, -1]
print testray
intersection = intersectRay forestPolygon testray
print ("planting tree "+(q as string)+", point "+testpoint as string+", "+(intersection as string))
if intersection != undefined then notValid=false
)
local tree=getNewTree()
tree.pos=testpoint

)
)

delete $Foliage*
scatterTrees 100 $
