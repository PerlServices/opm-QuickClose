// --
// QuickClose.Core.js - provides the special module functions for the user search
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var QuickClose = QuickClose || {};

/**
 * @namespace
 * @exports TargetNS as QuickClose.Core
 * @description
 *      This namespace contains the special module functions for the user search.
 */
QuickClose.Core = (function (TargetNS) {
    $('#CreateArticle').on('click', function() {
        if ( $(this).is(':checked') ) {
            $('#ArticleFields').removeClass('Hidden');
            $('#RichText').addClass('Validate_Required');
            $('#Subject').addClass('Validate_Required');
            Core.UI.InputFields.InitSelect( $('#ArticleType') );
        }
        else {
            CKEDITOR.instances.RichText.setData( '' );
            $('#RichText').removeClass('Validate_Required');
            $('#Subject').removeClass('Validate_Required').val('');
            $('#ArticleFields').addClass('Hidden');
        }
    });

    if ( $('#CreateArticle').is(':checked') ) {
        $('#ArticleFields').removeClass('Hidden');
    }

    return TargetNS;
}(QuickClose.Core || {}));

