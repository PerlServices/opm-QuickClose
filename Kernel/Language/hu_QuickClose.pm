# --
# Kernel/Language/hu_QuickClose.pm - the Hungarian translation for QuickClose
# Copyright (C) 2011 - 2023 Perl-Services, https://www.perl-services.de
# Copyright (C) 2016 Balázs Úr, http://www.otrs-megoldasok.hu
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::hu_QuickClose;

use strict;
use warnings;

use utf8;

our $VERSION = '0.01';

sub Data {
    my $Self = shift;

    my $Lang = $Self->{Translation};

    return if ref $Lang ne 'HASH';

    # Kernel/Config/Files/QuickClose.xml
    $Lang->{'Frontend module registration for the QuickClose agent interface.'} =
        'Előtétprogram-modul regisztráció a gyors lezárás ügyintézői felülethez.';
    $Lang->{'QuickClose'} = 'Gyors lezárás';
    $Lang->{'Frontend module registration for the quick close administration.'} =
        'Előtétprogram-modul regisztráció a gyors lezárás adminisztrációjához.';
    $Lang->{'Create and manage QuickClose texts.'} = 'Gyors lezárás szövegek létrehozása és kezelése.';
    $Lang->{'Frontend module registration for the user search.'} =
        'Előtétprogram-modul regisztráció a felhasználókereséshez.';
    $Lang->{'Search for owners.'} = 'Tulajdonosok keresése.';
    $Lang->{'Frontend module registration for the bulk QuickClose agent interface.'} =
        'Előtétprogram-modul regisztráció a tömeges gyors lezárás ügyintézői felülethez.';
    $Lang->{'Bulk QuickClose.'} = 'Tömeges gyors lezárás.';
    $Lang->{'Bulk QuickClose'} = 'Tömeges gyors lezárás';
    $Lang->{'Modul to show OuputfilterClose.'} = 'Egy modul a kimenetszűrő-lezárás megjelenítéséhez.';
    $Lang->{'Modul to show OuputfilterClose in ticket overviews.'} =
        'Egy modul a kimenetszűrő-lezárás megjelenítéséhez a jegyáttekintőkön.';
    $Lang->{'Only the ticket owner sees the dropdown.'} = 'Csak a jegytulajdonos látja a legördülőt.';
    $Lang->{'Label for the NULL option in dropdown.'} = 'Címke a legördülő üres lehetőségéhez.';
    $Lang->{'Default subject for "close" notes.'} = 'Alapértelmezett tárgy a „lezárás” jegyzetekhez.';
    $Lang->{'Default "close". This is used when no "CloseID" is passed.'} =
        'Alapértelmezett „lezárás”. Ezt akkor használják, amikor nincs „lezárásazonosító” átadva.';
    $Lang->{'Use queue move functionality for quick close.'} =
        'A várólista áthelyezés funkcionalitásának használata a gyors lezáráshoz.';
    $Lang->{'State types for quick closes.'} = 'Állapottípusok a gyors lezárásokhoz.';
    $Lang->{'Default time to wait when new state is a pending state.'} =
        'Alapértelmezett várakozási idő, amikor az új állapot egy várakozó állapot.';
    $Lang->{'Enables or disables the autocomplete feature for the user search in the ITSM agent interface.'} =
        'Engedélyezi vagy letiltja az automatikus kiegészítés szolgáltatást a felhasználókeresésnél az ITSM ügyintézői felületen.';
    $Lang->{'Adapts the width of the autocomplete drop down to the length of the longest option.'} =
        'Hozzáigazítja az automatikus kiegészítés legördülő szélességét a leghosszabb lehetőség hosszához.';
    $Lang->{'Sets the minimum number of characters before autocomplete query is sent.'} =
        'Beállítja a karakterek legkisebb számát az automatikus kiegészítés lekérdezés elküldése előtt.';
    $Lang->{'Sets the maximum number of search results for the autocomplete feature.'} =
        'Beállítja a keresési eredmények legnagyobb számát az automatikus kiegészítés szolgáltatásnál.';
    $Lang->{'Delay time between autocomplete queries in milliseconds.'} =
        'Késleltetési idő az automatikus kiegészítés lekérdezések között ezredmásodpercben.';
    $Lang->{'Enables or disables TypeAhead for the autocomplete feature.'} =
        'Engedélyezi vagy letiltja a TypeAhead használatát az automatikus kiegészítés szolgáltatásnál.';
    $Lang->{'Use group functionality for quick close.'} = 'Csoportfunkcionalitás használata a gyors lezárásnál.';
    $Lang->{'No'} = 'Nem';
    $Lang->{'Yes'} = 'Igen';
    $Lang->{'Labels for groups.'} = 'Címkék a csoportokhoz.';


    # Kernel/Modules/AgentTicketCloseBulk.pm
    $Lang->{'Close'} = 'Lezárás';
    $Lang->{'No TicketID is given!'} = 'Nincs jegyazonosító megadva!';
    $Lang->{'Please contact the admin.'} = 'Vegye fel a kapcsolatot a rendszergazdával.';
    $Lang->{'No QuickClose data found!'} = 'Nem található gyors lezárás adat!';
    $Lang->{'No Access to these Tickets (IDs: %s)'} = 'Nincs hozzáférés ezekhez a jegyekhez (azonosítók: %s)';

    # Kernel/Output/HTML/Templates/Standard/QuickCloseSnippetTicketView.tt
    $Lang->{'QuickClose ticket'} = 'Jegy gyors lezárása';

    # Kernel/Output/HTML/Templates/Standard/AdminQuickCloseList.tt
    $Lang->{'QuickClose Management'} = 'Gyors lezárás kezelés';
    $Lang->{'Actions'} = 'Műveletek';
    $Lang->{'Add text'} = 'Szöveg hozzáadása';
    $Lang->{'List'} = 'Lista';
    $Lang->{'Name'} = 'Név';
    $Lang->{'State'} = 'Állapot';
    $Lang->{'Valid'} = 'Érvényes';
    $Lang->{'Date'} = 'Dátum';
    $Lang->{'Author'} = 'Szerző';
    $Lang->{'Action'} = 'Művelet';
    $Lang->{'No matches found.'} = 'Nincs találat.';
    $Lang->{'edit'} = 'szerkesztés';
    $Lang->{'delete'} = 'törlés';

    # Kernel/Output/HTML/Templates/Standard/AdminQuickCloseUserSearch.tt
    $Lang->{'Search Agent'} = 'Ügyintéző keresése';

    # Kernel/Output/HTML/Templates/Standard/AdminQuickCloseForm.tt
    $Lang->{'Go to overview'} = 'Ugrás az áttekintőhöz';
    $Lang->{'Add/Change QuickClose texts'} = 'Gyors lezárás szövegek hozzáadása vagy megváltoztatása';
    $Lang->{'A name for the QuickClose text is required.'} = 'Egy név kötelező a gyors lezárás szöveghez.';
    $Lang->{'Role'} = 'Szerep';
    $Lang->{'Group'} = 'Csoport';
    $Lang->{'Subject'} = 'Tárgy';
    $Lang->{'Body'} = 'Törzs';
    $Lang->{'A body text is required.'} = 'A törzs szövege kötelező.';
    $Lang->{'Time units'} = 'Időegységek';
    $Lang->{'State after close'} = 'Állapot a lezárás után';
    $Lang->{'Pending Diff (in minutes)'} = 'Várakozási különbség (percben)';
    $Lang->{'Fix Hour:Minute for pending time'} = 'Óra:Perc javítása a várakozási időnél';
    $Lang->{'Priority'} = 'Prioritás';
    $Lang->{'Owner'} = 'Tulajdonos';
    $Lang->{'Invalid User.'} = 'Érvénytelen felhasználó.';
    $Lang->{'Responsible'} = 'Felelős';
    $Lang->{'Acting user should become ticket owner'} = 'Az eljáró felhasználónak jegytulajdonossá kell válnia';
    $Lang->{'Responsible should become ticket owner'} = 'A felelősnek jegytulajdonossá kell válnia';
    $Lang->{'Unlock Ticket'} = 'Jegy feloldása';
    $Lang->{'Tickets are unlocked automatically on \'closed\' states'} = 'A jegyek automatikusan fel lesznek oldva a „lezárt” állapotoknál';
    $Lang->{'Validity'} = 'Érvényesség';
    $Lang->{'Article Type'} = 'Bejegyzéstípus';
    $Lang->{'Queue'} = 'Várólista';
    $Lang->{'Show ticket Zoom after QuickClose'} = 'Jegynagyítás megjelenítése a gyors lezárás után';
    $Lang->{'Save'} = 'Mentés';
    $Lang->{'or'} = 'vagy';
    $Lang->{'Cancel'} = 'Mégse';

    return 1;
}

1;
