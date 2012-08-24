# --
# Kernel/System/QuickClose.pm - All QuickClose related functions should be here eventually
# Copyright (C) 2011 Perl-Services.de, http://www.perl-services.de
# --
# $Id: QuickClose.pm,v 1.1.1.1 2011/04/15 07:49:58 rb Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::QuickClose;

use strict;
use warnings;

use Kernel::System::User;
use Kernel::System::Valid;
use Kernel::System::State;
use Kernel::System::Queue;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.1.1.1 $) [1];

=head1 NAME

Kernel::System::QuickClose - backend for product news

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::Main;
    use Kernel::System::DB;
    use Kernel::System::QuickClose;

    my $ConfigObject = Kernel::Config->new();
    my $EncodeObject = Kernel::System::Encode->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
    );
    my $MainObject = Kernel::System::Main->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
    );
    my $DBObject = Kernel::System::DB->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
        MainObject   => $MainObject,
    );
    my $QuickCloseObject = Kernel::System::QuickClose->new(
        ConfigObject => $ConfigObject,
        LogObject    => $LogObject,
        DBObject     => $DBObject,
        MainObject   => $MainObject,
        EncodeObject => $EncodeObject,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $Object (qw(DBObject ConfigObject MainObject LogObject EncodeObject TimeObject)) {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    # create needed objects
    $Self->{UserObject}  = Kernel::System::User->new( %{$Self} );
    $Self->{ValidObject} = Kernel::System::Valid->new( %{$Self} );
    $Self->{StateObject} = Kernel::System::State->new( %{$Self} );
    $Self->{QueueObject} = Kernel::System::Queue->new( %{$Self} );
    
    return $Self;
}

=item QuickCloseAdd()

to add a news 

    my $ID = $QuickCloseObject->QuickCloseAdd(
        Name          => 'A name for the news',
        StateID       => 'A state_id for the news',
        Body          => 'Anything is happened',
        ArticleTypeID => 1,
        ValidID       => 1,
        UserID        => 123,
        QueueID       => 123,
    );

=cut

sub QuickCloseAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Name StateID Body ValidID UserID ArticleTypeID)) {
        if ( !$Param{$Needed} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    $Param{QueueID} ||= 0;

    # insert new news
    return if !$Self->{DBObject}->Do(
        SQL => 'INSERT INTO ps_quick_close '
            . '(close_name, state_id, body, create_time, create_by, valid_id, '
            . ' article_type_id, change_time, change_by, comments, queue_id) '
            . 'VALUES (?, ?, ?, current_timestamp, ?, ?, ?, current_timestamp, ?, ?, ?)',
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
        ],
    );

    # get new invoice id
    return if !$Self->{DBObject}->Prepare(
        SQL   => 'SELECT MAX(id) FROM ps_quick_close WHERE close_name = ?',
        Bind  => [ \$Param{Name}, ],
        Limit => 1,
    );

    my $ID;
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        $ID = $Row[0];
    }

    # log notice
    $Self->{LogObject}->Log(
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
        Body          => 'Anything is happened',
        ArticleTypeID => 1,
        ValidID       => 1,
        UserID        => 123,
        QueueID       => 123,
    );

=cut

sub QuickCloseUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ID Name StateID Body ValidID UserID ArticleTypeID)) {
        if ( !$Param{$Needed} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    $Param{QueueID} ||= 0;

    # insert new news
    return if !$Self->{DBObject}->Do(
        SQL => 'UPDATE ps_quick_close SET close_name = ?, state_id = ?, body = ?, '
            . 'valid_id = ?, change_time = current_timestamp, change_by = ?, article_type_id = ?, '
            . 'queue_id = ? '
            . 'WHERE id = ?',
        Bind => [
            \$Param{Name},
            \$Param{StateID},
            \$Param{Body},
            \$Param{ValidID},
            \$Param{UserID},
            \$Param{ArticleTypeID},
            \$Param{QueueID},
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
        'ArticleTypeID' => 3,
        'CreateTime'    => '2010-04-07 15:41:15',
        'CreateBy'      => 123,
        'QueueID'       => 123,
    );

=cut

sub QuickCloseGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ID} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need ID!',
        );
        return;
    }

    # sql
    return if !$Self->{DBObject}->Prepare(
        SQL => 'SELECT id, close_name, state_id, body, create_time, create_by, valid_id, '
            . 'article_type_id, queue_id '
            . 'FROM ps_quick_close WHERE id = ?',
        Bind  => [ \$Param{ID} ],
        Limit => 1,
    );

    my %QuickClose;
    while ( my @Data = $Self->{DBObject}->FetchrowArray() ) {
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
        );
    }

    $QuickClose{Valid}  = $Self->{ValidObject}->ValidLookup( ValidID => $QuickClose{ValidID} );
    $QuickClose{Author} = $Self->{UserObject}->UserLookup( UserID => $QuickClose{CreateBy} );
    $QuickClose{State}  = $Self->{StateObject}->StateLookup( StateID => $QuickClose{StateID} );

    if ( $QuickClose{QueueID} ) {
        $QuickClose{Queue}  = $Self->{QueueObject}->QueueLookup( QueueID => $QuickClose{QueueID} );
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

    # check needed stuff
    if ( !$Param{ID} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need ID!',
        );
        return;
    }

    return $Self->{DBObject}->Do(
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

    my $Where = '';
    my @Bind;

    if ( $Param{Valid} ) {
        my $ValidID = $Self->{ValidObject}->ValidLookup( Valid => 'valid' );
        $Where = 'WHERE valid_id = ?';
        @Bind  = ( \$ValidID );
    }

    # sql
    return if !$Self->{DBObject}->Prepare(
        SQL  => "SELECT id, close_name FROM ps_quick_close $Where",
        Bind => \@Bind,
    );

    my %QuickClose;
    while ( my @Data = $Self->{DBObject}->FetchrowArray() ) {
        $QuickClose{ $Data[0] } = $Data[1];
    }

    return %QuickClose;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

=head1 VERSION

$Revision: 1.1.1.1 $ $Date: 2011/04/15 07:49:58 $

=cut
