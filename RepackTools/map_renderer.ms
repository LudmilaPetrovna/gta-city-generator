delete $*
clearListener()
clearUndoBuffer()
deleteAllChangeHandlers()
gc()

renderWidth=768
renderHeight=768

meditMaterials[7].diffuseMap = Bitmaptexture fileName:@"Z:\camera-calibration-patterns\xor-numbered.png"
meditMaterials[7].selfIllumAmount = 61

b=Box lengthsegs:1 widthsegs:1 heightsegs:1 length:6000.0 width:6000.0 height:1.0 mapcoords:on pos:[0,0,0]
b.material=meditMaterials[7]

cam=Freecamera fov:45 targetDistance:160 pos:[0,0,10000]
viewport.setCamera cam
cam.pos=[0,0,10000]
cam.rotation=(quat 0 0 0 1)
cam.baseObject.targetDistance = 10000.0
cam.fov = 173.9 -- for 160 target
cam.fov = 33.3985 -- for 10000 target
cam.orthoProjection =true

devider=2.0
devider=12.0
dev_int=devider as integer

cam.baseObject.targetDistance = 10000.0/devider
animationRange=(interval 0f ((pow devider 2)-1))
view_size=6000.0/devider
offset_size=(6000.0-view_size)/2.0

-- for 2
cam.pos=[-1500,1500,10000]
cam.pos=[1500,-1500,10000]

cam.pos=[-2250,2250,10000]
cam.pos=[-2250+1500,2250,10000]

pow 2 3

for w=1 to dev_int do(
	for q=1 to dev_int do(
		at time ((q-1)+(w-1)*dev_int) animate on (
			cam.pos=[-offset_size+(q-1)*view_size,offset_size-(w-1)*view_size,10000]
		)
	)
)
