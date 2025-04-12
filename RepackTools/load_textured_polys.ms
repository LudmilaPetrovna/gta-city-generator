delete $tms*
clearListener()
clearUndoBuffer()
deleteAllChangeHandlers()
gc()

--Sphere pos:[0,0,0] radius:1 segments:20 name:"center_" color:[0,0,0]
--Sphere pos:[0,20,0] radius:1 segments:20 name:"north_" color:[0,0,255]
--Sphere pos:[0,0,20] radius:1 segments:20 name:"top_" color:[255,0,0]



src_poly=@"z:\cache\poly.txt"
images_root=@"Z:\camera-calibration-patterns\"
images_root=@"Z:\"

file=openFile src_poly mode:"rt" encoding:#utf8


whitemat=Standard()
whitemat.Diffuse=color 255 255 255
whitemat.selfIllumAmount=100

undo off (
	while not (eof file); do (
		
dline=readLine file
fields=filterString dline ";"
local vert1=execute fields[1]
local vert2=execute fields[2]
local vert3=execute fields[3]
local vert4=execute fields[4]
local label=execute fields[5]
local texture=fields[6]
--Sphere pos:vert1 radius:.1 segments:12 name:"tms_debug_" material:whitemat
--Sphere pos:vert2 radius:.1 segments:12 name:"tms_debug_" material:whitemat
--Sphere pos:vert3 radius:.1 segments:12 name:"tms_debug_" material:whitemat
--Sphere pos:vert4 radius:.1 segments:12 name:"tms_debug_" material:whitemat

mat=Standard()
mat.diffusemap=bitmapTexture filename:(images_root+texture)
mat.selfIllumAmount=100
--mat.twoSided=on
showTextureMap mat true
meditMaterials[1]=mat
		
m=mesh numverts:4 numfaces:2
m.name="tms_plane_"+label+"_"
m.material=mat
setVert m 1 vert1
setVert m 2 vert2
setVert m 3 vert3
setVert m 4 vert4


meshop.createPolygon m #(1,3,2)	
meshop.createPolygon m #(1,4,3)
update m

meshop.setNumMaps m 2 keep:false
meshop.getMapSupport m 1
meshop.freeMapChannel m 1
meshop.makeMapPlanar m 1
meshop.setNumTVerts m 4

meshop.setMapVert m 1 1 [0,0,0]
meshop.setMapVert m 1 2 [0,1,0]
meshop.setMapVert m 1 3 [1,1,0]
meshop.setMapVert m 1 4 [1,0,0]


		
	)
	)
		close file
free file
