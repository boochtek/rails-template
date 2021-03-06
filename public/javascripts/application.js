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
