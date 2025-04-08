delete $occl*
clearListener()
clearUndoBuffer()
deleteAllChangeHandlers()
gc()

--actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
--actionMan.executeAction 0 "554"  -- Views: Viewport Visual Style Consistent Colors
viewport.SetRenderLevel #flat
viewport.SetShowEdgeFaces true
file=openFile (@"z:\cache\occl-all.txt") mode:"rt" encoding:#utf8
--file=openFile (@"z:\cache\ipl_decoded\occl\occluveg.txt") mode:"rt" encoding:#utf8
linenum=1
undo off (
	while not (eof file); do (
		
dline=readLine file
fields=filterString dline ", "
pos=[fields[1] as float, fields[2] as float, fields[3] as float]
dim=[fields[4] as float, fields[5] as float, fields[6] as float]
rot=fields[7] as float
b=Box lengthsegs:1 widthsegs:1 heightsegs:1 length:dim.x width:dim.y height:dim.z mapcoords:on
rotate b (angleaxis (rot+90) [0,0,1])
b.pos=pos
b.name="occl_"+(linenum as string)+"_";

linenum+=1
		
		
	)
	)
		close file
free file
