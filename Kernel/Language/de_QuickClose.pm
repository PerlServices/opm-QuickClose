# --
# Kernel/Language/de_QuickClose.pm - the German translation for QuickClose
# Copyright (C) 2011-2016 Perl-Services, http://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_QuickClose;

use strict;
use warnings;

use utf8;

our $VERSION = '0.01';

sub Data {
    my $Self = shift;

    my $Lang = $Self->{Translation};

    return if ref $Lang ne 'HASH';

    # Kernel/Config/Files/QuickClose.xml
    $Lang->{'Frontend module registration for the QuickClose agent interface.'} = 'Frontendmodul-Registration für das QuickClose Agenten Interface.';
    $Lang->{'QuickClose'} = '';
    $Lang->{'Frontend module registration for the quick close administration.'} = '';
    $Lang->{'Create and manage QuickClose texts.'} = 'Erstellen und verwalten von QuickClose-Einstellungen.';
    $Lang->{'Frontend module registration for the user search.'} = '';
    $Lang->{'Search for owners.'} = '';
    $Lang->{'Frontend module registration for the bulk QuickClose agent interface.'} = 'Frontendmodul-Registration für das MassenQuickClose Agenten Interface.';
    $Lang->{'Bulk QuickClose.'} = '';
    $Lang->{'Bulk QuickClose'} = '';
    $Lang->{'Modul to show OuputfilterClose.'} = 'Modul zum Anzeigen von OuputfilterClose.';
    $Lang->{'Modul to show OuputfilterClose in ticket overviews.'} = 'Modul zum Anzeigen von OuputfilterClose in Ticketübersichten.';
    $Lang->{'Label for the NULL option in dropdown.'} = 'Text für die Leer-Option im Dropdown.';
    $Lang->{'Default subject for "close" notes.'} = 'Standardbetreff für "Schließen"-Notizen.';
    $Lang->{'Default "close". This is used when no "CloseID" is passed.'} = 'Standardgrund für das Schließen. Wird verwendet wenn keine "CloseID" übergeben wird.';
    $Lang->{'Use queue move functionality for quick close.'} = '';
    $Lang->{'State types for quick closes.'} = '';
    $Lang->{'Default time to wait when new state is a pending state.'} = '';
    $Lang->{'Enables or disables the autocomplete feature for the user search in the ITSM agent interface.'} = '';
    $Lang->{'Adapts the width of the autocomplete drop down to the length of the longest option.'} = '';
    $Lang->{'Sets the minimum number of characters before autocomplete query is sent.'} = '';
    $Lang->{'Sets the maximum number of search results for the autocomplete feature.'} = '';
    $Lang->{'Delay time between autocomplete queries in milliseconds.'} = '';
    $Lang->{'Enables or disables TypeAhead for the autocomplete feature.'} = '';
    $Lang->{'Use group functionality for quick close.'} = '';
    $Lang->{'No'} = 'Nein';
    $Lang->{'Yes'} = 'Ja';
    $Lang->{'Labels for groups.'} = '';


    # Kernel/Modules/AgentTicketCloseBulk.pm
    $Lang->{'Close'} = '';
    $Lang->{'No TicketID is given!'} = '';
    $Lang->{'Please contact the admin.'} = '';
    $Lang->{'No QuickClose data found!'} = '';
    $Lang->{'No Access to these Tickets (IDs: %s)'} = '';

    # Kernel/Output/HTML/Templates/Standard/QuickCloseSnippetTicketView.tt
    $Lang->{'QuickClose ticket'} = '';

    # Kernel/Output/HTML/Templates/Standard/AdminQuickCloseList.tt
    $Lang->{'QuickClose Management'} = 'QuickClose verwalten';
    $Lang->{'Actions'} = '';
    $Lang->{'Add text'} = 'Neuer QuickClose';
    $Lang->{'List'} = '';
    $Lang->{'Name'} = '';
    $Lang->{'State'} = '';
    $Lang->{'Valid'} = '';
    $Lang->{'Date'} = '';
    $Lang->{'Author'} = 'Autor';
    $Lang->{'Action'} = '';
    $Lang->{'No matches found.'} = '';
    $Lang->{'edit'} = 'bearbeiten';
    $Lang->{'delete'} = 'löschen';

    # Kernel/Output/HTML/Templates/Standard/AdminQuickCloseUserSearch.tt
    $Lang->{'Search Agent'} = '';

    # Kernel/Output/HTML/Templates/Standard/AdminQuickCloseForm.tt
    $Lang->{'Go to overview'} = '';
    $Lang->{'Add/Change QuickClose texts'} = 'QuickClose hinzufügen/ändern';
    $Lang->{'A name for the QuickClose text is required.'} = '';
    $Lang->{'Role'} = '';
    $Lang->{'Group'} = '';
    $Lang->{'Subject'} = '';
    $Lang->{'Body'} = '';
    $Lang->{'A body text is required.'} = '';
    $Lang->{'Time units'} = '';
    $Lang->{'State after close'} = 'Neuer Status';
    $Lang->{'Pending Diff (in minutes)'} = 'Wartezeit (in Minuten)';
    $Lang->{'Fix Hour:Minute for pending time'} = 'Feste Stunde:Minute bei Warten-Status';
    $Lang->{'Priority'} = '';
    $Lang->{'Owner'} = '';
    $Lang->{'Invalid User.'} = '';
    $Lang->{'Responsible'} = '';
    $Lang->{'Acting user should become ticket owner'} = 'Ausführender Benutzer wird Besitzer';
    $Lang->{'Responsible should become ticket owner'} = 'Verantwortlicher wird Besitzer';
    $Lang->{'Unlock Ticket'} = 'Ticket freigeben';
    $Lang->{'Tickets are unlocked automatically on \'closed\' states'} = 'Tickets werden bei \'geschlossen\' Status automatisch freigegeben';
    $Lang->{'Validity'} = '';
    $Lang->{'Article Type'} = '';
    $Lang->{'Queue'} = '';
    $Lang->{'Show ticket Zoom after QuickClose'} = 'Zeige die Ticketansicht nach einem QuickClose';
    $Lang->{'Save'} = '';
    $Lang->{'or'} = '';
    $Lang->{'Cancel'} = '';

    return 1;
}

1;
