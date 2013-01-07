(function() {
  var animateBand, cnvs1, cnvs2, copySelection, ctx1, ctx2, debug, debugging, disableDebugFor, drawBand, endSelection, fl, fliplr, flipud, gBand, getMouse, hGlass, mekominus, mekoplus, mouse, negative, origin, q0, readSelection, revert, rotateRGB, selecting, startSelection, undo, undoStack, updateMouse, vGlass, win, writeSelection, xor80,
    __slice = Array.prototype.slice,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  ctx1 = {};

  ctx2 = {};

  cnvs1 = {};

  cnvs2 = {};

  undoStack = [];

  debugging = true;

  disableDebugFor = ['animateBand', 'getMouse', 'updateMouse', 'drawBand', 'readSelection', 'writeSelection', 'startSelection', 'endSelection'];

  debug = function() {
    var args, funcName;
    funcName = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    if (debugging && __indexOf.call(disableDebugFor, funcName) < 0) {
      return console.log(funcName, args);
    }
  };

  origin = {
    'x': 0,
    'y': 0
  };

  selecting = false;

  gBand = {
    'x': 0,
    'y': 0,
    'w': 0,
    'h': 0
  };

  mouse = {
    'x': 0,
    'y': 0
  };

  readSelection = function(band) {
    debug('readSelection', band);
    return ctx1.getImageData(band.x, band.y, band.w, band.h);
  };

  writeSelection = function(band, imgData) {
    debug('writeSelection', imgData, band.x, band.y);
    if ((band.w !== imgData.width) || (band.h !== imgData.height)) {
      console.error("Dimension mismatch between band and ImageData");
    }
    ctx1.putImageData(imgData, band.x, band.y);
    return drawBand(band);
  };

  copySelection = function() {
    var copy;
    return copy = {
      x: selection.x,
      y: selection.y,
      w: selection.w,
      h: selection.h
    };
  };

  updateMouse = function(e) {
    var x, y;
    debug('updateMouse', e);
    if (e.offsetX) {
      x = e.offsetX;
      y = e.offsetY;
    } else if (e.layerX) {
      x = e.layerX;
      y = e.layerY;
    }
    return mouse = {
      'x': x,
      'y': y
    };
  };

  getMouse = function() {
    debug('getMouse');
    return {
      'x': mouse.x,
      'y': mouse.y
    };
  };

  startSelection = function(e) {
    debug('startSelection', e);
    origin = getMouse();
    selecting = true;
    return window.mozRequestAnimationFrame(animateBand);
  };

  endSelection = function(e) {
    debug('endSelection', e);
    return selecting = false;
  };

  animateBand = function() {
    var pos, x1, x2, y1, y2;
    debug('animateBand');
    pos = getMouse();
    x1 = Math.min(origin.x, pos.x);
    x1 -= x1 % 8;
    y1 = Math.min(origin.y, pos.y);
    y1 -= y1 % 8;
    x2 = Math.max(origin.x, pos.x);
    x2 += 8 - (x2 % 8);
    if (x2 > cnvs1.width) x2 -= 8;
    y2 = Math.max(origin.y, pos.y);
    y2 += 8 - (y2 % 8);
    if (y2 > cnvs1.height) y2 -= 8;
    if (x2 !== x1 && y2 !== y1) {
      gBand = {
        x: x1,
        y: y1,
        w: x2 - x1,
        h: y2 - y1
      };
    }
    if (selecting) {
      drawBand(gBand);
      return window.mozRequestAnimationFrame(animateBand);
    }
  };

  drawBand = function(band) {
    debug('drawBand', band);
    ctx2.clearRect(0, 0, cnvs2.width, cnvs2.height);
    return ctx2.strokeRect(band.x, band.y, band.w, band.h);
  };

  rotateRGB = function(band, isUndo) {
    var bValue, gValue, i, imgData, rValue, _ref;
    if (band == null) band = gBand;
    if (isUndo == null) isUndo = false;
    debug('rotateRGB', band, isUndo);
    imgData = readSelection(band);
    for (i = 0, _ref = imgData.data.length - 1; i <= _ref; i += 4) {
      rValue = imgData.data[i];
      gValue = imgData.data[i + 1];
      bValue = imgData.data[i + 2];
      imgData.data[i] = gValue;
      imgData.data[i + 1] = bValue;
      imgData.data[i + 2] = rValue;
    }
    if (!isUndo) {
      undoStack.push({
        'band': band,
        'filters': [rotateRGB, rotateRGB]
      });
    }
    return writeSelection(band, imgData);
  };

  xor80 = function(band, isUndo) {
    var i, imgData, _ref;
    if (band == null) band = gBand;
    if (isUndo == null) isUndo = false;
    debug('xor80', band, isUndo);
    imgData = readSelection(band);
    for (i = 0, _ref = imgData.data.length - 1; 0 <= _ref ? i <= _ref : i >= _ref; 0 <= _ref ? i++ : i--) {
      if (i % 4 !== 3) imgData.data[i] ^= 128;
    }
    if (!isUndo) {
      undoStack.push({
        'band': band,
        'filters': [xor80]
      });
    }
    return writeSelection(band, imgData);
  };

  flipud = function(band, isUndo) {
    var imgData, r, s, temp, _ref, _ref2, _ref3;
    if (band == null) band = gBand;
    if (isUndo == null) isUndo = false;
    debug('flipud', band, isUndo);
    imgData = readSelection(band);
    for (r = 0, _ref = imgData.data.length / 2 - 1, _ref2 = 4 * imgData.width; 0 <= _ref ? r <= _ref : r >= _ref; r += _ref2) {
      for (s = 0, _ref3 = 4 * imgData.width - 1; 0 <= _ref3 ? s <= _ref3 : s >= _ref3; 0 <= _ref3 ? s++ : s--) {
        temp = imgData.data[r + s];
        imgData.data[r + s] = imgData.data[(imgData.height - 1) * imgData.width * 4 - r + s];
        imgData.data[(imgData.height - 1) * imgData.width * 4 - r + s] = temp;
      }
    }
    if (!isUndo) {
      undoStack.push({
        'band': band,
        'filters': [flipud]
      });
    }
    return writeSelection(band, imgData);
  };

  fliplr = function(band, isUndo) {
    var imgData, p, r, s, temp, _ref, _ref2, _ref3;
    if (band == null) band = gBand;
    if (isUndo == null) isUndo = false;
    debug('fliplr', band, isUndo);
    imgData = readSelection(band);
    for (r = 0, _ref = imgData.data.length - 1, _ref2 = 4 * imgData.width; 0 <= _ref ? r <= _ref : r >= _ref; r += _ref2) {
      for (p = 0, _ref3 = (4 * imgData.width) / 2 - 1; p <= _ref3; p += 4) {
        for (s = 0; s <= 3; s++) {
          temp = imgData.data[r + p + s];
          imgData.data[r + p + s] = imgData.data[r + (4 * imgData.width - 1) - (p + 3) + s];
          imgData.data[r + (4 * imgData.width - 1) - (p + 3) + s] = temp;
        }
      }
    }
    if (!isUndo) {
      undoStack.push({
        'band': band,
        'filters': [fliplr]
      });
    }
    return writeSelection(band, imgData);
  };

  negative = function(band, isUndo) {
    var bValue, gValue, i, imgData, rValue, _ref;
    if (band == null) band = gBand;
    if (isUndo == null) isUndo = false;
    debug('negative', band, isUndo);
    imgData = readSelection(band);
    for (i = 0, _ref = imgData.data.length - 1; i <= _ref; i += 4) {
      rValue = imgData.data[i];
      gValue = imgData.data[i + 1];
      bValue = imgData.data[i + 2];
      imgData.data[i] = 255 - rValue;
      imgData.data[i + 1] = 255 - gValue;
      imgData.data[i + 2] = 255 - bValue;
    }
    if (!isUndo) {
      undoStack.push({
        'band': band,
        'filters': [negative]
      });
    }
    return writeSelection(band, imgData);
  };

  vGlass = function(band, isUndo) {
    var colEnd, colIdx, i, imgData, subpixelIdx, subpixelVals, _ref, _ref2;
    if (band == null) band = gBand;
    if (isUndo == null) isUndo = false;
    debug('vGlass', band, isUndo);
    imgData = readSelection(band);
    for (i = 0, _ref = imgData.data.length - 1, _ref2 = 4 * 8; 0 <= _ref ? i <= _ref : i >= _ref; i += _ref2) {
      subpixelVals = Array.prototype.slice.call(imgData.data, i, i + 32);
      for (subpixelIdx = 0; subpixelIdx <= 31; subpixelIdx++) {
        colEnd = 4 * Math.ceil((32 - subpixelIdx) / 4) - 1;
        colIdx = colEnd - (3 - (subpixelIdx % 4));
        imgData.data[i + subpixelIdx] = subpixelVals[colIdx];
      }
    }
    if (!isUndo) {
      undoStack.push({
        'band': band,
        'filters': [vGlass]
      });
    }
    return writeSelection(band, imgData);
  };

  hGlass = function(band, isUndo) {
    var i, imgData, j, rowIdx, rows, subpixelIdx, _ref, _ref2, _ref3, _ref4;
    if (band == null) band = gBand;
    if (isUndo == null) isUndo = false;
    debug('hGlass', band, isUndo);
    imgData = readSelection(band);
    for (i = 0, _ref = imgData.data.length - 1, _ref2 = 4 * imgData.width * 8; 0 <= _ref ? i <= _ref : i >= _ref; i += _ref2) {
      rows = [];
      for (j = 0; j <= 7; j++) {
        rows.push(Array.prototype.slice.call(imgData.data, i + (j * 4 * imgData.width), i + ((j + 1) * 4 * imgData.width)));
      }
      for (rowIdx = _ref3 = rows.length - 1; _ref3 <= 0 ? rowIdx <= 0 : rowIdx >= 0; _ref3 <= 0 ? rowIdx++ : rowIdx--) {
        for (subpixelIdx = 0, _ref4 = rows[rowIdx].length - 1; 0 <= _ref4 ? subpixelIdx <= _ref4 : subpixelIdx >= _ref4; 0 <= _ref4 ? subpixelIdx++ : subpixelIdx--) {
          imgData.data[i + ((7 - rowIdx) * 4 * imgData.width) + subpixelIdx] = rows[rowIdx][subpixelIdx];
        }
      }
    }
    if (!isUndo) {
      undoStack.push({
        'band': band,
        'filters': [hGlass]
      });
    }
    return writeSelection(band, imgData);
  };

  win = function(band, isUndo) {
    if (band == null) band = gBand;
    if (isUndo == null) isUndo = false;
    debug('win', band, isUndo);
    if (!isUndo) {
      undoStack.push({
        'band': band,
        'filters': [win]
      });
    }
    return writeSelection(band, imgData);
  };

  mekoplus = function(band, isUndo) {
    if (band == null) band = gBand;
    if (isUndo == null) isUndo = false;
    debug('mekoplus', band, isUndo);
    if (!isUndo) {
      undoStack.push({
        'band': band,
        'filters': [mekominus]
      });
    }
    return writeSelection(band, imgData);
  };

  mekominus = function(band, isUndo) {
    if (band == null) band = gBand;
    if (isUndo == null) isUndo = false;
    debug('mekominus', band, isUndo);
    if (!isUndo) {
      undoStack.push({
        'band': band,
        'filters': [mekoplus]
      });
    }
    return writeSelection(band, imgData);
  };

  fl = function(band, isUndo) {
    if (band == null) band = gBand;
    if (isUndo == null) isUndo = false;
    debug('fl', band, isUndo);
    if (!isUndo) {
      undoStack.push({
        'band': band,
        'filters': [fl]
      });
    }
    return writeSelection(band, imgData);
  };

  q0 = function(band, isUndo) {
    if (band == null) band = gBand;
    if (isUndo == null) isUndo = false;
    debug('q0', band, isUndo);
    hGlass(band, true);
    vGlass(band, true);
    negative(band, true);
    if (!isUndo) {
      return undoStack.push({
        'band': band,
        'filters': [q0]
      });
    }
  };

  undo = function() {
    var step;
    debug('undo');
    if (undoStack.length) {
      step = undoStack.pop();
      return step.filters.map(function(x) {
        return x(step.band, true);
      });
    }
  };

  revert = function() {
    var _results;
    debug('revert');
    _results = [];
    while (undoStack.length) {
      _results.push(undo());
    }
    return _results;
  };

  window.onload = function() {
    var img;
    debug('window.onload');
    cnvs1 = document.getElementById('cnvs1');
    cnvs2 = document.getElementById('cnvs2');
    ctx1 = cnvs1.getContext('2d');
    ctx2 = cnvs2.getContext('2d');
    cnvs2.addEventListener('mousemove', function(e) {
      return updateMouse(e);
    });
    cnvs2.addEventListener('mousedown', function(e) {
      return startSelection(e);
    });
    cnvs2.addEventListener('mouseup', function(e) {
      return endSelection(e);
    });
    img = new Image();
    img.onload = function() {
      cnvs1.width = img.width;
      cnvs1.height = img.height;
      cnvs2.width = img.width;
      cnvs2.height = img.height;
      gBand.w = img.width - (img.width % 8);
      gBand.h = img.height - (img.height % 8);
      ctx1.drawImage(img, 0, 0);
      return drawBand(gBand);
    };
    return img.src = 'test.png';
  };

  window.rotateRGB = rotateRGB;

  window.xor80 = xor80;

  window.flipud = flipud;

  window.fliplr = fliplr;

  window.negative = negative;

  window.vGlass = vGlass;

  window.hGlass = hGlass;

  window.win = win;

  window.mekominus = mekominus;

  window.mekoplus = mekoplus;

  window.fl = fl;

  window.q0 = q0;

  window.undo = undo;

  window.revert = revert;

}).call(this);
