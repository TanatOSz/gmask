ctx1 = {}
ctx2 = {}
cnvs1 = {}
cnvs2 = {}
undoStack = []

debugging = on
disableDebugFor = ['animateBand', 'getMouse', 'updateMouse','drawBand', 'readSelection', 'writeSelection', 'startSelection', 'endSelection']
debug = (funcName, args...) ->
	if debugging and funcName not in disableDebugFor
		console.log(funcName, args)

##selection
origin = {'x':0, 'y':0}
selecting = no
gBand = {'x':0, 'y':0, 'w':0, 'h':0}
mouse = {'x':0, 'y':0}

readSelection = (band) ->
	debug('readSelection', band)
	ctx1.getImageData(band.x, band.y, band.w, band.h)

writeSelection = (band, imgData) ->
	debug('writeSelection', imgData, band.x, band.y)
	if (band.w isnt imgData.width) or (band.h isnt imgData.height)
		console.error("Dimension mismatch between band and ImageData")
	ctx1.putImageData(imgData, band.x, band.y)
	drawBand(band)

copySelection = ->
	copy =
		x: selection.x
		y: selection.y
		w: selection.w
		h: selection.h

updateMouse = (e) ->
	debug('updateMouse', e)
	if e.offsetX
		x = e.offsetX
		y = e.offsetY
	else if e.layerX
		x = e.layerX
		y = e.layerY
	mouse = {'x':x, 'y':y}

getMouse = ->
	debug('getMouse')
	{'x':mouse.x, 'y':mouse.y}

startSelection = (e) ->
	debug('startSelection', e)
	origin = getMouse()
	selecting = yes
	window.mozRequestAnimationFrame(animateBand)

endSelection = (e) ->
	debug('endSelection', e)
	selecting = no

animateBand = ->
	debug('animateBand')
	pos = getMouse()
	x1 = Math.min(origin.x, pos.x)
	x1 -= x1 % 8
	y1 = Math.min(origin.y, pos.y)
	y1 -= y1 % 8
	x2 = Math.max(origin.x, pos.x)
	x2 += 8 - (x2 % 8)
	if x2 > cnvs1.width
		x2 -= 8
	y2 = Math.max(origin.y, pos.y)
	y2 += 8 - (y2 % 8)
	if y2 > cnvs1.height
		y2 -= 8
	if x2 != x1 and y2 != y1
		gBand =
			x: x1
			y: y1
			w: x2 - x1
			h: y2 - y1
	if selecting
		drawBand(gBand)
		window.mozRequestAnimationFrame(animateBand)

drawBand = (band) ->
	debug('drawBand', band)
	ctx2.clearRect(0,0,cnvs2.width,cnvs2.height)
	ctx2.strokeRect(band.x, band.y, band.w, band.h)

## masks
# rotate RGB CCW (on RGB wheel)
rotateRGB = (band=gBand, isUndo=no) ->
	debug('rotateRGB', band, isUndo)
	imgData = readSelection(band)
	for i in [0 .. imgData.data.length-1] by 4
		rValue = imgData.data[i]
		gValue = imgData.data[i+1]
		bValue = imgData.data[i+2]
		# red -> green
		imgData.data[i] = gValue
		# green -> blue
		imgData.data[i+1] = bValue
		# blue -> red
		imgData.data[i+2] = rValue
	if not isUndo then undoStack.push({'band':band, 'filters':[rotateRGB, rotateRGB]})
	writeSelection(band,imgData)

#XOR 0x80
xor80 = (band=gBand, isUndo=no) ->
	debug('xor80', band, isUndo)
	imgData = readSelection(band)
	for i in [0 .. imgData.data.length-1]
		if i % 4 != 3
			imgData.data[i] ^= 128
	if not isUndo then undoStack.push({'band':band, 'filters':[xor80]})
	writeSelection(band,imgData)

#Flip up-down
flipud = (band=gBand, isUndo=no) ->
	debug('flipud',band,isUndo)
	imgData = readSelection(band)

#Flip left-right
fliplr = (band=gBand, isUndo=no) ->
	debug('fliplr',band,isUndo)
	imgData = readSelection(band)
	for i in [0 .. imgData.data.length-1] by (4 * imgData.width) #row
		for p in [0..(4*imgData.width)/2-1] by 4 #pixel
			for s in [0 .. 3] #subpixel
				temp = imgData.data[i+p+s]
				imgData.data[i+p+s] = imgData.data[i+(4*imgData.width-1)-(p+3)+s]
				imgData.data[i+(4*imgData.width-1)-(p+3)+s] = temp
	if not isUndo then undoStack.push({'band':band, 'filters':[fliplr]})
	writeSelection(band,imgData)

