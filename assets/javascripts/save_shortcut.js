//
// Dmitry Belokurov (dmitry.belokurov@lanit-tercom.com), Lanit-Tercom, Inc
//
// Finds out user agent
var userAgent = navigator.userAgent.toLowerCase();
var isIE = (userAgent.indexOf("msie") != -1 && userAgent.indexOf("opera") == -1);
var isGecko = (userAgent.indexOf("gecko") != -1); 
var isChrome = (userAgent.indexOf("chrom") != -1);
  
// Adds keyboard event handler for IE, Opera, FF
function addKeyboardHandler(object, event, handler, useCapture) {
  if (object.addEventListener)
    object.addEventListener(event, handler, useCapture ? useCapture : false);
  else if (object.attachEvent)
    object.attachEvent('on' + event, handler);
}

// Just submits our form
function submitForm() {
  if (window.confirm("Save page?"))
    document.getElementsByName('commit')[0].click();
}

// Saves page
function savePage(evt) {
  evt = evt || window.event;
  var key = evt.keyCode || evt.which;
  key = !isGecko ? (key == 83 ? 1 : 0) : (key == 115 ? 1 : 0);
  if (evt.ctrlKey && key) {
    if(evt.preventDefault) 
      evt.preventDefault();
    evt.returnValue = false;
    submitForm();
    window.focus();
    return false;
  }
}

// Initializes keyboard handlers
function setupSaveShortcut() {
  var frameDocument = window.frames[0].window.document;
  
  // Chrome and Chromium
  if (isChrome){
    var isCtrl = false;
    frameDocument.onkeyup = document.onkeyup = function(e) {
      if(e.which == 17) 
        isCtrl=false;
    }
    frameDocument.onkeydown= document.onkeydown = function(e) {
      if(e.which == 17)
        isCtrl=true;
      if(e.which == 83 && isCtrl == true) {
        submitForm();
        return false;
      }
    }
  }
  // Internet Explorer
  else if (isIE)
  {
    addKeyboardHandler (frameDocument, "keydown", savePage);
    addKeyboardHandler (document, "keydown", savePage);
  }
  // Other browsers
  else 
  {
    addKeyboardHandler (frameDocument, "keypress", savePage);
    addKeyboardHandler (document, "keypress", savePage);
  }
}
