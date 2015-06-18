----------------------------------------------------------------
-- Copyright (c) 2010-2011 Zipline Games, Inc. 
-- All Rights Reserved. 
-- http://getmoai.com
----------------------------------------------------------------

MOAIDebugLines.setStyle ( MOAIDebugLines.PROP_MODEL_BOUNDS, 2, 1, 1, 1 )
MOAIDebugLines.setStyle ( MOAIDebugLines.PROP_WORLD_BOUNDS, 1, 0.5, 0.5, 0.5 )

-- just for readability
local RECT_XMIN		= 1
local RECT_YMIN		= 2
local RECT_XMAX		= 3
local RECT_YMAX		= 4

local sprites		= {}

function loadAsset(basename)
	json = MOAIJsonParser.decode ( MOAIFileSystem.loadFile ( basename .. '.json' ))
	assert ( json )

	-- local CHUNKSIZE_X = math.min(json.chunkSize, json.width)
	-- local CHUNKSIZE_Y = math.min(json.chunkSize, json.height)
	local CHUNKSIZE_X = json.chunkSize
	local CHUNKSIZE_Y = json.chunkSize

	local WIDTH_IN_CHUNKS = math.ceil ( json.width / CHUNKSIZE_X )

	local ANCHOR_X = 0
	local ANCHOR_Y = 0

	if (json.anchor) then
		ANCHOR_X = json.anchor.x
		ANCHOR_Y = json.anchor.y
	end
	
	local uvRects		= {}
	local screenRects	= {}
	local materialIDs	= {}

	for i, tile in ipairs ( json.tiles ) do

		local cropRect	= tile.cropRect
		local padRect	= tile.paddingRect

		local xOff = ANCHOR_X + cropRect [ RECT_XMIN ] - padRect [ RECT_XMIN ]
		local yOff = ANCHOR_Y + cropRect [ RECT_YMIN ] - padRect [ RECT_YMIN ]

		local screenSub, screenSubWidth, screenSubHeight = MOAIGfxQuadListDeck2D.subdivideRect (

			CHUNKSIZE_X,
			CHUNKSIZE_Y,

			cropRect [ RECT_XMIN ],
			cropRect [ RECT_YMIN ],
			cropRect [ RECT_XMAX ],
			cropRect [ RECT_YMAX ]
		)

		table.insert ( sprites, {
			base	= #materialIDs + 1,
			size	= #screenSub,
		})
		
		for i, screenRect in ipairs ( screenSub ) do

			print ( screenRect [ RECT_XMIN ], screenRect [ RECT_YMIN ], screenRect [ RECT_XMAX ], screenRect [ RECT_YMAX ])
			local xChunk = math.floor ( screenRect [ RECT_XMIN ] / CHUNKSIZE_X )
			local yChunk = math.floor ( screenRect [ RECT_YMIN ] / CHUNKSIZE_Y )

			local uvRect = {
				[ RECT_XMIN ]	= ( screenRect [ RECT_XMIN ] - ( xChunk * CHUNKSIZE_X )) / CHUNKSIZE_X,
				[ RECT_YMIN ]	= ( screenRect [ RECT_YMIN ] - ( yChunk * CHUNKSIZE_Y )) / CHUNKSIZE_Y,
				[ RECT_XMAX ]	= ( screenRect [ RECT_XMAX ] - ( xChunk * CHUNKSIZE_X )) / CHUNKSIZE_X,
				[ RECT_YMAX ]	= ( screenRect [ RECT_YMAX ] - ( yChunk * CHUNKSIZE_Y )) / CHUNKSIZE_Y,
			}

			screenRect [ RECT_XMIN ] = screenRect [ RECT_XMIN ] - xOff
			screenRect [ RECT_YMIN ] = screenRect [ RECT_YMIN ] - yOff
			screenRect [ RECT_XMAX ] = screenRect [ RECT_XMAX ] - xOff
			screenRect [ RECT_YMAX ] = screenRect [ RECT_YMAX ] - yOff

			screenRect [ RECT_YMIN ] = screenRect [ RECT_YMIN ] * -1
			screenRect [ RECT_YMAX ] = screenRect [ RECT_YMAX ] * -1

			-- print ( screenRect [ RECT_XMIN ], screenRect [ RECT_YMIN ], screenRect [ RECT_XMAX ], screenRect [ RECT_YMAX ])

			local materialID = ( xChunk + ( yChunk * WIDTH_IN_CHUNKS )) + 1

			table.insert ( uvRects, uvRect )
			table.insert ( screenRects, screenRect )
			table.insert ( materialIDs, materialID )
		end
	end

	gfxQuadListDeck = MOAIGfxQuadListDeck2D.new ()

	-- we're going to init the textures with filenames to enable reloading and
	-- prevent caching of image data
	gfxQuadListDeck:reserveMaterials ( 2 )

	local loadAsBitmap = function ( filename )

		local image = MOAIImage.new ()
		image:load ( filename )
		image:resize ( 128, 128 )
		image:simpleThreshold ( 1, 1, 1, 0.5 )
		image:convert ( MOAIImage.COLOR_FMT_A_1 )
		return image
	end

	local maxCols = math.ceil(json.width / CHUNKSIZE_X)
	local maxRows = math.ceil(json.height / CHUNKSIZE_Y)

	local fileCount = maxCols * maxRows

	local extension = ".png"
	-- reload the images one by one and generate bitmaps from their alpha
	-- ideally, these will be pre-generated and stored alongside the png's
	for i=1, fileCount do

		local zeroBasedIdx = i - 1
		local imageFilename = basename .. "." .. zeroBasedIdx .. extension

		-- Make sure the file exists!  If it does not, MOAITexture.load fails silently.
		assert(MOAIFileSystem.checkFileExists(imageFilename), "Texture._loadChunk: missing file '" .. imageFilename .. "'")
		print("load", imageFilename)
		gfxQuadListDeck:setTexture ( i, imageFilename )
		gfxQuadListDeck:setHitMask ( i, loadAsBitmap ( imageFilename ))
		gfxQuadListDeck:setHitMaskThreshold ( i, 0, 0, 0, 1 )
	end

	local totalRects = #materialIDs

	gfxQuadListDeck:reserveUVQuads ( totalRects)
	gfxQuadListDeck:reserveQuads ( totalRects )
	gfxQuadListDeck:reservePairs ( totalRects )

	for i = 1, totalRects do

		local uvRect = uvRects [ i ]
		local screenRect = screenRects [ i ]

		print ( 'uv rect', i, uvRect [ RECT_XMIN ], uvRect [ RECT_YMIN ], uvRect [ RECT_XMAX ], uvRect [ RECT_YMAX ])
		print ( 'screen rect', i, " --", screenRect [ RECT_XMIN ], screenRect [ RECT_YMIN ], screenRect [ RECT_XMAX ], screenRect [ RECT_YMAX ])

		gfxQuadListDeck:setUVRect ( i,
			uvRect [ RECT_XMIN ],
			uvRect [ RECT_YMIN ],
			uvRect [ RECT_XMAX ],
			uvRect [ RECT_YMAX ]
		)

		gfxQuadListDeck:setRect ( i,
			screenRect [ RECT_XMIN ],
			screenRect [ RECT_YMIN ],
			screenRect [ RECT_XMAX ],
			screenRect [ RECT_YMAX ]
		)

		gfxQuadListDeck:setPair ( i, i, i, materialIDs [ i ])
	end

	gfxQuadListDeck:reserveLists ( #sprites )
	for i, sprite in ipairs ( sprites ) do
		gfxQuadListDeck:setList ( i, sprite.base, sprite.size )
	end

	----------------------------------------------------------------

	prop = MOAIProp2D.new ()
	prop:setDeck ( gfxQuadListDeck )
	prop:setHitGranularity ( MOAIProp.HIT_TEST_FINE )
	layer:insertProp ( prop )
end

index = 1

function onMouseEvent ( down, delta )

	if down == true then

		local x, y = MOAIInputMgr.device.pointer:getLoc ()
		x, y = layer:wndToWorld ( x, y )
		-- if prop:inside ( x, y ) then

			if delta > 0 then
				index = ( index % #sprites ) + 1
			elseif delta < 0 then
				index = index - 1
				index = index <= 0 and #sprites or index
			end

			prop:setIndex ( index )

			label:setString ( tostring(index) )

		-- end
	end
end

MOAIInputMgr.device.mouseLeft:setCallback ( function ( down ) onMouseEvent ( down, 1 ) end )
MOAIInputMgr.device.mouseRight:setCallback ( function ( down ) onMouseEvent ( down, -1 ) end )

MOAISim.openWindow ( "test", 1024, 1024 )

viewport = MOAIViewport.new ()
viewport:setSize ( 1024, 1024 )
viewport:setScale ( 1024, 1024 )

layer = MOAILayer2D.new ()
layer:setViewport ( viewport )
MOAISim.pushRenderPass ( layer )


font = MOAIFont.new ()
font:loadFromTTF ( 'r/arial-rounded.TTF' )

label = MOAITextLabel.new ()
label:setString ( '' )
label:setFont ( font )
label:setTextSize ( 32 )
label:setYFlip ( true )
label:setAlignment ( MOAITextBox.CENTER_JUSTIFY, MOAITextBox.BASELINE_JUSTIFY )
label:setLoc ( 0, -220 )
layer:insertProp ( label )

-- animation with horizontal tiles in texture files
-- loadAsset('r/running_julius')

-- animation with vertical tiles in texture files
-- loadAsset('r/worry_bear_run_left')

-- single frame smallest than the tile size
-- loadAsset('r/worry_bear_run_left')

-- single, small rectangle (smaller than chunk size)
-- loadAsset('r/rect')

-- single, large rectangle (bigger than chunk size, uses non-square blocks)
-- a 720x720 image, with a 512 input chunkSize, will be cut in 4 pieces (from top left to bottom right)
-- the conditioner works like this: 720 % 512 = 208. What's the nearest upper pow2 for 208? 256
-- 512x512     256x512
-- 512x256     256x256
loadAsset('r/rect2')


