# --
# Kernel/Language/de_QuickClose.pm - the German translation for QuickClose
# Copyright (C) 2011 - 2022 Perl-Services, https://www.perl-services.de
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
    $Lang->{'Frontend module registration for the QuickClose agent interface.'} = 'Frontendmodul-Registrierung für das QuickClose Agenten Interface.';
    $Lang->{'QuickClose'} = 'QuickClose';
    $Lang->{'Frontend module registration for the quick close administration.'} = 'Frontendmodul für die QuickClose-Verwaltung';
    $Lang->{'Create and manage QuickClose texts.'} = 'Erstellen und verwalten von QuickClose-Einstellungen.';
    $Lang->{'Frontend module registration for the user search.'} = 'Frontendmodul-Registrierung für die Benutzersuche';
    $Lang->{'Search for owners.'} = 'Nach Besitzern suchen';
    $Lang->{'Frontend module registration for the bulk QuickClose agent interface.'} = 'Frontendmodul-Registration für das MassenQuickClose Agenten Interface.';
    $Lang->{'Bulk QuickClose.'} = 'Sammel-Schließen';
    $Lang->{'Bulk QuickClose'} = 'Sammel-Schließen';
    $Lang->{'Modul to show OuputfilterClose.'} = 'Modul zum Anzeigen von OuputfilterClose.';
    $Lang->{'Modul to show OuputfilterClose in ticket overviews.'} = 'Modul zum Anzeigen von OuputfilterClose in Ticketübersichten.';
    $Lang->{'Only the ticket owner sees the dropdown.'} = 'Nur der Ticketbesitzer sieht das Dropdown.';
    $Lang->{'Label for the NULL option in dropdown.'} = 'Text für die Leer-Option im Dropdown.';
    $Lang->{'Default subject for "close" notes.'} = 'Standardbetreff für "Schließen"-Notizen.';
    $Lang->{'Default "close". This is used when no "CloseID" is passed.'} = 'Standardgrund für das Schließen. Wird verwendet wenn keine "CloseID" übergeben wird.';
    $Lang->{'Use queue move functionality for quick close.'} = 'Verschieben-Funktionalität für QuickClose aktivieren';
    $Lang->{'State types for quick closes.'} = 'Statustypen für QuickCloses';
    $Lang->{'Default time to wait when new state is a pending state.'} = 'Standard-Wartezeit wenn der neue Status ein "Warten"-Status ist.';
    $Lang->{'Enables or disables the autocomplete feature for the user search in the ITSM agent interface.'} = 'Aktiviere/Deaktivere das Autocomplete-Feature für die Benutzersuche im ITSM Agenteninterface';
    $Lang->{'Adapts the width of the autocomplete drop down to the length of the longest option.'} = '';
    $Lang->{'Sets the minimum number of characters before autocomplete query is sent.'} = '';
    $Lang->{'Sets the maximum number of search results for the autocomplete feature.'} = '';
    $Lang->{'Delay time between autocomplete queries in milliseconds.'} = '';
    $Lang->{'Enables or disables TypeAhead for the autocomplete feature.'} = '';
    $Lang->{'Use group functionality for quick close.'} = 'Gruppen-Funktionalität für QuickClose verwenden';
    $Lang->{'No'} = 'Nein';
    $Lang->{'Yes'} = 'Ja';
    $Lang->{'Labels for groups.'} = 'Gruppenbezeichnungen';


    # Kernel/Modules/AgentTicketCloseBulk.pm
    $Lang->{'Close'} = 'Schließen';
    $Lang->{'No TicketID is given!'} = 'Keine TicketID übergeben!';
    $Lang->{'Please contact the admin.'} = 'Bitte kontaktieren Sie den OTRS-Administrator';
    $Lang->{'No QuickClose data found!'} = 'Keine QuickClose-Daten gefunden';
    $Lang->{'No Access to these Tickets (IDs: %s)'} = 'Kein Zugriff auf diese Tickets (IDs: %s)';
    $Lang->{'QuickClose not applicable for these Tickets (IDs: %s)'} = 'Aktion kann nicht auf diese Tickets angewendet werden (IDs: %s)';

    # Kernel/Output/HTML/Templates/Standard/QuickCloseSnippetTicketView.tt
    $Lang->{'QuickClose ticket'} = 'Ticket schnellschließen';

    # Kernel/Output/HTML/Templates/Standard/AdminQuickCloseList.tt
    $Lang->{'QuickClose Management'} = 'QuickClose verwalten';
    $Lang->{'Actions'} = 'Aktionen';
    $Lang->{'Add text'} = 'Neuer QuickClose';
    $Lang->{'List'} = 'Liste';
    $Lang->{'Name'} = 'Name';
    $Lang->{'State'} = 'Status';
    $Lang->{'Valid'} = 'Gültig';
    $Lang->{'Date'} = 'Datum';
    $Lang->{'Author'} = 'Autor';
    $Lang->{'Action'} = 'Aktion';
    $Lang->{'No matches found.'} = 'Keine Treffer gefunden';
    $Lang->{'edit'} = 'bearbeiten';
    $Lang->{'delete'} = 'löschen';

    # Kernel/Output/HTML/Templates/Standard/AdminQuickCloseUserSearch.tt
    $Lang->{'Search Agent'} = 'Suche Agenten';

    # Kernel/Output/HTML/Templates/Standard/AdminQuickCloseForm.tt
    $Lang->{'Go to overview'} = 'Zur Übersicht gehen';
    $Lang->{'Add/Change QuickClose texts'} = 'QuickClose hinzufügen/ändern';
    $Lang->{'A name for the QuickClose text is required.'} = 'Es muss ein Name für den QuickClose-Text eingegeben werden';
    $Lang->{'Role'} = 'Rolle';
    $Lang->{'Group'} = 'Gruppe';
    $Lang->{'Subject'} = 'Betreff';
    $Lang->{'Body'} = 'Text';
    $Lang->{'A body text is required.'} = 'Ein Nachrichtentext wird benötigt.';
    $Lang->{'Time units'} = 'Zeiteinheiten';
    $Lang->{'State after close'} = 'Neuer Status';
    $Lang->{'Pending Diff (in minutes)'} = 'Wartezeit (in Minuten)';
    $Lang->{'Fix Hour:Minute for pending time'} = 'Feste Stunde:Minute bei Warten-Status';
    $Lang->{'Priority'} = 'Priorität';
    $Lang->{'Owner'} = 'Besitzer';
    $Lang->{'Invalid User.'} = 'Ungültiger Benutzer.';
    $Lang->{'Responsible'} = 'Verantwortlich';
    $Lang->{'Acting user should become ticket owner'} = 'Ausführender Benutzer wird Besitzer';
    $Lang->{'Responsible should become ticket owner'} = 'Verantwortlicher wird Besitzer';
    $Lang->{'Unlock Ticket'} = 'Ticket freigeben';
    $Lang->{'Tickets are unlocked automatically on \'closed\' states'} = 'Tickets werden bei \'geschlossen\' Status automatisch freigegeben';
    $Lang->{'Validity'} = 'Gültigkeit';
    $Lang->{'Article Type'} = 'Artikeltyp';
    $Lang->{'Queue'} = 'Queue';
    $Lang->{'Show ticket Zoom after QuickClose'} = 'Zeige die Ticketansicht nach einem QuickClose';
    $Lang->{'Save'} = 'Speichern';
    $Lang->{'or'} = 'oder';
    $Lang->{'Cancel'} = 'Abbrechen';
    $Lang->{'Article viewable for Customer'} = 'Article für Kunden sichtbar';

    return 1;
}

1;
