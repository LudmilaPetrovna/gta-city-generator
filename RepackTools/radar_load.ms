delete $radar*
clearListener()
clearUndoBuffer()
deleteAllChangeHandlers()
gc()

images_root=@"T:\Gta-Micro\Projects\ColorRadar\newcol"

undo off (
for w=1 to 12 do(
for q=1 to 12 do(
	id=((q-1)+(w-1)*12) as integer
filename=images_root+"\\frames"+(formattedPrint id format:"04u")+".png"
view_size=6000.0/12.0
offset_size=(6000.0-view_size)/2.0

p=Plane length:view_size width:view_size
p.pos=[-offset_size+(q-1)*view_size,offset_size-(w-1)*view_size,0]
p.name="radar_"+(id as string)+"_"

m=StandardMaterial()
m.diffusemap=bitmapTexture filename:filename
m.twoSided=on
m.selfIllumAmount=100
showTextureMap m true
p.material=m
	
		
		
	)
	)
)