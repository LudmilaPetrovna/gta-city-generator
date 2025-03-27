delete $*
clearListener()
clearUndoBuffer()
deleteAllChangeHandlers()
gc()


--resetMaxFile() #noPrompt
--macros.run "Lights and Cameras" "Camera_CreateFromView"

filename=@"z:\cache\vgnboigashot15.col"

if false then(
pano=Sphere radius:33 segs:200 mapcoords:on
pano.pos=[-2254,207,47]
pano.material=meditMaterials[7]

panocam=Targetcamera fov:45
panocam.pos=pano.pos
panocam.target=targetObject ()
panocam.target.pos=pano.pos+[10,0,0]

meditMaterials[1].selfIllumAmount = 100
meditMaterials[1].opacity = 51
)

surfaces=#()
for q=1 to 256 do (
	surfaces[q]=(random [0,0,0] [255,255,255])
)

-- 0: (1 in max) DEFAULT
surfaces[1]=[55, 124, 234]
-- 1: (2 in max) TARMAC
surfaces[2]=[69, 122, 236]
-- 2: (3 in max) TARMAC_FUCKED
surfaces[3]=[166, 3, 123]
-- 3: (4 in max) TARMAC_REALLYFUCKED
surfaces[4]=[68, 78, 1]
-- 4: (5 in max) PAVEMENT
surfaces[5]=[162, 160, 128]
-- 5: (6 in max) PAVEMENT_FUCKED
surfaces[6]=[29, 112, 136]
-- 6: (7 in max) GRAVEL
surfaces[7]=[158, 153, 16]
-- 7: (8 in max) FUCKED_CONCRETE
surfaces[8]=[35, 60, 56]
-- 8: (9 in max) PAINTED_GROUND
surfaces[9]=[246, 101, 249]
-- 9: (10 in max) GRASS_SHORT_LUSH
surfaces[10]=[61, 208, 205]
-- 10: (11 in max) GRASS_MEDIUM_LUSH
surfaces[11]=[212, 7, 22]
-- 11: (12 in max) GRASS_LONG_LUSH
surfaces[12]=[56, 220, 127]
-- 12: (13 in max) GRASS_SHORT_DRY
surfaces[13]=[208, 121, 3]
-- 13: (14 in max) GRASS_MEDIUM_DRY
surfaces[14]=[0, 33, 233]
-- 14: (15 in max) GRASS_LONG_DRY
surfaces[15]=[165, 143, 237]
-- 15: (16 in max) GOLFGRASS_ROUGH
surfaces[16]=[59, 228, 208]
-- 16: (17 in max) GOLFGRASS_SMOOTH
surfaces[17]=[98, 196, 77]
-- 17: (18 in max) STEEP_SLIDYGRASS
surfaces[18]=[36, 174, 111]
-- 18: (19 in max) STEEP_CLIFF
surfaces[19]=[41, 4, 134]
-- 19: (20 in max) FLOWERBED
surfaces[20]=[241, 34, 247]
-- 20: (21 in max) MEADOW
surfaces[21]=[226, 191, 105]
-- 21: (22 in max) WASTEGROUND
surfaces[22]=[250, 208, 41]
-- 22: (23 in max) WOODLANDGROUND
surfaces[23]=[232, 143, 117]
-- 23: (24 in max) VEGETATION
surfaces[24]=[55, 207, 254]
-- 24: (25 in max) MUD_WET
surfaces[25]=[156, 110, 42]
-- 25: (26 in max) MUD_DRY
surfaces[26]=[52, 217, 95]
-- 26: (27 in max) DIRT
surfaces[27]=[133, 101, 152]
-- 27: (28 in max) DIRTTRACK
surfaces[28]=[194, 101, 177]
-- 28: (29 in max) SAND_DEEP
surfaces[29]=[55, 48, 87]
-- 29: (30 in max) SAND_MEDIUM
surfaces[30]=[69, 73, 129]
-- 30: (31 in max) SAND_COMPACT
surfaces[31]=[108, 247, 137]
-- 31: (32 in max) SAND_ARID
surfaces[32]=[86, 99, 129]
-- 32: (33 in max) SAND_MORE
surfaces[33]=[23, 192, 152]
-- 33: (34 in max) SAND_BEACH
surfaces[34]=[85, 85, 141]
-- 34: (35 in max) CONCRETE_BEACH
surfaces[35]=[37, 195, 63]
-- 35: (36 in max) ROCK_DRY
surfaces[36]=[92, 84, 140]
-- 36: (37 in max) ROCK_WET
surfaces[37]=[131, 11, 204]
-- 37: (38 in max) ROCK_CLIFF
surfaces[38]=[252, 86, 182]
-- 38: (39 in max) WATER_RIVERBED
surfaces[39]=[39, 199, 51]
-- 39: (40 in max) WATER_SHALLOW
surfaces[40]=[222, 156, 41]
-- 40: (41 in max) CORNFIELD
surfaces[41]=[14, 210, 153]
-- 41: (42 in max) HEDGE
surfaces[42]=[254, 16, 229]
-- 42: (43 in max) WOOD_CRATES
surfaces[43]=[9, 2, 34]
-- 43: (44 in max) WOOD_SOLID
surfaces[44]=[153, 71, 64]
-- 44: (45 in max) WOOD_THIN
surfaces[45]=[189, 115, 85]
-- 45: (46 in max) GLASS
surfaces[46]=[134, 236, 47]
-- 46: (47 in max) GLASS_WINDOWS_LARGE
surfaces[47]=[237, 219, 130]
-- 47: (48 in max) GLASS_WINDOWS_SMALL
surfaces[48]=[18, 197, 68]
-- 48: (49 in max) EMPTY1
surfaces[49]=[99, 225, 133]
-- 49: (50 in max) EMPTY2
surfaces[50]=[97, 68, 213]
-- 50: (51 in max) GARAGE_DOOR
surfaces[51]=[221, 160, 142]
-- 51: (52 in max) THICK_METAL_PLATE
surfaces[52]=[24, 98, 18]
-- 52: (53 in max) SCAFFOLD_POLE
surfaces[53]=[18, 139, 194]
-- 53: (54 in max) LAMP_POST
surfaces[54]=[79, 146, 171]
-- 54: (55 in max) METAL_GATE
surfaces[55]=[188, 90, 121]
-- 55: (56 in max) METAL_CHAIN_FENCE
surfaces[56]=[199, 115, 182]
-- 56: (57 in max) GIRDER
surfaces[57]=[147, 133, 91]
-- 57: (58 in max) FIRE_HYDRANT
surfaces[58]=[147, 174, 5]
-- 58: (59 in max) CONTAINER
surfaces[59]=[153, 234, 143]
-- 59: (60 in max) NEWS_VENDOR
surfaces[60]=[25, 199, 134]
-- 60: (61 in max) WHEELBASE
surfaces[61]=[116, 145, 154]
-- 61: (62 in max) CARDBOARDBOX
surfaces[62]=[127, 82, 25]
-- 62: (63 in max) PED
surfaces[63]=[30, 172, 74]
-- 63: (64 in max) CAR
surfaces[64]=[147, 220, 135]
-- 64: (65 in max) CAR_PANEL
surfaces[65]=[45, 66, 134]
-- 65: (66 in max) CAR_MOVINGCOMPONENT
surfaces[66]=[143, 9, 141]
-- 66: (67 in max) TRANSPARENT_CLOTH
surfaces[67]=[122, 154, 28]
-- 67: (68 in max) RUBBER
surfaces[68]=[88, 87, 73]
-- 68: (69 in max) PLASTIC
surfaces[69]=[156, 33, 66]
-- 69: (70 in max) TRANSPARENT_STONE
surfaces[70]=[2, 56, 110]
-- 70: (71 in max) WOOD_BENCH
surfaces[71]=[69, 109, 236]
-- 71: (72 in max) CARPET
surfaces[72]=[30, 84, 187]
-- 72: (73 in max) FLOORBOARD
surfaces[73]=[59, 152, 41]
-- 73: (74 in max) STAIRSWOOD
surfaces[74]=[145, 87, 28]
-- 74: (75 in max) P_SAND
surfaces[75]=[203, 45, 209]
-- 75: (76 in max) P_SAND_DENSE
surfaces[76]=[115, 172, 202]
-- 76: (77 in max) P_SAND_ARID
surfaces[77]=[96, 171, 150]
-- 77: (78 in max) P_SAND_COMPACT
surfaces[78]=[73, 54, 168]
-- 78: (79 in max) P_SAND_ROCKY
surfaces[79]=[152, 143, 73]
-- 79: (80 in max) P_SANDBEACH
surfaces[80]=[217, 245, 238]
-- 80: (81 in max) P_GRASS_SHORT
surfaces[81]=[85, 117, 170]
-- 81: (82 in max) P_GRASS_MEADOW
surfaces[82]=[167, 106, 49]
-- 82: (83 in max) P_GRASS_DRY
surfaces[83]=[77, 63, 55]
-- 83: (84 in max) P_WOODLAND
surfaces[84]=[116, 109, 211]
-- 84: (85 in max) P_WOODDENSE
surfaces[85]=[245, 159, 107]
-- 85: (86 in max) P_ROADSIDE
surfaces[86]=[244, 54, 91]
-- 86: (87 in max) P_ROADSIDEDES
surfaces[87]=[38, 76, 197]
-- 87: (88 in max) P_FLOWERBED
surfaces[88]=[137, 0, 123]
-- 88: (89 in max) P_WASTEGROUND
surfaces[89]=[138, 58, 222]
-- 89: (90 in max) P_CONCRETE
surfaces[90]=[63, 130, 104]
-- 90: (91 in max) P_OFFICEDESK
surfaces[91]=[215, 53, 131]
-- 91: (92 in max) P_711SHELF1
surfaces[92]=[176, 70, 210]
-- 92: (93 in max) P_711SHELF2
surfaces[93]=[29, 122, 46]
-- 93: (94 in max) P_711SHELF3
surfaces[94]=[217, 150, 16]
-- 94: (95 in max) P_RESTUARANTTABLE
surfaces[95]=[153, 122, 45]
-- 95: (96 in max) P_BARTABLE
surfaces[96]=[181, 184, 201]
-- 96: (97 in max) P_UNDERWATERLUSH
surfaces[97]=[237, 209, 170]
-- 97: (98 in max) P_UNDERWATERBARREN
surfaces[98]=[220, 64, 44]
-- 98: (99 in max) P_UNDERWATERCORAL
surfaces[99]=[3, 181, 209]
-- 99: (100 in max) P_UNDERWATERDEEP
surfaces[100]=[200, 247, 164]
-- 100: (101 in max) P_RIVERBED
surfaces[101]=[125, 255, 96]
-- 101: (102 in max) P_RUBBLE
surfaces[102]=[216, 158, 153]
-- 102: (103 in max) P_BEDROOMFLOOR
surfaces[103]=[237, 85, 79]
-- 103: (104 in max) P_KIRCHENFLOOR
surfaces[104]=[161, 254, 194]
-- 104: (105 in max) P_LIVINGRMFLOOR
surfaces[105]=[128, 122, 136]
-- 105: (106 in max) P_CORRIDORFLOOR
surfaces[106]=[88, 250, 189]
-- 106: (107 in max) P_711FLOOR
surfaces[107]=[135, 149, 42]
-- 107: (108 in max) P_FASTFOODFLOOR
surfaces[108]=[235, 59, 52]
-- 108: (109 in max) P_SKANKYFLOOR
surfaces[109]=[33, 58, 145]
-- 109: (110 in max) P_MOUNTAIN
surfaces[110]=[73, 81, 59]
-- 110: (111 in max) P_MARSH
surfaces[111]=[41, 20, 37]
-- 111: (112 in max) P_BUSHY
surfaces[112]=[244, 6, 162]
-- 112: (113 in max) P_BUSHYMIX
surfaces[113]=[92, 205, 225]
-- 113: (114 in max) P_BUSHYDRY
surfaces[114]=[169, 97, 121]
-- 114: (115 in max) P_BUSHYMID
surfaces[115]=[255, 61, 23]
-- 115: (116 in max) P_GRASSWEEFLOWERS
surfaces[116]=[210, 87, 135]
-- 116: (117 in max) P_GRASSDRYTALL
surfaces[117]=[224, 202, 188]
-- 117: (118 in max) P_GRASSLUSHTALL
surfaces[118]=[53, 205, 238]
-- 118: (119 in max) P_GRASSGRNMIX
surfaces[119]=[16, 58, 23]
-- 119: (120 in max) P_GRASSBRNMIX
surfaces[120]=[121, 0, 182]
-- 120: (121 in max) P_GRASSLOW
surfaces[121]=[63, 100, 137]
-- 121: (122 in max) P_GRASSROCKY
surfaces[122]=[113, 159, 149]
-- 122: (123 in max) P_GRASSSMALLTREES
surfaces[123]=[159, 237, 100]
-- 123: (124 in max) P_DIRTROCKY
surfaces[124]=[216, 78, 163]
-- 124: (125 in max) P_DIRTWEEDS
surfaces[125]=[164, 223, 232]
-- 125: (126 in max) P_GRASSWEEDS
surfaces[126]=[206, 188, 115]
-- 126: (127 in max) P_RIVEREDGE
surfaces[127]=[158, 8, 251]
-- 127: (128 in max) P_POOLSIDE
surfaces[128]=[101, 126, 46]
-- 128: (129 in max) P_FORESTSTUMPS
surfaces[129]=[56, 24, 64]
-- 129: (130 in max) P_FORESTSTICKS
surfaces[130]=[137, 100, 50]
-- 130: (131 in max) P_FORRESTLEAVES
surfaces[131]=[96, 219, 135]
-- 131: (132 in max) P_DESERTROCKS
surfaces[132]=[176, 198, 15]
-- 132: (133 in max) P_FORRESTDRY
surfaces[133]=[132, 251, 3]
-- 133: (134 in max) P_SPARSEFLOWERS
surfaces[134]=[100, 124, 36]
-- 134: (135 in max) P_BUILDINGSITE
surfaces[135]=[203, 82, 127]
-- 135: (136 in max) P_DOCKLANDS
surfaces[136]=[209, 242, 144]
-- 136: (137 in max) P_INDUSTRIAL
surfaces[137]=[246, 94, 100]
-- 137: (138 in max) P_INDUSTJETTY
surfaces[138]=[22, 255, 162]
-- 138: (139 in max) P_CONCRETELITTER
surfaces[139]=[227, 154, 100]
-- 139: (140 in max) P_ALLEYRUBISH
surfaces[140]=[207, 189, 183]
-- 140: (141 in max) P_JUNKYARDPILES
surfaces[141]=[155, 17, 234]
-- 141: (142 in max) P_JUNKYARDGRND
surfaces[142]=[134, 119, 104]
-- 142: (143 in max) P_DUMP
surfaces[143]=[218, 141, 76]
-- 143: (144 in max) P_CACTUSDENSE
surfaces[144]=[120, 103, 55]
-- 144: (145 in max) P_AIRPORTGRND
surfaces[145]=[44, 134, 112]
-- 145: (146 in max) P_CORNFIELD
surfaces[146]=[217, 113, 42]
-- 146: (147 in max) P_GRASSLIGHT
surfaces[147]=[82, 31, 131]
-- 147: (148 in max) P_GRASSLIGHTER
surfaces[148]=[96, 52, 158]
-- 148: (149 in max) P_GRASSLIGHTER2
surfaces[149]=[181, 0, 160]
-- 149: (150 in max) P_GRASSMID1
surfaces[150]=[204, 184, 178]
-- 150: (151 in max) P_GRASSMID2
surfaces[151]=[35, 239, 129]
-- 151: (152 in max) P_GRASSDARK
surfaces[152]=[242, 19, 221]
-- 152: (153 in max) P_GRASSDARK2
surfaces[153]=[206, 236, 41]
-- 153: (154 in max) P_GRASSDIRTMIX
surfaces[154]=[9, 110, 22]
-- 154: (155 in max) P_RIVERBEDSTONE
surfaces[155]=[255, 81, 108]
-- 155: (156 in max) P_RIVERBEDSHALLOW
surfaces[156]=[239, 245, 221]
-- 156: (157 in max) P_RIVERBEDWEEDS
surfaces[157]=[98, 160, 126]
-- 157: (158 in max) P_SEAWEED
surfaces[158]=[151, 7, 131]
-- 158: (159 in max) DOOR
surfaces[159]=[229, 91, 100]
-- 159: (160 in max) PLASTICBARRIER
surfaces[160]=[161, 47, 47]
-- 160: (161 in max) PARKGRASS
surfaces[161]=[50, 4, 198]
-- 161: (162 in max) STAIRSSTONE
surfaces[162]=[74, 114, 23]
-- 162: (163 in max) STAIRSMETAL
surfaces[163]=[184, 28, 179]
-- 163: (164 in max) STAIRSCARPET
surfaces[164]=[105, 144, 75]
-- 164: (165 in max) FLOORMETAL
surfaces[165]=[191, 158, 78]
-- 165: (166 in max) FLOORCONCRETE
surfaces[166]=[0, 219, 186]
-- 166: (167 in max) BIN_BAG
surfaces[167]=[92, 248, 205]
-- 167: (168 in max) THIN_METAL_SHEET
surfaces[168]=[97, 224, 56]
-- 168: (169 in max) METAL_BARREL
surfaces[169]=[235, 58, 142]
-- 169: (170 in max) PLASTIC_CONE
surfaces[170]=[32, 179, 79]
-- 170: (171 in max) PLASTIC_DUMPSTER
surfaces[171]=[247, 220, 68]
-- 171: (172 in max) METAL_DUMPSTER
surfaces[172]=[4, 155, 126]
-- 172: (173 in max) WOOD_PICKET_FENCE
surfaces[173]=[234, 96, 230]
-- 173: (174 in max) WOOD_SLATTED_FENCE
surfaces[174]=[47, 19, 157]
-- 174: (175 in max) WOOD_RANCH_FENCE
surfaces[175]=[224, 79, 119]
-- 175: (176 in max) UNBREAKABLE_GLASS
surfaces[176]=[188, 189, 154]
-- 176: (177 in max) HAY_BALE
surfaces[177]=[241, 32, 175]
-- 177: (178 in max) GORE
surfaces[178]=[177, 59, 239]
-- 178: (179 in max) RAILTRACK
surfaces[179]=[90, 22, 210]


