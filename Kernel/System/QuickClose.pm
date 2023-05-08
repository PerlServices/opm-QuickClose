# --
# Copyright (C) 2011 - 2023 Perl-Services.de, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::QuickClose;

use strict;
use warnings;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Encode
    Kernel::System::Log
    Kernel::System::Main
    Kernel::System::DB
    Kernel::System::User
    Kernel::System::Valid
    Kernel::System::State
    Kernel::System::Queue
    Kernel::System::Priority
    Kernel::System::QuickClose::Permission
);

=head1 NAME

Kernel::System::QuickClose

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

=item QuickCloseAdd()

to add a news 

    my $ID = $QuickCloseObject->QuickCloseAdd(
        Name          => 'A name for the news',
        StateID       => 'A state_id for the news',
        Body          => 'Anything is happened',
        Subject       => 'A subject',
        ArticleTypeID => 1,
        ValidID       => 1,
        UserID        => 123,
        QueueID       => 123,
        Permission    => {
            RoleID => [ 1,2,3 ],
        },
    );

=cut

sub QuickCloseAdd {
    my ( $Self, %Param ) = @_;

    my $LogObject        = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject         = $Kernel::OM->Get('Kernel::System::DB');
    my $PermissionObject = $Kernel::OM->Get('Kernel::System::QuickClose::Permission');

    # check needed stuff
    for my $Needed (qw(Name ValidID UserID ArticleType)) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    $Param{QueueID}                 ||= 0;
    $Param{OwnerID}                 ||= 0;
    $Param{ResponsibleID}           ||= 0;
    $Param{PriorityID}              ||= 0;
    $Param{PendingDiff}             ||= 0;
    $Param{ForceCurrentUserAsOwner} ||= 0;
    $Param{AssignToResponsible}     ||= 0;
    $Param{Unlock}                  ||= 0;
    $Param{StateID}                 ||= 0;
    $Param{ShowTicketZoom}          ||= 0;
    $Param{TimeUnits}               ||= 0;
    $Param{ToAddress}               ||= '';
    $Param{ToType}                  ||= '';
    $Param{Body}                    ||= '';
    $Param{ArticleCustomer}         ||= 0;
    $Param{FixHour}                 ||= 0;

    # insert new news
    return if !$DBObject->Do(
        SQL => 'INSERT INTO ps_quick_close '
            . '(close_name, state_id, body, create_time, create_by, valid_id, '
            . ' article_type, article_customer, change_time, change_by, comments, queue_id, '
            . ' subject, ticket_unlock, owner_id, pending_diff, force_owner_change, '
            . ' assign_to_responsible, show_ticket_zoom, fix_hour, group_name,'
            . ' responsible_id, priority_id, time_units, to_address, to_type) '
            . 'VALUES (?, ?, ?, current_timestamp, ?, ?, ?, ?, current_timestamp, '
            . ' ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        Bind => [
            \$Param{Name},
            \$Param{StateID},
            \$Param{Body},
            \$Param{UserID},
            \$Param{ValidID},
            \$Param{ArticleType},
            \$Param{ArticleCustomer},
            \$Param{UserID},
            \' ', # empty comment as we have no comments field
            \$Param{QueueID},
            \$Param{Subject},
            \$Param{Unlock},
            \$Param{OwnerID},
            \$Param{PendingDiff},
            \$Param{ForceCurrentUserAsOwner},
            \$Param{AssignToResponsible},
            \$Param{ShowTicketZoom},
            \$Param{FixHour},
            \$Param{Group},
            \$Param{ResponsibleID},
            \$Param{PriorityID},
            \$Param{TimeUnits},
            \$Param{ToAddress},
            \$Param{ToType},
        ],
    );

    # get new invoice id
    return if !$DBObject->Prepare(
        SQL   => 'SELECT MAX(id) FROM ps_quick_close WHERE close_name = ?',
        Bind  => [ \$Param{Name}, ],
        Limit => 1,
    );

    my $ID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ID = $Row[0];
    }

    # log notice
    $LogObject->Log(
        Priority => 'notice',
        Message  => "QuickClose '$ID' created successfully ($Param{UserID})!",
    );

    $PermissionObject->PermissionSet(
        QuickCloseID => $ID,
        RoleID       => $Param{Permission}->{RoleID},
    );

    return $ID;
}


