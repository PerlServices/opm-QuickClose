# --
# Copyright (C) 2011 - 2018 Perl-Services.de, http://www.perl-services.de/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FilterContent::CloseTicketViewJS;

use strict;
use warnings;

use Kernel::System::Encode;
use Kernel::System::Time;
use Kernel::System::QuickClose;
use Kernel::System::Web::UploadCache;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Encode
    Kernel::System::Log
    Kernel::System::Main
    Kernel::System::Time
    Kernel::System::Group
    Kernel::Output::HTML::Layout
    Kernel::System::QuickClose
    Kernel::System::Web::Request
    Kernel::System::Web::UploadCache
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    return 1 if ${ $Param{Data} } !~ m{class="QuickCloseView"}xms;

    my $JS = q~
        <script type="text/javascript">//<![CDATA[
        Core.App.Ready( function() {
        $('.QuickCloseSelect').each( function( SelectIndex, SelectElement) {
            $(SelectElement).unbind('change');
            $(SelectElement).bind('change', function (Event) {
                // retrieve body for quickclose
                var URL = Core.Config.Get('Baselink');
                var TID = $(this).val();

                if ( !TID || TID == "" ) {
                    return;
                }

                var $SelectedTickets;
                var CloseForm = $(this).closest('form');
                var TicketElementSelectors = {
                    'Small': 'div.Overview form table tbody tr td input:checkbox[name="TicketID"]',
                    'Medium': 'ul.Overview input:checkbox[name="TicketID"]',
                    'Large': 'ul.Overview input:checkbox[name="TicketID"]'
                };
                var TicketView;

                var thisObject = $(this);

                if ($('#TicketOverviewMedium').length) {
                    TicketView = 'Medium';
                }
                else if ($('#TicketOverviewLarge').length) {
                    TicketView = 'Large';
                }
                else {
                    TicketView = 'Small';
                }

                if ( TID ) {
                    $SelectedTickets = $(TicketElementSelectors[TicketView] + ':checked');
                    $SelectedTickets.each(function () {
                        var HiddenField = $('<input type="hidden" name="TicketID">');
                        HiddenField.val( $(this).val() );
                        CloseForm.append( HiddenField );
                    });
                    CloseForm.submit();
                }
            });
        });
        });
        // ]]> </script>
    ~;

    ${ $Param{Data} } =~ s{</body>}{$JS</body>}xms;

    return 1;
}

1;
