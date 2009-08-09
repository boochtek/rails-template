jQuery.extend(jQuery.expr[":"], {
    'required':         function(e){ return false; }, // TODO: Return TRUE if a this is a field and is required.
    'valid':            function(e){ return false; }, // TODO: Return TRUE if a this is a field and is valid.
    'invalid':          function(e){ return false; }, // TODO: Return TRUE if a this is a field and is not valid.
    'validatedField':   function(e){ return false; }  // TODO: Return TRUE if this is a field that has the validation hooks attached.
});



jQuery.validation = {};
jQuery.validation.defaults = {
    'namespace': 'validation',  // Prefix used by validation:type, validation:required and other attributes. (TODO: May also provide a URI.)
    debug: false,               // If set to true, an invalid validation:type will trigger an alert.
    validClass: 'valid',        // Add this class to elements that are valid.
    invalidClass: 'invalid',    // Add this class to elements that are invalid.
    requiredClass: 'required',  // Add this class to elements that are determined to be required.
    validateOnKeyup: true,      // Check for validation on 'keyup' events, in addition to 'change' and 'blur' events.
    disableSubmitButton: false, // Disable the from's submit button until all fields in the form are valid.
    markRequiredFields: true,   // Add 'required' class to LABELs associated with required fields. Also tack on some HTML to the required fields and labels.
    wrapThLabels: false,        // Find all the TH fields that are followed by a TD with an INPUT and wrap the TH's content in a LABEL element.
    focusFirstInvalidField: false,      // If set to true, move the user's focus to the first invalid field in the form. (If no field is invalid, leave the focus where it was.)
    requiredFieldFilter:        // Determine which fields are required. FIXME: doesn't take options.namespace or options.requiredClass into account.
        function(){return jQuery(this).attr('validation:required') == 'true' || jQuery(this).hasClass('required');}, // NOTE: jQuery as of 1.2.3 does not accept colons in attributes in '[attribute=value]' selectors, otherwise we'd use filter('[validation:required=true], .required').
    appendAfterRequiredField: ' <span class="show_if_required required" title="This field is required">(required)</span>', // for markRequiredFields
    appendToLabel: ' <span class="show_if_required required" title="This field is required">*</span> <img class="show_if_invalid" src="invalid.gif" title="This field is invalid" />',
    appendAfterField: '',
//  appendBeforeField: ' <span class="invalid">Invalid!</span>',
//  prependToLabel: ' <span class="invalid">Invalid!</span>',
};

