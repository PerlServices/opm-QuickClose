# --
# Kernel/Language/de_QuickClose.pm - the german translation of QuickClose
# Copyright (C) 2011 Perl-Services, http://www.perl-services.de
# --
# $Id: de_QuickClose.pm,v 1.1.1.1 2011/04/15 07:49:58 rb Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_QuickClose;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.1.1.1 $) [1];

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

    $Lang->{'State after close'}     = 'Neuer Status';
    $Lang->{'Pending Diff (in minutes)'} = 'Wartezeit (in Minuten)';

    $Lang->{"Tickets are unlocked automatically on 'closed' states"} = "Tickets werden bei 'geschlossen' Status automatisch freigegeben";

    return 1;
}

1;