meditMaterials[1]=Standard diffuseMap:(Vertex_Color())
meditMaterials[1].twoSided = on
meditMaterials[1].selfIllumAmount = 69
showTextureMap meditMaterials[1] true
showHWTextureMap meditMaterials[1] false

fn util_enable_vc obj=(
meshop.setNumMaps obj 1 keep:false
obj.showVertexColors=on
)
	
fn util_colorize obj col=(
local q
convertToMesh obj
util_enable_vc obj
meshop.setNumCPVVerts obj 1
setVertColor obj 1 col
obj.showVertexColors=on
--setVertColor obj 1 [255,0,0]
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
	local m=undefined
	
	if verts_count>0 and count_faces>0 then (
	m=mesh numverts:verts_count numfaces:count_faces
	util_enable_vc m

--print ("creating object with verts: "+(verts_count as string)+", faces: "+(count_faces as string))
	meshop.setNumCPVVerts m 256

	for q=1 to 256 do (
			setVertColor m q surfaces[q]
	)
	vert_max=0
	fseek f (off_faces+4) #seek_set

	for q=1 to count_faces do (
		v1=readShort f #unsigned
		v2=readShort f #unsigned
		v3=readShort f #unsigned
		mat=readByte f #unsigned
		light=readByte f #unsigned
		setFace m q (v1+1) (v2+1) (v3+1)
		setVCFace m q [mat+1,mat+1,mat+1]
		if vert_max<v1 then vert_max=v1
		if vert_max<v2 then vert_max=v2
		if vert_max<v3 then vert_max=v3
	)
	vert_max=vert_max+1
	fseek f (off_verts+4) #seek_set
	for q=1 to vert_max do (
		v1=readShort f #signed
		v2=readShort f #signed
		v3=readShort f #signed
		setVert m q [1.0*v1/128.0,1.0*v2/128.0,1.0*v3/128.0]
	)
	update m
)

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
		if m==undefined then (
			m=s
		) else (
		attach m s
		)
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
		--b.width=ev1-v1
		--b.length=ev2-v2
		--b.height=ev3-v3
		scale b [ev1-v1,ev2-v2,ev3-v3]
		util_colorize b surfaces[mat+1]
		if m==undefined then (
			m=b
		) else (
		attach m b
		)
	)
	
	fclose f

	m.showVertexColors=on
	m.material=meditMaterials[1]