jQuery.validation['integer'] = {
    messageText: 'must be an integer',
    isValid: function(value)
    {
        return value.match(/^-?\d+$/);
    }
}
jQuery.validation['bob'] = {
    messageText: 'must be "Bob"',
    isValid: function(value)
    {
        return value.match(/^bob$/i);
    }
}
jQuery.validation['name'] = {
    messageText: 'must be a name',
    isValid: function(value)
    {
        return value.match(/^[a-zA-Z ,.'-]+$/);
    }
}
jQuery.validation['identifier'] = {
    messageText: 'must be a valid identifier',
    isValid: function(value)
    {
        return value.match(/^[a-zA-Z_][0-9a-zA-Z_.-]*$/);
    }
}


// Add validation features to a form (or set of forms).
jQuery.fn.enableValidation = function(options)
{
    // Merge user-specified options with defaults.
    var options = jQuery.extend({}, jQuery.validation.defaults, options || {});

    // Handle some options that need to be taken care of before we enable validation.
    if ( options.debug )
    {
        jQuery.alertOnDuplicateIDs();
        jQuery.alertOnDuplicateIDs();
    }
    if ( options.wrapThLabels )
    {
        this.wrapThLabels(); // NOTE: This has to go before most other options, as many options depend on LABELs existing.
    }
    if ( options.markRequiredFields )
    {
        this.markRequiredFields(options);
    }

    this.each(function(){
        var form = jQuery(this);

        // Stow the options with the form.
        form.data('options.validation', options);

        // Find all fields with attributes of 'validation:type' or 'validation:required'.
        // NOTE: jQuery as of 1.2.3 does not accept colons in attributes in '[attribute=value]' selectors, so we use a filter.
        var fields = form.fields().filter(function(index){
            return jQuery(this).attr(options.namespace + ':type') != undefined || jQuery(this).attr(options.namespace + ':required') == 'true';
        });

        fields.each(function(){
            var field = jQuery(this);
            var labels = field.labelsFor();
            // Set the field's current validity.
            field.validate();
            // Check the field's validity any time it changes. (Actually, when focus leaves the field after changing.)
            field.change(function(){
                jQuery(this).validate();
            });
            // Check the field's validity any time we leave the field. (Because Firefox doesn't trigger 'change' if user selects an item from an auto-select drop-down.)
            field.blur(function(){
                jQuery(this).validate();
            });
            // Check the field's validity any time we receive a keystroke for the field.
            if ( options.validateOnKeyup )
            {
                field.keyup(function(){
                    jQuery(this).validate();
                });
            }
            // TODO: Add additional validity indicators.
            if ( options.appendToLabel )
                labels.append(options.appendToLabel);
            if ( options.appendAfterField )
                field.after(options.appendAfterField);
        });
        fields.trigger('field'); // TODO: Change to 'validatedField'?

        if ( options.disableSubmitButton )
        {
            form.find(':submit').disable();
            form.validate();
        }

        if ( options.focusFirstInvalidField )
        {
            form.find('.invalid:first').focus(); // TODO: Make it '.invalid:first:field' once we add the :field selector.
        }
    });

    // Allow chaining.
    return this;
};


// Sets the valid/invalid classes, depending on whether the field passes its validation tests.
// Also set the classes on any LABELs and FORMs associated with the field.
// Can also pass a form, which will validate all the fields in the form.
jQuery.fn.validate = function()
{
    this.each(function(){
        var field = jQuery(this);

        // If we're dealing with a form, just validate all its INPUT fields.
        if ( field.is('form') )
        {
            var form = jQuery(this);
            form.fields().each(function(){
                jQuery(this).validate();
            });
            return;
        }

        var form = field.parents('form');
        var options = form.data('options.validation');

        if ( field.isValid() )
        {
            field.addClass(options.validClass).removeClass(options.invalidClass);
            field.labelsFor().addClass(options.validClass).removeClass(options.invalidClass);
            field.parent().addClass(options.validClass).removeClass(options.invalidClass);
            field.trigger('valid');

            // If none of the form's INPUT fields are invalid, set the form's class as 'valid'.
            var form_is_valid = true;
            form.fields().each(function(){
                if ( jQuery(this).hasClass(options.invalidClass) )
                    form_is_valid = false;
            });
            if ( form_is_valid )
            {
                form.addClass(options.validClass).removeClass(options.invalidClass);
                if ( options.disableSubmitButton )
                {
                    form.find(':submit').enable();
                }
                // TODO: Only do this when the form's valid state changes.
                form.trigger('valid');
            }
        }
        else
        {
            field.addClass(options.invalidClass).removeClass(options.validClass);
            field.labelsFor().addClass(options.invalidClass).removeClass(options.validClass);
            field.parent().addClass(options.invalidClass).removeClass(options.validClass);
            field.trigger('invalid');

            form.addClass(options.invalidClass).removeClass(options.validClass);
            if ( options.disableSubmitButton )
            {
                form.find(':submit').disable();
            }
            // TODO: Only do this when the form's valid state changes.
            form.trigger('invalid');
        }
    });

    // Allow chaining.
    return this;
}


// Returns TRUE if the element passes its validation checks.
// Can also handle multiple items in the jQuery 'this' set, as well as complete forms.
jQuery.fn.isValid = function()
{
    // If we're a set of items, then return TRUE only if all items in the set are valid.
    if ( this.size() > 1 )
    {
        var result = true;
        this.each(function(){
            if ( !jQuery(this).isValid() )
                result = false;
        });
        return result;
    }

    var field = this.first();
    var form = field.parents('form');
    var options = form.data('options.validation');
    var validation_type = field.attr(options.namespace + ':type');

    // If field is not required, and is blank, then it is valid. TODO: Use requiredFieldFilter here.
    if ( field.attr(options.namespace + ':required') != 'true' && field.isBlank() )
        return true;

    // If field is required, but there's no validation type, then allow anything except blank. TODO: Use requiredFieldFilter here.
    if ( field.attr(options.namespace + ':required') == 'true' && !validation_type )
        return !field.isBlank();

    // If the validation type is not found, return FALSE.
    if ( !jQuery.validation[validation_type] )
    {
        if ( options.debug && !field.data('alerted_on_unknown_type.validation') )
        {
            alert('Unknown validation type (' + validation_type + ') on field with ID of ' + field.id());
            field.data('alerted_on_unknown_type.validation', true);
        }

        // NOTE: It would be nice to raise an error here, but that would cause other validations to stop working.
        return false;
    }

    // Check the actual validation functions here.
    return jQuery.validation[validation_type].isValid(field.val());
}


// TODO: Add additional required indicators: before field, after label, prepend label.
// NOTE: Don't call this outside of enableValidation() if you don't turn off the markRequiredFields option, or you'll add items twice.
jQuery.fn.markRequiredFields = function(options)
{
    // Merge user-specified options with defaults.
    var options = jQuery.extend({}, jQuery.validation.defaults, options || {});

    this.each(function(){
        var form = jQuery(this);
        // Find all required fields.
        var fields = form.fields().filter(options.requiredFieldFilter);

        fields.each(function(){
            var field = jQuery(this);
            field.labelsFor().addClass(options.requiredClass);
            field.parent().addClass(options.requiredClass);
            if ( options.appendAfterRequiredField )
            {
                field.after(options.appendAfterRequiredField);
            }
        });
        fields.trigger('required');
    });

    // Allow chaining.
    return this;
}


// Find all the TH fields that are followed by a TD with an INPUT and wrap the TH's content in a LABEL element.
jQuery.fn.wrapThLabels = function()
{
    this.each(function(){
        var form = jQuery(this);

        // Find all the THs that we need to wrap.
        var ths = form.find('th').filter(function(index){
            var th = jQuery(this);
            var tr = th.parent('tr');

            // Don't include any THs that already contain a LABEL.
            if ( th.find('label').size() > 0 )
                return false;

            // Return TRUE iff parent is a TR containing a TD with an INPUT.
            return tr.size() == 1 && tr.children('td').fields().size() == 1;
        });

        ths.each(function(){
            // Get the TH and the INPUT within the associated TD.
            var th = jQuery(this);
            var input = th.next().fields();

            // Wrap the TH's content in a LABEL.
            th.wrapInner('<label></label>');

            // Add a FOR attribute, pointing to the INPUT in the TD.
            th.find('label').attr('for', input.id());
        });
    });

    // Allow chaining.
    return this;
};


