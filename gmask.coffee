origin = {'x':0,'y':0}
selection = {'x':0,'y':0,'w':0,'h':0}
selecting = no
ctx = {}
img = {}
mouse = {'x':0,'y':0}

updateMouse = (e) ->
	if e.offsetX
		x = e.offsetX
		y = e.offsetY
	else if e.layerX
		x = e.layerX
		y = e.layerY
	mouse = {'x':x,'y':y}

getMouse = ->
	{'x':mouse.x,'y':mouse.y}

startSelection = (e) ->
	origin = getMouse()
	selecting = yes
	window.mozRequestAnimationFrame(animateSelection)

endSelection = (e) ->
	selecting = no

animateSelection = ->
	ctx.drawImage(img,0,0)
	pos = getMouse()
	x1 = Math.min(origin.x, pos.x)
	x1 -= x1 % 8
	y1 = Math.min(origin.y, pos.y)
	y1 -= y1 % 8
	x2 = Math.max(origin.x, pos.x)
	x2 += 8 - (x2 % 8)
	y2 = Math.max(origin.y, pos.y)
	y2 += 8 - (y2 % 8)
	selection =
		x: x1
		y: y1
		w: x2 - x1
		h: y2 - y1
	ctx.strokeRect(selection.x,selection.y,selection.w,selection.h)
	if selecting
		window.mozRequestAnimationFrame(animateSelection)

window.onload = ->
	cnvs = document.getElementById('cnvs')
	ctx = cnvs.getContext('2d')
	cnvs.addEventListener('mousemove', (e) -> updateMouse(e))
	cnvs.addEventListener('mousedown', (e) -> startSelection(e))
	cnvs.addEventListener('mouseup', (e) -> endSelection(e))
	img = new Image()
	img.onload = ->
		cnvs.width = img.width
		cnvs.height = img.height
		selection.w = img.width
		selection.h = img.height
		ctx.drawImage(img,0,0)
	img.src = 'test.jpg'
		
