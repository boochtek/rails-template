// Basic jQuery extension helper functions.
jQuery.fn.extend({
    disable:    function(){ return this.attr('disabled', 'disabled'); }, // Disable the given elements. FIXME: Might not work for checkboxes.
    enable:     function(){ return this.removeAttr('disabled'); }, // Enable the given elements.
    check:      function(){ return this.attr('checked', 'checked'); }, // Check the given checkbox elements.
    uncheck:    function(){ return this.removeAttr('checked'); }, // Uncheck the given checkbox elements.
    ancestors:  function(expr){ return this.parents(expr); }, // Seems like a better name than parents(), which is too easily confused with parent().
    first:      function(){ return this.eq(0); }, // Returns the first item in the jQuery set. Same as filter(':first').
    id:         function(){ return this.eq(0).attr('id'); }, // Returns the ID of the first element. TODO: Look at 'name' attribute too?
    trimmedVal: function(){ return jQuery.trim(this.val()); }, // Returns value of field, with leading and trailing whitespace removed.
    url:        function(){ return this.attr('href') || this.attr('src'); },
    fields:     function(){ return this.find(':field'); }, // Find all form fields, i.e. INPUTs (except submit, reset, image, and button types), SELECTs, and TEXTAREAs.
    labelsFor:  function(){ return this.parents('label').add('label[for=' + this.id() + ']'); } // Returns all LABELs associated with the given element. (I.e. the 'for' field of the LABEL matches this element's ID, or the LABEL is an ancestor of this element.)
});
jQuery.extend({
    load:       function(url){ return jQuery.getScript(url); },
    'include':  function(url){ return jQuery.getScript(url); }
});
jQuery.extend(jQuery.expr[":"], {
    blank:  function(e){ return jQuery.trim(jQuery(e).val()) == ''; }, // Returns TRUE if value contains only whitespace.
    'and':  function(a, i, m) { return jQuery(a).filter(m[3]).length; }, // Allows selectors like 'p:and(.post)'. From http://gist.github.com/83845
    field:  function(e){ return (/input|select|textarea/i.test(e.nodeName)) && !(/submit|reset|button|image/i.test(e.type)); } // Returns TRUE if the element is an INPUT (except submit, reset, image, and button types), SELECT, or TEXTAREA.
});



// Returs an array of IDs that are duplicated in the HTML document.
jQuery.findDuplicateIDs = function()
{
    var ids = {};
    var duplicate_ids = [];

    // Find all the elements with IDs.
    jQuery('[id]').each(function(){
        var id = jQuery(this).id();
        if ( ids[id] )
        {
            duplicate_ids.push(id);
        }
        ids[id] = true;
    });

    return duplicate_ids;
};