--	m.name="collision"
	m.pivot=[0,0,0]

	update m
	return m
)
fn col_load_collision_faces filename=(
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
	
	local m=undefined
	local verts_count=(off_faces-off_verts)/6
	local verts=#()

	if verts_count>0 and count_faces>0 then (

	fseek f (off_verts+4) #seek_set
	for q=1 to verts_count do (
		v1=readShort f #signed
		v2=readShort f #signed
		v3=readShort f #signed
		verts[q]=[1.0*v1/128.0,1.0*v2/128.0,1.0*v3/128.0]
	)

	fseek f (off_faces+4) #seek_set

	for q=1 to count_faces do (
	m=mesh numverts:3 numfaces:1
	util_enable_vc m
	meshop.setNumCPVVerts m 1
	m.showVertexColors=on
	m.material=meditMaterials[1]
		v1=readShort f #unsigned
		v2=readShort f #unsigned
		v3=readShort f #unsigned
		mat=readByte f #unsigned
		light=readByte f #unsigned
		setFace m 1 1 2 3
		setVertColor m 1 surfaces[mat+1]
		setVCFace m 1 [1,1,1]
	setVert m 1 verts[v1+1]
	setVert m 2 verts[v2+1]
	setVert m 3 verts[v3+1]
	m.name="mat_"+(mat as string)+"_li"+(light as string)+"_"
	)
	
	update m
)
	
	fclose f

	return 0
)