=item QuickCloseUpdate()

to update news 

    my $Success = $QuickCloseObject->QuickCloseUpdate(
        ID            => 3,
        Name          => 'A name for the news',
        StateID       => 'A state_id for the news',
        Subject       => 'A subject',
        Body          => 'Anything is happened',
        ArticleTypeID => 1,
        ValidID       => 1,
        UserID        => 123,
        QueueID       => 123,
        Permission    => {
            RoleID => [ 1,2,3 ],
        },
    );

=cut

sub QuickCloseUpdate {
    my ( $Self, %Param ) = @_;

    my $LogObject        = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject         = $Kernel::OM->Get('Kernel::System::DB');
    my $PermissionObject = $Kernel::OM->Get('Kernel::System::QuickClose::Permission');

    # check needed stuff
    for my $Needed (qw(ID Name ValidID UserID ArticleType)) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    $Param{QueueID}                 ||= 0;
    $Param{OwnerID}                 ||= 0;
    $Param{ResponsibleID}           ||= 0;
    $Param{PriorityID}              ||= 0;
    $Param{PendingDiff}             ||= 0;
    $Param{ForceCurrentUserAsOwner} ||= 0;
    $Param{AssignToResponsible}     ||= 0;
    $Param{ArticleCustomer}         ||= 0;
    $Param{Unlock}                  ||= 0;
    $Param{StateID}                 ||= 0;
    $Param{ShowTicketZoom}          ||= 0;
    $Param{TimeUnits}               ||= 0;
    $Param{ToType}                  ||= '';
    $Param{ToAddress}               ||= '';
    $Param{Body}                    ||= '';
    $Param{FixHour}                 ||= 0;

    # insert new news
    return if !$DBObject->Do(
        SQL => 'UPDATE ps_quick_close SET close_name = ?, state_id = ?, body = ?, '
            . 'valid_id = ?, change_time = current_timestamp, change_by = ?, article_type = ?, '
            . 'queue_id = ?, subject = ?, ticket_unlock = ?, owner_id = ?, pending_diff = ?, '
            . 'force_owner_change = ?, assign_to_responsible = ?, show_ticket_zoom = ?, '
            . 'fix_hour = ?, group_name = ?, responsible_id = ?, priority_id = ?, time_units = ?, '
            . 'to_address = ?, to_type = ?, article_customer = ? '
            . 'WHERE id = ?',
        Bind => [
            \$Param{Name},
            \$Param{StateID},
            \$Param{Body},
            \$Param{ValidID},
            \$Param{UserID},
            \$Param{ArticleType},
            \$Param{QueueID},
            \$Param{Subject},
            \$Param{Unlock},
            \$Param{OwnerID},
            \$Param{PendingDiff},
            \$Param{ForceCurrentUserAsOwner},
            \$Param{AssignToResponsible},
            \$Param{ShowTicketZoom},
            \$Param{FixHour},
            \$Param{Group},
            \$Param{ResponsibleID},
            \$Param{PriorityID},
            \$Param{TimeUnits},
            \$Param{ToAddress},
            \$Param{ToType},
            \$Param{ArticleCustomer},
            \$Param{ID},
        ],
    );

    $PermissionObject->PermissionSet(
        QuickCloseID => $Param{ID},
        RoleID       => $Param{Permission}->{RoleID},
    );

    return 1;
}

=item QuickCloseGet()

returns a hash with news data

    my %QuickCloseData = $QuickCloseObject->QuickCloseGet( ID => 2 );

