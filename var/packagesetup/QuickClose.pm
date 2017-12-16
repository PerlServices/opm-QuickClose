# --
# Copyright (C) 2017 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package var::packagesetup::QuickClose;

use strict;
use warnings;

use utf8;

use File::Basename;
use List::Util qw(first);
use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::SysConfig
    Kernel::System::Valid
    Kernel::System::DynamicField
);

=head1 NAME

TicketAttachments.pm - code to excecute during package installation

=head1 SYNOPSIS

All functions

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item CodeInstall()

run the code install part

    my $Result = $CodeObject->CodeInstall();

=cut

sub CodeInstall {
    my ( $Self, %Param ) = @_;

    return 1;
}

=item CodeReinstall()

run the code reinstall part

    my $Result = $CodeObject->CodeReinstall();

=cut

sub CodeReinstall {
    my ( $Self, %Param ) = @_;

    return 1;
}

=item CodeUpgrade()

run the code upgrade part

    my $Result = $CodeObject->CodeUpgrade();

=cut

sub CodeUpgrade {
    my ( $Self, %Param ) = @_;

    return 1;
}

=item CodeUninstall()

run the code uninstall part

    my $Result = $CodeObject->CodeUninstall();

=cut

sub CodeUninstall {
    my ( $Self, %Param ) = @_;

    return 1;
}

sub CodeUpgrade_6_0_1 {
    my ( $Self, %Param ) = @_;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    my %TypeIDToName = (
        1  => ['email-external', 'Email', 1 ],
        2  => ['email-internal', 'Email', 0 ],
        3  => ['email-notification-ext', 'Email', 1 ],
        4  => ['email-notification-int', 'Email', 0 ],
        5  => ['phone', 'Phone', 0],
        6  => ['fax', 'Phone', 0],
        7  => ['sms', 'Phone', 0],
        8  => ['webrequest', 'Internal', 0 ],
        9  => ['note-internal', 'Internal', 0 ],
        10 => ['note-external', 'Internal', 1 ],
    );

    my $Select = q~SELECT id, article_type_id FROM ps_quick_close~;
    $DBObject->Prepare(
        SQL => $Select,
    );

    my %NewData;

    ROW:
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my ($Name, $Channel, $Viewable) = @{ $TypeIDToName{ $Row[1] } || [] };
        next ROW if !$Name;

        $NewData{$Row[0]} = {
            ArticleType     => $Channel,
            ArticleCustomer => $Viewable,
        };
    }

    my $Update = q~
        UPDATE ps_quick_close SET article_type = ?, article_customer = ? WHERE id = ?
    ~;

    for my $ID ( sort keys %NewData ) {
        my @Bind = ( @{ $NewData{$ID} }{qw/ArticleType ArticleCustomer/}, $ID );

        $DBObject->Do(
            SQL  => $Update,
            Bind => [ map { \$_ }@Bind ],
        );
    }

    # Delete table column
    my $Delete = q~ALTER TABLE ps_quick_close DROP COLUMN article_type_id~;
    $DBObject->Do(
        SQL => $Delete,
    );

    return 1;
}

1;


=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

