delete $*
clearListener()
clearUndoBuffer()
--resetMaxFile() #noPrompt

filename=@"z:\cache\vgnboigashot15.col"

m=mesh numverts:0 numfaces:0

surfaces=#()

for q=1 to 256 do (
	surfaces[q]=(random [0,0,0] [255,255,255])
)

meditMaterials[1]=Standard diffuseMap:(Vertex_Color())
showTextureMap meditMaterials[1] true
showHWTextureMap meditMaterials[1] true

fn util_enable_vc obj=(
obj.showVertexColors=on
obj.material=meditMaterials[1]
meshop.setNumMaps obj 1 keep:false
)
	
fn util_colorize obj col=(
local q
convertToMesh obj
util_enable_vc obj
meshop.setNumCPVVerts obj 1
setVertColor obj 1 col
for q=1 to (meshop.getNumFaces obj) do (
	setVCFace obj q [1,1,1]
)
update obj
)


fn col_load_shadow filename=(
	local f=fopen filename "rb"
	fseek f 108 #seek_set
	local count_shadow_faces=readLong f #unsigned
	local off_verts=readLong f #unsigned
	local off_faces=readLong f #unsigned
	local verts_count=(off_faces-off_verts)/6
	local m=mesh numverts:verts_count numfaces:count_shadow_faces
	fseek f (off_faces+4) #seek_set
	local q
	local v1,v2,v3,unused
	local vert_max=0
	for q=1 to count_shadow_faces do (
		v1=readShort f #unsigned
		v2=readShort f #unsigned
		v3=readShort f #unsigned
		unused=readShort f #unsigned
		meshop.createPolygon m #(v1+1,v2+1,v3+1)
	)
	fseek f (off_verts+4) #seek_set
	for q=1 to verts_count do (
		v1=readShort f #signed
		v2=readShort f #signed
		v3=readShort f #signed
		setVert m q [1.0*v1/128.0,1.0*v2/128.0,1.0*v3/128.0]
	)
	fclose f
	update m
	return m
)

fn col_load_collision filename=(
	local f=fopen filename "rb"
	fseek f 72 #seek_set
	local count_spheres=readShort f #unsigned
	local count_boxes=readShort f #unsigned
	local count_faces=readShort f #unsigned
	local unused=readShort f #unsigned -- lines and padding
	unused=readLong f #unsigned -- flags (have collision, have shadow)
	local off_spheres=readLong f #unsigned
	local off_boxes=readLong f #unsigned
	local off_lines=readLong f #unsigned
	local off_verts=readLong f #unsigned
	local off_faces=readLong f #unsigned
	local off_planes=readLong f #unsigned
	if off_lines>0 or off_planes>0 then (
		print "very strange file, sent it to me!"
		exit
	)

	local q
	local v1,v2,v3
	local ev1,ev2,ev3
	local vert_max=0
	local rad
	
	local verts_count=(off_faces-off_verts)/6
	local m=mesh numverts:verts_count numfaces:count_faces
	util_enable_vc m


	meshop.setNumCPVVerts m 256

	for q=1 to 256 do (
			setVertColor m q surfaces[q]
	)
	
	fseek f (off_verts+4) #seek_set
	for q=1 to verts_count do (
		v1=readShort f #signed
		v2=readShort f #signed
		v3=readShort f #signed
		setVert m q [1.0*v1/128.0,1.0*v2/128.0,1.0*v3/128.0]
	)
	fseek f (off_faces+4) #seek_set

	for q=1 to count_faces do (
		v1=readShort f #unsigned
		v2=readShort f #unsigned
		v3=readShort f #unsigned
		mat=readByte f #unsigned
		light=readByte f #unsigned
		setFace m q (v1+1) (v2+1) (v3+1)
		setVCFace m q [mat+1,mat+1,mat+1]
	)
	update m
	
		-- add balls
	fseek f (off_spheres+4) #seek_set
	for q=1 to count_spheres do (
		v1=readFloat f
		v2=readFloat f
		v3=readFloat f
		rad=readFloat f
		mat=readByte f #unsigned
		flag=readByte f #unsigned
		bright=readByte f #unsigned
		light=readByte f #unsigned
		s=Sphere pos:[v1,v2,v3] radius:rad segments:25
		util_colorize s surfaces[mat+1]
		attach m s
	)
	-- add boxes
	fseek f (off_boxes+4) #seek_set
	for q=1 to count_boxes do (
		v1=readFloat f
		v2=readFloat f
		v3=readFloat f
		ev1=readFloat f
		ev2=readFloat f
		ev3=readFloat f
		mat=readByte f #unsigned
		flag=readByte f #unsigned
		bright=readByte f #unsigned
		light=readByte f #unsigned
		b=box pos:[0.5,0.5,0] length:1.0 width:1.0 height:1.0
		b.pivot=[0,0,0]
		b.pos=[v1,v2,v3]
		b.width=ev1-v1
		b.length=ev2-v2
		b.height=ev3-v3
		util_colorize b surfaces[mat+1]
		attach m b
			
	)
	
	fclose f
	update m
	return m
)

fn col_get_info filename=(
	-- we need: shadow mesh exists? collisions exists?
	local has_shadow=false
	local has_collision=false
	
	local f=fopen filename "rb"
	if f==undefined then (
		print ("Can't open file! Check path: "+filename)
		return ""
	)
	fseek f 0 #seek_set 
	
	local version=ReadLong f #unsigned
	
	-- check signature "COL3"
	if version!=860639043 then (
		print "Only COL3 supported!"
		return ""
	)
	
	--go to flags field
	fseek f 80 #seek_set
	local flags=ReadLong f #unsigned
	print flags
	if (bit.and flags 2)>0 then (
		
		fseek f 72 #seek_set
		local count_spheres=readShort f #unsigned
		local count_boxes=readShort f #unsigned
		local count_faces=readShort f #unsigned
		if count_spheres > 0 or  count_boxes > 0 or  count_faces > 0 then (
			print ("here " + (count_spheres as string)+" spheres")
			has_collision=true
		)
	)
	
	if (bit.and flags 16)>0 then (
		fseek f 108 #seek_set
		local count_shadow_faces=readLong f #unsigned
		local off_verts=readLong f #unsigned
		local off_faces=readLong f #unsigned
		if count_shadow_faces>0 and off_verts>0 and off_faces>0 then (
			has_shadow=true
		)
	)
	fclose f
	return #(has_collision,has_shadow)
)


col_get_info filename
col_load_collision filename
--col_load_shadow filename