This returns something like:

    %QuickCloseData = (
        'ID'            => 2,
        'Name'          => 'This is the name',
        'StateID'       => 'A short abstract',
        'Body'          => 'This is the long text of the news',
        'Subject'       => 'A subject',
        'ArticleTypeID' => 3,
        'CreateTime'    => '2010-04-07 15:41:15',
        'CreateBy'      => 123,
        'QueueID'       => 123,
        'Unlock'        => 1,
        Permission      => {
            RoleID => [ 1,2,3 ],
        },
    );

=cut

sub QuickCloseGet {
    my ( $Self, %Param ) = @_;

    my $LogObject        = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject         = $Kernel::OM->Get('Kernel::System::DB');
    my $ValidObject      = $Kernel::OM->Get('Kernel::System::Valid');
    my $UserObject       = $Kernel::OM->Get('Kernel::System::User');
    my $StateObject      = $Kernel::OM->Get('Kernel::System::State');
    my $QueueObject      = $Kernel::OM->Get('Kernel::System::Queue');
    my $PriorityObject   = $Kernel::OM->Get('Kernel::System::Priority');
    my $PermissionObject = $Kernel::OM->Get('Kernel::System::QuickClose::Permission');

    # check needed stuff
    if ( !$Param{ID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need ID!',
        );
        return;
    }

    # sql
    return if !$DBObject->Prepare(
        SQL => 'SELECT id, close_name, state_id, body, create_time, create_by, valid_id, '
            . 'article_type, queue_id, subject, ticket_unlock, owner_id, pending_diff, '
            . 'force_owner_change, assign_to_responsible, show_ticket_zoom, fix_hour, group_name, '
            . 'responsible_id, priority_id, time_units, to_address, to_type, article_customer '
            . 'FROM ps_quick_close WHERE id = ?',
        Bind  => [ \$Param{ID} ],
        Limit => 1,
    );

    my %QuickClose;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        %QuickClose = (
            ID            => $Data[0],
            Name          => $Data[1],
            StateID       => $Data[2],
            Body          => $Data[3],
            CreateTime    => $Data[4],
            CreateBy      => $Data[5],
            ValidID       => $Data[6],
            ArticleType   => $Data[7],
            QueueID       => $Data[8],
            Subject       => $Data[9],
            Unlock        => $Data[10],
            OwnerID       => $Data[11],
            PendingDiff   => $Data[12],

            ForceCurrentUserAsOwner => $Data[13],
            AssignToResponsible     => $Data[14],
            ShowTicketZoom          => $Data[15],
            FixHour                 => $Data[16],
            Group                   => $Data[17],
            ResponsibleID           => $Data[18],
            PriorityID              => $Data[19],
            TimeUnits               => $Data[20],
            ToAddress               => $Data[21] || '',
            ToType                  => $Data[22] || '',
            ArticleCustomer         => $Data[23] || 0,
        );
    }

    $QuickClose{Valid}  = $ValidObject->ValidLookup( ValidID => $QuickClose{ValidID} );
    $QuickClose{Author} = $UserObject->UserLookup( UserID => $QuickClose{CreateBy} );

    if ( $QuickClose{StateID} ) {
        $QuickClose{State}  = $StateObject->StateLookup( StateID => $QuickClose{StateID} );
    }

    if ( $QuickClose{QueueID} ) {
        $QuickClose{Queue}  = $QueueObject->QueueLookup( QueueID => $QuickClose{QueueID} );
    }

    if ( $QuickClose{OwnerID} ) {
        $QuickClose{Owner}  = $UserObject->UserLookup( UserID => $QuickClose{OwnerID} );
    }

    if ( $QuickClose{ResponsibleID} ) {
        $QuickClose{Responsible} = $UserObject->UserLookup( UserID => $QuickClose{ResponsibleID} );
    }

    if ( $QuickClose{PriorityID} ) {
        $QuickClose{Priority} = $PriorityObject->PriorityLookup( PriorityID => $QuickClose{PriorityID} );
    }

    $QuickClose{Permission} = $PermissionObject->PermissionGet(
        QuickCloseID => $Param{ID},
    );

    return %QuickClose;
}

