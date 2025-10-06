max select none
delete $water_*
clearListener()
clearUndoBuffer()
deleteAllChangeHandlers()
gc()

DATAFILE=@"z:\water\water.dat"
water_sample=[-1474.6840,127.7405,-0.4584]
sphere pos:water_sample radius:10 segments:30 name:"water_sample" wirecolor:[255,0,0]

wf = openFile DATAFILE
n = 0
while not (eof wf) do (
dline = readline wf
data = filterString dline " 	"
n=n+1
--if n>200 then exit
if data.count<22 then continue

rcol=random [0, 0, 0] [255, 255, 255]
lpref="water_"+(n as string)+"_"

if data.count==22 do (
vert1=[data[1] as float, data[2] as float, data[3] as float]
vert2=[data[8] as float, data[9] as float, data[10] as float]
vert3=[data[15] as float, data[16] as float, data[17] as float]
flags=data[22] as integer
sphere pos:vert1 radius:5 segments:10 name:(lpref+"v1_") wirecolor:rcol
sphere pos:vert2 radius:5 segments:10 name:(lpref+"v2_") wirecolor:rcol
sphere pos:vert3 radius:5 segments:10 name:(lpref+"v3_") wirecolor:rcol
m=mesh numverts:3 numfaces:1 wirecolor:rcol pos:[0,0,0] showFrozenInGray:off castShadows:off receiveshadows:off name:(lpref+"poly_")
--m.material=mat
setVert m 1 vert1
setVert m 2 vert2
setVert m 3 vert3

meshop.createPolygon m #(3,2,1)	
update m
freeze m
)

if data.count==29 do (

vert1=[data[1] as float, data[2] as float, data[3] as float]
vert2=[data[8] as float, data[9] as float, data[10] as float]
vert3=[data[15] as float, data[16] as float, data[17] as float]
vert4=[data[22] as float, data[23] as float, data[24] as float]
flags=data[29] as integer

waterspeed_1=[data[4] as float, data[5] as float]
waterspeed_2=[data[11] as float, data[12] as float]
waterspeed_3=[data[18] as float, data[19] as float]
waterspeed_4=[data[25] as float, data[26] as float]
waves_1=[data[6] as float, data[7] as float]
waves_2=[data[13] as float, data[14] as float]
waves_3=[data[20] as float, data[21] as float]
waves_4=[data[27] as float, data[28] as float]
	

r1=waterspeed_1.x+waterspeed_1.y+10.0
r2=waterspeed_2.x+waterspeed_2.y+10.0
r3=waterspeed_3.x+waterspeed_3.y+10.0
r4=waterspeed_4.x+waterspeed_4.y+10.0
	
Cone pos:vert1 radius1:r1 radius2:0 height:(waves_1.y*100.0) heightsegs:1 capsegs:1 sides:10 mapcoords:off name:(lpref+"v1_") wirecolor:rcol
Cone pos:vert2 radius1:r2 radius2:0 height:(waves_2.y*100.0) heightsegs:1 capsegs:1 sides:10 mapcoords:off name:(lpref+"v2_") wirecolor:rcol
Cone pos:vert3 radius1:r3 radius2:0 height:(waves_3.y*100.0) heightsegs:1 capsegs:1 sides:10 mapcoords:off name:(lpref+"v3_") wirecolor:rcol
Cone pos:vert4 radius1:r4 radius2:0 height:(waves_4.y*100.0) heightsegs:1 capsegs:1 sides:10 mapcoords:off name:(lpref+"v4_") wirecolor:rcol
	
--sphere pos:vert1 radius:waterspeed_1.x segments:10 name:(lpref+"v1_") wirecolor:rcol
--sphere pos:vert2 radius:waterspeed_2.x segments:10 name:(lpref+"v2_") wirecolor:rcol
--sphere pos:vert3 radius:waterspeed_3.x segments:10 name:(lpref+"v3_") wirecolor:rcol
--sphere pos:vert4 radius:waterspeed_4.x segments:10 name:(lpref+"v4_") wirecolor:rcol

	
m=mesh numverts:4 numfaces:2 wirecolor:rcol pos:[0,0,0] showFrozenInGray:off castShadows:off receiveshadows:off name:(lpref+"poly_")
--m.material=mat
setVert m 1 vert1
setVert m 2 vert2
setVert m 3 vert3
setVert m 4 vert4

meshop.createPolygon m #(1,2,3)	
meshop.createPolygon m #(2,4,3)
update m
freeze m

if bit.and flags 1!=0 then m.renderable=on else m.renderable=off
if bit.and flags 2!=0 then m.xray=on else m.xray=off

)



)

close wf
free wf
