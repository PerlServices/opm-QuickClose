# --
# Kernel/System/QuickClose/Permission.pm - All QuickClose related functions should be here eventually
# Copyright (C) 2015 - 2022 Perl-Services.de, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::QuickClose::Permission;

use strict;
use warnings;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Log
    Kernel::System::DB
);

=head1 NAME

Kernel::System::QuickClose::Permission

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

=item PermissionSet()

    $Object->PermissionSet(
        QuickCloseID => 1,
        RoleID       => [ 1,2,3 ],
    );

=cut

sub PermissionSet {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    for my $Needed ( qw(QuickCloseID) ) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );

            return;
        }
    }

    $Self->PermissionDelete(
        QuickCloseID => $Param{QuickCloseID},
    );

    ROLEID:
    for my $RoleID ( @{ $Param{RoleID} || [] } ) {
        next ROLEID if !$DBObject->Do(
            SQL => 'INSERT INTO ps_quick_close_perm '
                . '(quick_close_id, perm_type, type_id) '
                . 'VALUES (?, ?, ?)',
            Bind => [
                \$Param{QuickCloseID},
                \'Role',
                \$RoleID,
            ],
        );
    }

    return 1;
}


=item PermissionGet()

    my $Permissions = $Object->PermissionGet(
        QuickCloseID => 3,
    );

returns

    {
        RoleID => [ 1,2,3 ],
    }

=cut

sub PermissionGet {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    # check needed stuff
    for my $Needed (qw(QuickCloseID)) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );

            return {};
        }
    }

    return {} if !$DBObject->Prepare(
        SQL => 'SELECT quick_close_id, perm_type, type_id '
            . ' FROM ps_quick_close_perm '
            . 'WHERE quick_close_id = ?'
            . 'ORDER BY perm_type, type_id',
        Bind => [
            \$Param{QuickCloseID},
        ],
    );

    my %Permissions;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my ($Type) = $Row[1];
        my ($ID)   = $Row[2];
        push @{ $Permissions{$Type} }, $ID;
    }

    return \%Permissions;
}

=item PermissionDelete()

    my $Success = $Object->PermissionDelete(
        QuickCloseID => 123,
    );

=cut

sub PermissionDelete {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    # check needed stuff
    if ( !$Param{QuickCloseID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need QuickCloseID!',
        );
        return;
    }

    return $DBObject->Do(
        SQL  => 'DELETE FROM ps_quick_close_perm WHERE quick_close_id = ?',
        Bind => [ \$Param{QuickCloseID} ],
    );
}

1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