=item QuickCloseDelete()

deletes a news entry. Returns 1 if it was successful, undef otherwise.

    my $Success = $QuickCloseObject->QuickCloseDelete(
        ID => 123,
    );

=cut

sub QuickCloseDelete {
    my ( $Self, %Param ) = @_;

    my $LogObject        = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject         = $Kernel::OM->Get('Kernel::System::DB');
    my $PermissionObject = $Kernel::OM->Get('Kernel::System::QuickClose::Permission');

    # check needed stuff
    if ( !$Param{ID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need ID!',
        );
        return;
    }

    $PermissionObject->PermissionDelete(
        QuickCloseID => $Param{ID},
    );

    return $DBObject->Do(
        SQL  => 'DELETE FROM ps_quick_close WHERE id = ?',
        Bind => [ \$Param{ID} ],
    );
}


=item QuickCloseList()

returns a hash of all news

    my %QuickCloses = $QuickCloseObject->QuickCloseList(
        Valid => 1,
    );

the result looks like

    %QuickCloses = (
        '1' => 'QuickClose 1',
        '2' => 'Test QuickClose',
    );

to restrict by role_ids:

    my %QuickCloses = $QuickCloseObject->QuickCloseList(
        Valid => 1,
        Permission => {
            RoleID => [1,2,3],
        },
    );

=cut

sub QuickCloseList {
    my ( $Self, %Param ) = @_;

    my $ValidObject  = $Kernel::OM->Get('Kernel::System::Valid');
    my $DBObject     = $Kernel::OM->Get('Kernel::System::DB');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $Join  = '';
    my @Where;
    my @Bind;

    if ( $Param{Valid} ) {
        my $ValidID = $ValidObject->ValidLookup( Valid => 'valid' );
        push @Where, 'valid_id = ?';
        @Bind  = ( \$ValidID );
    }

    if ( $Param{Permission} ) { #&& @{ $Param{Permission}->{RoleID} // [] } ) {
        $Join = q~
            LEFT OUTER JOIN ps_quick_close_perm pqcp
                ON pqc.id = pqcp.quick_close_id
                    AND pqcp.perm_type = 'Role'~;

        my $TypeIDIn = '';
        if ( @{ $Param{Permission}->{RoleID} // [] } ) {
            my $Placeholder = join ', ', ('?') x @{ $Param{Permission}->{RoleID} };
            $TypeIDIn = " OR pqcp.type_id IN ($Placeholder)";
            push @Bind, map{ \$_ }@{ $Param{Permission}->{RoleID} };
        }

        push @Where, "( pqcp.type_id IS NULL $TypeIDIn )";
    }

    my $Where = @Where ? ' WHERE ' . join ' AND ', @Where : '';

    # sql
    return if !$DBObject->Prepare(
        SQL  => "SELECT id, close_name, group_name FROM ps_quick_close pqc $Join $Where",
        Bind => \@Bind,
    );

    my $GroupElements = $ConfigObject->Get('QuickClose::UseGroups');

    my %QuickClose;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        if ( $GroupElements && $Param{GroupBy} ) { 
            $QuickClose{ $Data[2] // '' }->{ $Data[0] } = $Data[1];
        }
        else {
            $QuickClose{ $Data[0] } = $Data[1];
        }
    }

    return %QuickClose;
}

sub TicketStateTypeByStateGet {
    my ($Self, %Param) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    for my $Needed (qw(StateID)) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );

            return;
        }
    }

    my $SQL = 'SELECT tst.name FROM ticket_state_type tst '
        . ' INNER JOIN ticket_state ts ON tst.id = ts.type_id '
        . ' WHERE ts.id = ?';

    return if !$DBObject->Prepare(
        SQL   => $SQL,
        Bind  => [ \$Param{StateID} ],
        Limit => 1,
    );

    my $Type;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Type = $Row[0];
    }

    return $Type;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

