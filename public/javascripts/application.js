// These will be used to add more classes to the HTML or BODY tag for cases where we need to make special-case CSS rules.
// TODO: These should be moved out of the global namespace.
var isAndroid = /Android/.test(navigator.userAgent);
var isIOS = /iP(?:ad|hone|od)/.test(navigator.userAgent);
var isMac = /Mac OS X/.test(navigator.userAgent);
var isWindows = /Windows NT/.test(navigator.userAgent);

var isGecko = /Gecko\//.test(navigator.userAgent);
var isPresto = !!win.opera;
var isEdge = /Edge\//.test(navigator.userAgent);
var isWebKit = !isEdge && /WebKit\//.test(navigator.userAgent);
var isIE6 = /MSIE 6/.test(navigator.userAgent);
var isIE7 = /MSIE 7/.test(navigator.userAgent);
var isIE8 = /MSIE 8/.test(navigator.userAgent);
var isIE9 = /MSIE 9/.test(navigator.userAgent);
var isIE10 = /MSIE 10/.test(navigator.userAgent);
var isIE11 = /Trident\/7/.test(navigator.userAgent);
var isIE = isIE6 || isIE7 || isIE8 || isIE9 || isIE10 || isIE11;

// Be nice and use the modifier key appropriate to the OS.
var primaryModifierKey = isMac ? 'meta' : 'ctrl';


// Allow CSS to easily determine whether we're running with JavaScript enabled or not.
jQuery('body').addClass('hasJS'); // Considered adding the class to HEAD, but while the DOM supports it, the HTML spec doesn't allow className on HEAD.

// This section will run after all the DOM is loaded (i.e. all elements) but right before they're displayed, and before all the images and such are loaded.
jQuery(document).ready(function(){

    // Focus on the first text field. NOTE: The focusOnFirstInvalidField option to enableValidation() can override this.
    jQuery(':text:first').focus(); // TODO: May want to specify a specific form or field you want to focus on.

    // Disable submit buttons once they're clicked (so user doesn't accidentally submit twice).
    jQuery(':submit').click(function(event) {
        jQuery(event.target).disable();
    });
});
