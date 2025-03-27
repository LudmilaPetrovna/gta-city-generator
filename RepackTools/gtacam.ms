clearListener()
clearUndoBuffer()
gc()

deleteAllChangeHandlers()

gamecam=getnodebyname "gamecam"
lastsum=""

if(gamecam==undefined)then(
gamecam=Targetcamera fov:75
gamecam.pos=[0,0,0]
gamecam.target=targetObject ()
gamecam.target.pos=[0,-1,0]
gamecam.name="gamecam"
)


fn gamecamPositionWrite=(
	local sum=gamecam.pos.x+gamecam.pos.y+gamecam.pos.z+gamecam.target.pos.x+gamecam.target.pos.y+gamecam.target.pos.z+gamecam.fov
	if(lastsum==sum)then (
		return 1
	)
	lastsum=sum
	local out=(gamecam.pos.x as string)+";"+
	(gamecam.pos.y as string)+";"+
	(gamecam.pos.z as string)+";"+
	(gamecam.target.pos.x as string)+";"+
	(gamecam.target.pos.y as string)+";"+
	(gamecam.target.pos.z as string)+";"+
	(gamecam.fov as string)+";"+(sum as string)
	local f=createFile @"v:\gta\filerpc\gamecam.txt" -- encoding:#utf8 writeBOM:false
	format out to:f
	close f
	free f
	print out
)

gamecamPositionWrite()


--when transform gamecam changes do(
--	gamecamPositionWrite()
--)
when parameters gamecam change fov do(
	gamecamPositionWrite()
)

when select $* change do(
	if selection[1]!=undefined do(
		gamecam.target.pos=selection[1].pos
		--macros.run "Lights and Cameras" "Camera_CreateFromView"
		selection=#(gamecam)
	)
)


fn syncCam=(
--	macros.run "Lights and Cameras" "Camera_CreateFromView"
)

if theTimer == undefined then (    
    theTimer = dotNetObject "System.Windows.Forms.Timer"
)

theTimer.stop()
--dotnet.addEventHandler theTimer "tick" syncCam
--theTimer.interval = 10
--theTimer.start()