fn col_get_info filename do_bounding=(
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
	if version!=860639043 and version!=843861827 then (
		print "Only COL2/COL3 supported!"
		return #(false,false,undefined)
	)
	
	--go to flags field
	fseek f 80 #seek_set
	local flags=ReadLong f #unsigned
	if (bit.and flags 2)>0 then (
		
		fseek f 72 #seek_set
		local count_spheres=readShort f #unsigned
		local count_boxes=readShort f #unsigned
		local count_faces=readShort f #unsigned
		if count_spheres > 0 or  count_boxes > 0 or  count_faces > 0 then (
			--print ("here " + (count_spheres as string)+" spheres")
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
	
	if do_bounding then (

		fseek f 32 #seek_set 
		v1=readFloat f
		v2=readFloat f
		v3=readFloat f
		ev1=readFloat f
		ev2=readFloat f
		ev3=readFloat f
		
		b=box pos:[0.5,0.5,0] length:1.0 width:1.0 height:1.0
		b.pivot=[0,0,0]
		scale b [ev1-v1,ev2-v2,ev3-v3]
		b.pos=[v1,v2,v3]
		
		b.boxmode = on
		b.xray = on
		b.showVertexColors = off
		b.renderable = off
		freeze b
		
		v1=readFloat f
		v2=readFloat f
		v3=readFloat f
		ev1=readFloat f
		s=Sphere pos:[v1,v2,v3] radius:ev1 segments:10
		s.xray = on
		s.showVertexColors = off
		s.renderable = off
		freeze s


	)		
	fclose f
	return #(has_collision,has_shadow)
)

fn col_load filename=(
local info=col_get_info filename false
local obj1
local obj2
	
if info[2] then (
--obj1=col_load_shadow filename
)

if info[1] then (
obj2=col_load_collision filename
)

if obj1==undefined and obj2!=undefined then (
	return obj2
)

if obj1!=undefined and obj2!=undefined then (
	attach obj1 obj2
)
return obj1
)

badfile="z:/cache/col_unpacked/gta3/vegepart/tree_hipoly09b.col"
badfile="z:/cache/col_unpacked/gta3/barriers/gate_autor.col"
badfile="z:/cache/col_unpacked/gta3/las2_2/bchcostrd6v_las2.col"
badfile="z:/cache/col_unpacked/gta3/sfs_2/bbgroundbitc_sfs.col"
badfile="z:/cache/col_unpacked/gta3/sfe_1/masts1_sfe.col"
--col_get_info badfile true
--col_load_collision_faces badfile
--col_load badfile

if true then (

-- load file list
file=openFile (@"z:\cache\map.txt") mode:"rt" encoding:#utf8

tt=200000
undo off (
root=Sphere pos:[0,0,0] radius:1 segments:10
util_colorize root [0,0,0]
util_enable_vc root
meshop.setNumCPVVerts root 256
root.showVertexColors = on
for q=1 to 256 do (
	setVertColor root q surfaces[q]
)
	linenum=1
	
	while not (eof file); do (
dline=readLine file
fields=filterString dline "\t"
	tt=tt-1
	if tt<0 then exit
--print fields
id=fields[1] as integer
filename=@"z:\cache\"+fields[2]
pos_x=fields[3] as float
pos_y=fields[4] as float
pos_z=fields[5] as float
	
rot_x=fields[6] as float
rot_y=fields[7] as float
rot_z=fields[8] as float
rot_w=fields[9] as float
nodename="obj_"+fields[1]

if mainref!=undefined then (
	if mainref.name!=nodename then (
	delete mainref
		mainref=undefined
	)
)
if mainref==undefined then (
	mainref=col_load filename
	if mainref==undefined then (
		mainref=Dummy pos:[0,0,0]
	)
	mainref.name=nodename
)

obj=instance mainref
obj.pos=[0,0,0]
obj.rotation=(quat rot_x rot_y -rot_z rot_w)
obj.pos=[pos_x,pos_y,pos_z]
obj.showVertexColors=on
obj.name=nodename+"_"+(linenum as string)
cl=classof obj
if cl==Editable_mesh then (
--attach root obj
)

linenum+=1
if mod linenum 123==0 then print linenum

)

print "Map creation complete, enabling \"undo\""
)

close file
free file

)

