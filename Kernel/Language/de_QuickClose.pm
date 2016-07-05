# --
# Kernel/Language/de_QuickClose.pm - the german translation of QuickClose
# Copyright (C) 2011 Perl-Services, http://www.perl-services.de
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

    $Lang->{'Add text'}              = 'Neuer QuickClose';
    $Lang->{'Author'}                = 'Autor';
    $Lang->{'Add/Change QuickClose'} = 'QuickClose hinzufügen/ändern';
    $Lang->{'Add/Change QuickClose texts'} = 'QuickClose hinzufügen/ändern';
    $Lang->{'QuickClose Management'} = 'QuickClose verwalten';
    $Lang->{'edit'}                  = 'bearbeiten';
    $Lang->{'Unlock Ticket'}         = 'Ticket freigeben';
    $Lang->{'delete'}                = 'löschen';
    $Lang->{'closed successful'}     = 'erfolgreich geschlossen';

    $Lang->{'State after close'}     = 'Neuer Status';
    $Lang->{'Pending Diff (in minutes)'} = 'Wartezeit (in Minuten)';

    $Lang->{"Tickets are unlocked automatically on 'closed' states"} = "Tickets werden bei 'geschlossen' Status automatisch freigegeben";
    $Lang->{"Create and manage QuickClose texts."} = "Erstellen und verwalten von QuickClose-Einstellungen.";

    $Lang->{'Acting user should become ticket owner'} = 'Ausführender Benutzer wird Besitzer';
    $Lang->{'Responsible should become ticket owner'} = 'Verantwortlicher wird Besitzer';

    $Lang->{"Show ticket Zoom after QuickClose"} = 'Zeige die Ticketansicht nach einem QuickClose';
    $Lang->{"Fix Hour:Minute for pending time"}  = 'Feste Stunde:Minute bei Warten-Status';

    return 1;
}

1;
