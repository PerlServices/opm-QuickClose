# --
# Kernel/System/QuickClose.pm - All QuickClose related functions should be here eventually
# Copyright (C) 2011-2014 Perl-Services.de, http://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::QuickClose;

use strict;
use warnings;

our $VERSION = 0.02;

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
);

=head1 NAME

Kernel::System::QuickClose - backend for product news

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
    );

=cut

sub QuickCloseAdd {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    # check needed stuff
    for my $Needed (qw(Name StateID Body ValidID UserID ArticleTypeID)) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    $Param{QueueID}     ||= 0;
    $Param{OwnerID}     ||= 0;
    $Param{PendingDiff} ||= 0;

    # insert new news
    return if !$DBObject->Do(
        SQL => 'INSERT INTO ps_quick_close '
            . '(close_name, state_id, body, create_time, create_by, valid_id, '
            . ' article_type_id, change_time, change_by, comments, queue_id, '
            . ' subject, ticket_unlock, owner_id, pending_diff) '
            . 'VALUES (?, ?, ?, current_timestamp, ?, ?, ?, current_timestamp, ?, ?, ?, ?, ?, ?, ?)',
        Bind => [
            \$Param{Name},
            \$Param{StateID},
            \$Param{Body},
            \$Param{UserID},
            \$Param{ValidID},
            \$Param{ArticleTypeID},
            \$Param{UserID},
            \' ', # empty comment as we have no comments field
            \$Param{QueueID},
            \$Param{Subject},
            \$Param{Unlock},
            \$Param{OwnerID},
            \$Param{PendingDiff},
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
    );

=cut

sub QuickCloseUpdate {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    # check needed stuff
    for my $Needed (qw(ID Name StateID Body ValidID UserID ArticleTypeID)) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    $Param{QueueID}     ||= 0;
    $Param{OwnerID}     ||= 0;
    $Param{PendingDiff} ||= 0;

    # insert new news
    return if !$DBObject->Do(
        SQL => 'UPDATE ps_quick_close SET close_name = ?, state_id = ?, body = ?, '
            . 'valid_id = ?, change_time = current_timestamp, change_by = ?, article_type_id = ?, '
            . 'queue_id = ?, subject = ?, ticket_unlock = ?, owner_id = ?, pending_diff = ? '
            . 'WHERE id = ?',
        Bind => [
            \$Param{Name},
            \$Param{StateID},
            \$Param{Body},
            \$Param{ValidID},
            \$Param{UserID},
            \$Param{ArticleTypeID},
            \$Param{QueueID},
            \$Param{Subject},
            \$Param{Unlock},
            \$Param{OwnerID},
            \$Param{PendingDiff},
            \$Param{ID},
        ],
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
    );

=cut

sub QuickCloseGet {
    my ( $Self, %Param ) = @_;

    my $LogObject   = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject    = $Kernel::OM->Get('Kernel::System::DB');
    my $ValidObject = $Kernel::OM->Get('Kernel::System::Valid');
    my $UserObject  = $Kernel::OM->Get('Kernel::System::User');
    my $StateObject = $Kernel::OM->Get('Kernel::System::State');
    my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');

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
            . 'article_type_id, queue_id, subject, ticket_unlock, owner_id, pending_diff '
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
            ArticleTypeID => $Data[7],
            QueueID       => $Data[8],
            Subject       => $Data[9],
            Unlock        => $Data[10],
            OwnerID       => $Data[11],
            PendingDiff   => $Data[12],
        );
    }

    $QuickClose{Valid}  = $ValidObject->ValidLookup( ValidID => $QuickClose{ValidID} );
    $QuickClose{Author} = $UserObject->UserLookup( UserID => $QuickClose{CreateBy} );
    $QuickClose{State}  = $StateObject->StateLookup( StateID => $QuickClose{StateID} );

    if ( $QuickClose{QueueID} ) {
        $QuickClose{Queue}  = $QueueObject->QueueLookup( QueueID => $QuickClose{QueueID} );
    }

    if ( $QuickClose{OwnerID} ) {
        $QuickClose{Owner}  = $UserObject->UserLookup( UserID => $QuickClose{OwnerID} );
    }

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

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    # check needed stuff
    if ( !$Param{ID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need ID!',
        );
        return;
    }

    return $DBObject->Do(
        SQL  => 'DELETE FROM ps_quick_close WHERE id = ?',
        Bind => [ \$Param{ID} ],
    );
}


=item QuickCloseList()

returns a hash of all news

    my %QuickCloses = $QuickCloseObject->QuickCloseList();

the result looks like

    %QuickCloses = (
        '1' => 'QuickClose 1',
        '2' => 'Test QuickClose',
    );

=cut

sub QuickCloseList {
    my ( $Self, %Param ) = @_;

    my $ValidObject = $Kernel::OM->Get('Kernel::System::Valid');
    my $DBObject    = $Kernel::OM->Get('Kernel::System::DB');

    my $Where = '';
    my @Bind;

    if ( $Param{Valid} ) {
        my $ValidID = $ValidObject->ValidLookup( Valid => 'valid' );
        $Where = 'WHERE valid_id = ?';
        @Bind  = ( \$ValidID );
    }

    # sql
    return if !$DBObject->Prepare(
        SQL  => "SELECT id, close_name FROM ps_quick_close $Where",
        Bind => \@Bind,
    );

    my %QuickClose;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        $QuickClose{ $Data[0] } = $Data[1];
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

