ctx1 = {}
ctx2 = {}
cnvs1 = {}
cnvs2 = {}
mouse = {'x':0, 'y':0}
undoStack = []

debugging = on
disableDebugFor = ['animateBand', 'getMouse', 'updateMouse','drawBand']
debug = (funcName, args...) ->
	if debugging and funcName not in disableDebugFor
		console.log(funcName, args)

##selection
origin = {'x':0, 'y':0}
selecting = no
gBand = {'x':0, 'y':0, 'w':0, 'h':0}

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
	readSelection(gBand)

animateBand = ->
	debug('animateBand')
	pos = getMouse()
	x1 = Math.min(origin.x, pos.x)
	x1 -= x1 % 8
	y1 = Math.min(origin.y, pos.y)
	y1 -= y1 % 8
	x2 = Math.max(origin.x, pos.x)
	x2 += 8 - (x2 % 8)
	y2 = Math.max(origin.y, pos.y)
	y2 += 8 - (y2 % 8)
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

## filters
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

# RGB negative filter
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

# Vertical Glass filter
vGlass = (band=gBand, isUndo=no) ->
	debug('vGlass', band, isUndo)
	imgData= readSelection(band)
	for i in [0 .. imgData.data.length-1] by (4 * 8)
		r0 = imgData.data[i+0]
		g0 = imgData.data[i+1]
		b0 = imgData.data[i+2]
		a0 = imgData.data[i+3]
		r1 = imgData.data[i+4]
		g1 = imgData.data[i+5]
		b1 = imgData.data[i+6]
		a1 = imgData.data[i+7]
		r2 = imgData.data[i+8]
		g2 = imgData.data[i+9]
		b2 = imgData.data[i+10]
		a2 = imgData.data[i+11]
		r3 = imgData.data[i+12]
		g3 = imgData.data[i+13]
		b3 = imgData.data[i+14]
		a3 = imgData.data[i+15]
		r4 = imgData.data[i+16]
		g4 = imgData.data[i+17]
		b4 = imgData.data[i+18]
		a4 = imgData.data[i+19]
		r5 = imgData.data[i+20]
		g5 = imgData.data[i+21]
		b5 = imgData.data[i+22]
		a5 = imgData.data[i+23]
		r6 = imgData.data[i+24]
		g6 = imgData.data[i+25]
		b6 = imgData.data[i+26]
		a6 = imgData.data[i+27]
		r7 = imgData.data[i+28]
		g7 = imgData.data[i+29]
		b7 = imgData.data[i+30]
		a7 = imgData.data[i+31]
		imgData.data[i+0] = r7 
		imgData.data[i+1] = g7
		imgData.data[i+2] = b7
		imgData.data[i+3] = a7
		imgData.data[i+4] = r6
		imgData.data[i+5] = g6
		imgData.data[i+6] = b6
		imgData.data[i+7] = a6
		imgData.data[i+8] = r5
		imgData.data[i+9] = g5
		imgData.data[i+10] = b5 
		imgData.data[i+11] = a5
		imgData.data[i+12] = r4
		imgData.data[i+13] = g4
		imgData.data[i+14] = b4
		imgData.data[i+15] = a4
		imgData.data[i+16] = r3
		imgData.data[i+17] = g3
		imgData.data[i+18] = b3
		imgData.data[i+19] = a3
		imgData.data[i+20] = r2
		imgData.data[i+21] = g2
		imgData.data[i+22] = b2
		imgData.data[i+23] = a2
		imgData.data[i+24] = r1
		imgData.data[i+25] = g1
		imgData.data[i+26] = b1
		imgData.data[i+27] = a1
		imgData.data[i+28] = r0
		imgData.data[i+29] = g0
		imgData.data[i+30] = b0
		imgData.data[i+31] = a0
	if not isUndo then undoStack.push({'band':band,'filters':[vGlass]})
	writeSelection(band,imgData)

# Undo the last change
undo = ->
	debug('undo')
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
		gBand.w = img.width
		gBand.h = img.height
		ctx1.drawImage(img, 0, 0)
		drawBand(gBand)
	img.src = 'test.jpg'

# set globals for the HTML
window.rotateRGB = rotateRGB
window.negative = negative
window.vGlass = vGlass
window.undo = undo
window.revert = revert
