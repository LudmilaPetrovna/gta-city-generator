delete $*
clearListener()
clearUndoBuffer()
deleteAllChangeHandlers()
gc()

actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
actionMan.executeAction 0 "554"  -- Views: Viewport Visual Style Consistent Colors
viewport.SetRenderLevel #flat
viewport.SetShowEdgeFaces true
file=openFile (@"z:\cache\nodes_simple.txt") mode:"rt" encoding:#utf8

undo off (
	while not (eof file); do (
		
dline=readLine file
fields=filterString dline "\t"
pos=[fields[1] as float, fields[2] as float, fields[3] as float]
rad=fields[4] as float
		if rad<1 then rad=2
Sphere pos:pos radius:rad segments:5
		
		
	)
	)
		close file
free file