# Negative
negative = (band=gBand, isUndo=no) ->
	debug('negative', band, isUndo)
	imgData = readSelection(band)
	for i in [0 .. imgData.data.length-1] by 4
		rValue = imgData.data[i]
		gValue = imgData.data[i+1]
		bValue = imgData.data[i+2]
		imgData.data[i] = 255 - rValue
		imgData.data[i+1] = 255 - gValue
		imgData.data[i+2] = 255 - bValue
	if not isUndo then undoStack.push({'band':band,'filters':[negative]})
	writeSelection(band,imgData)

# Vertical Glass Blocks
vGlass = (band=gBand, isUndo=no) ->
	debug('vGlass', band, isUndo)
	imgData= readSelection(band)
	for i in [0 .. imgData.data.length-1] by (4 * 8)
		# hack to call slice on array-like object
		subpixelVals = Array.prototype.slice.call(imgData.data,i,i+32)
		for subpixelIdx in [0..31]
			# to preserve RGBA order
			# 28, 29, 30, 31, 24, 25, 26, 27 ...
			colEnd = 4*Math.ceil((32-subpixelIdx)/4)-1
			colIdx = colEnd - (3-(subpixelIdx%4))
			imgData.data[i+subpixelIdx] = subpixelVals[colIdx]
	if not isUndo then undoStack.push({'band':band,'filters':[vGlass]})
	writeSelection(band,imgData)

# Horizontal Glass Blocks
hGlass = (band=gBand, isUndo=no) ->
	debug('hGlass', band, isUndo)
	imgData= readSelection(band)
	for i in [0 .. imgData.data.length-1] by (4 * imgData.width * 8)
		rows = []
		for j in [0..7]
			rows.push( \
			Array.prototype.slice.call( \
			imgData.data
			, i+(j*4*imgData.width)
			, i+((j+1)*4*imgData.width)))
		for rowIdx in [rows.length-1..0]
			for subpixelIdx in [0..rows[rowIdx].length-1]
				imgData.data[i+((7-rowIdx)*4*imgData.width)+subpixelIdx] = rows[rowIdx][subpixelIdx]
	if not isUndo then undoStack.push({'band':band,'filters':[hGlass]})
	writeSelection(band,imgData)

# Win
win = (band=gBand, isUndo=no) ->
	debug('win', band, isUndo)
	if not isUndo then undoStack.push({'band':band,'filters':[win]})
	writeSelection(band,imgData)

# Meko+
mekoplus = (band=gBand, isUndo=no) ->
	debug('mekoplus', band, isUndo)
	if not isUndo then undoStack.push({'band':band,'filters':[mekominus]})
	writeSelection(band,imgData)

# Meko-
mekominus = (band=gBand, isUndo=no) ->
	debug('mekominus', band, isUndo)
	if not isUndo then undoStack.push({'band':band,'filters':[mekoplus]})
	writeSelection(band,imgData)

# FL
fl = (band=gBand, isUndo=no) ->
	debug('fl', band, isUndo)
	if not isUndo then undoStack.push({'band':band,'filters':[fl]})
	writeSelection(band,imgData)

# Q0
q0 = (band=gBand, isUndo=no) ->
	debug('q0', band, isUndo)
	hGlass(band, yes)
	vGlass(band, yes)
	negative(band, yes)
	if not isUndo then undoStack.push({'band':band, 'filters':[q0]})

# Undo the last change
undo = ->
	debug('undo')
	if undoStack.length
		step = undoStack.pop()
		step.filters.map((x) -> x(step.band,yes))

# Undo all changes
revert = ->
	debug('revert')
	while(undoStack.length)
		undo()

## 'ey yo, just set it off, man
window.onload = ->
	debug('window.onload')
	cnvs1 = document.getElementById('cnvs1')
	cnvs2 = document.getElementById('cnvs2')
	ctx1 = cnvs1.getContext('2d')
	ctx2 = cnvs2.getContext('2d')
	cnvs2.addEventListener('mousemove', (e) -> updateMouse(e))
	cnvs2.addEventListener('mousedown', (e) -> startSelection(e))
	cnvs2.addEventListener('mouseup', (e) -> endSelection(e))
	img = new Image()
	img.onload = ->
		cnvs1.width = img.width
		cnvs1.height = img.height
		cnvs2.width = img.width
		cnvs2.height = img.height
		gBand.w = img.width - (img.width%8)
		gBand.h = img.height - (img.height%8)
		ctx1.drawImage(img, 0, 0)
		drawBand(gBand)
	img.src = 'test.png'

# set globals for the HTML
window.rotateRGB = rotateRGB
window.xor80 = xor80
window.flipud = flipud
window.fliplr = fliplr
window.negative = negative
window.vGlass = vGlass
window.hGlass = hGlass
window.win = win
window.mekominus = mekominus
window.mekoplus = mekoplus
window.fl = fl
window.q0 = q0
window.undo = undo
window.revert = revert
