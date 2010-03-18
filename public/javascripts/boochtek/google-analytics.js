var pageTracker = null; // Keep this global, in case we want to use it inside more than one closure. TODO: Move into jQuery namespace.

jQuery(document).ready(function() {

  // Get Google Analytics code from META header tag.
  var gaUA = jQuery('meta[name="google.analytics.code"]').attr('name');

  // Determine where to pull Google Anaylytics from.
  var gaURL = (('https:' == document.location.protocol) ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';

  // Make a pretty label from a link, including the URL (without protocol), and the link title (if it has one). 
  var getLabel = function ( a ) {
    var label = jQuery(a).attr('href').replace(/https?:\/\/(.*)/,"$1");
    if ( jQuery(a).attr('title') && jQuery(a).attr('title').length > 0 )
    {
      label += ' (' + jQuery(a).attr('title') + ')';
      // TODO: Also consider including the link text.
    }
    return label;
  };

  // Make a pretty label from a form, including the URL (without protocol), and the form title (if it has one). FIXME: Combine this with getLabel().
  var getAction = function ( form ) {
    var label = jQuery(form).attr('action').replace(/https?:\/\/(.*)/,"$1");
    if ( jQuery(form).attr('title') && jQuery(form).attr('title').length > 0 )
    {
      label += ' (' + jQuery(form).attr('title') + ')';
      // TODO: Also consider including the link text.
    }
    return label;
  };

  // Get the file type of a link, from REL attribute or extension.
  var getFileType = function ( a ) {
    var fileType = jQuery(a).attr('rel');
    if ( !fileType || fileType.length == 0 )
    {
      // Use file extension of the URL as the FileType.
      var hrefArray = jQuery(a).attr('href').split('.');
      fileType = hrefArray[hrefArray.length - 1];
    }
    return fileType;
  };

  jQuery.getScript(gaURL, function() {
    try
    {
      pageTracker = _gat._getTracker(gaUA);
      pageTracker._trackPageview();
    }
    catch ( err )
    {
      if ( typeof console != 'undefined' && typeof console.logg != 'undefined' )
      {
        console.log('Failed to load Google Analytics: ' + err);
      }
    }
  });

  // Add tracking of all outbound links (TODO: Should we use document.domain or window.location.hostname?):
  jQuery('a[href^=http]:not("[href*=://' + document.domain + ']")').click(function(){
    if ( pageTracker )
    {
      var label = getLabel(this);
      var urlHost = jQuery(this).context.hostname; // Hostname of the link.
      pageTracker._trackEvent('Outbound Links', urlHost, label);
    }
  });

  // Add tracking of anything marked as a 'download' (via class). Inspired by http://www.thewhyandthehow.com/tracking-events-with-google-analytics/
  jQuery(’a.download’).click(function(){
    if ( pageTracker )
    {
      var label = getLabel(this);
      var fileType = getFileType(this);
      pageTracker._trackEvent('Download', fileType, label);
    }
  });

  // Add tracking of form submissions.
  jQuery('form').submit(function(){
    if ( pageTracker )
    {
      var action = getAction(this);
      var urlHost = jQuery(this).context.hostname; // Hostname of the form.
      pageTracker._trackEvent('Form Submission', urlHost, action);
    }
  });
});
