# --
# Kernel/Modules/AgentTicketCloseBulk.pm - bulk closing of tickets
# Copyright (C) 2012-2013 Perl-Services.de, http://perl-services.de
# --
# $Id: AgentTicketCloseBulk.pm,v 1.16 2011/08/26 06:45:08 ub Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentTicketCloseBulk;

use strict;
use warnings;

use Kernel::System::State;
use Kernel::System::Web::UploadCache;
use Kernel::System::QuickClose;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check needed objects
    for my $Needed (
        qw(ParamObject DBObject TicketObject LayoutObject LogObject QueueObject ConfigObject TimeObject)
        )
    {
        if ( !$Self->{$Needed} ) {
            $Self->{LayoutObject}->FatalError( Message => "Got no $Needed!" );
        }
    }

    $Self->{StateObject}       = Kernel::System::State->new(%Param);
    $Self->{UploadCacheObject} = Kernel::System::Web::UploadCache->new(%Param);
    $Self->{QuickCloseObject}  = Kernel::System::QuickClose->new(%Param);

    # get form id
    $Self->{FormID} = $Self->{ParamObject}->GetParam( Param => 'FormID' );

    # create form id
    if ( !$Self->{FormID} ) {
        $Self->{FormID} = $Self->{UploadCacheObject}->FormIDCreate();
    }

    # get config of frontend module
    $Self->{Config} = $Self->{ConfigObject}->Get("Ticket::Frontend::AgentTicketClose");

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my @TicketIDs = $Self->{ParamObject}->GetArray( Param => 'TicketID' );
    my $ID        = $Self->{ParamObject}->GetParam( Param => 'QuickClose' );

    my %GetParam;
    for my $WebParam ( qw(Subject) ) {
        $GetParam{$WebParam} = $Self->{ParamObject}->GetParam( Param => $WebParam ) || '';
    }

    if ( !$GetParam{Subject} ) {
        $GetParam{Subject} =
            $Self->{ConfigObject}->Get( 'QuickClose::DefaultSubject' ) ||
            $Self->{LayoutObject}->{LanguageObject}->Get( 'Close' );
    }

    # check needed stuff
    if ( !@TicketIDs ) {
        return $Self->{LayoutObject}->ErrorScreen(
            Message => 'No TicketID is given!',
            Comment => 'Please contact the admin.',
        );
    }

    if ( !$ID ) {
        $ID = $Self->{ConfigObject}->Get( 'QuickClose::DefaultID' ) || 1;
    }

    # get QuickClose data
    my %CloseData = $Self->{QuickCloseObject}->QuickCloseGet( ID => $ID );

    if ( !%CloseData ) {
        return $Self->{LayoutObject}->ErrorScreen(
            Message => 'No QuickClose data found!',
            Comment => 'Please contact the admin.',
        );
    }

    delete $CloseData{Subject} if !length $CloseData{Subject};

    my @NoAccess;

    TICKETID:
    for my $TicketID ( @TicketIDs ) {

        # check permissions
        my $Access = $Self->{TicketObject}->TicketPermission(
            Type     => $Self->{Config}->{Permission},
            TicketID => $TicketID,
            UserID   => $Self->{UserID}
        );

        # error screen, don't show ticket
        if ( !$Access ) {
            push @NoAccess, $TicketID;
            next TICKETID;
        }

        # challenge token check for write action
        $Self->{LayoutObject}->ChallengeTokenCheck();

        # add note
        my $ArticleID = '';
        my $MimeType = 'text/plain';
        if ( $Self->{LayoutObject}->{BrowserRichText} ) {
            $MimeType = 'text/html';

            # verify html document
            $CloseData{Body} = $Self->{LayoutObject}->RichTextDocumentComplete(
                String => $CloseData{Body},
            );
        }

        my $From = "$Self->{UserFirstname} $Self->{UserLastname} <$Self->{UserEmail}>"; 
        $ArticleID = $Self->{TicketObject}->ArticleCreate(
            TicketID       => $TicketID,
            SenderType     => 'agent',
            From           => $From,
            MimeType       => $MimeType,
            Charset        => $Self->{LayoutObject}->{UserCharset},
            UserID         => $Self->{UserID},
            HistoryType    => $Self->{Config}->{HistoryType}, 
            HistoryComment => $Self->{Config}->{HistoryComment}, 
            ArticleTypeID  => $CloseData{ArticleTypeID},
            %GetParam,
            %CloseData,
        );
        if ( !$ArticleID ) {
            return $Self->{LayoutObject}->ErrorScreen();
        }

        if ( $Self->{ConfigObject}->Get( 'QuickClose::QueueMove' ) && $CloseData{QueueID} ) {
            $Self->{TicketObject}->TicketQueueSet(
                TicketID => $TicketID,
                QueueID  => $CloseData{QueueID},
                UserID   => $Self->{UserID},
            );
        }

        if ( $CloseData{ForceCurrentUserAsOwner} ) {
            $Self->{TicketObject}->TicketOwnerSet(
                TicketID  => $TicketID,
                NewUserID => $Self->{UserID},
                UserID    => $Self->{UserID},
            );
        }
        if ( $CloseData{OwnerID} ) {
            $Self->{TicketObject}->TicketOwnerSet(
                TicketID  => $TicketID,
                NewUserID => $CloseData{OwnerID},
                UserID    => $Self->{UserID},
            );
        }

        # set state
        $Self->{TicketObject}->TicketStateSet(
            TicketID => $TicketID,
            StateID  => $CloseData{StateID},
            UserID   => $Self->{UserID},
        );

        my $Type = $Self->{QuickCloseObject}->TicketStateTypeByStateGet(
            StateID => $CloseData{StateID},
        );

        if ( $Type =~ m{^pending}xms ) {
            my $Diff = $CloseData{PendingDiff} ||
                $Self->{ConfigObject}->Get( 'QuickClose::PendingDiffDefault' ) ||
                ( 1 * 24 * 60 );

            my ($Sec, $Min, $Hour, $Day, $Month, $Year) = $Self->{TimeObject}->SystemTime2Date(
                SystemTime => $Self->{TimeObject}->SystemTime() + ( $Diff * 60 ),
            );

            $Self->{TicketObject}->TicketPendingTimeSet(
                Year     => $Year,
                Month    => $Month,
                Day      => $Day,
                Hour     => $Hour,
                Minute   => $Min,
                TicketID => $TicketID,
                UserID   => $Self->{UserID},
            );
        }

        # set unlock on close state
        if ( $Type =~ /^close/i ) {
            $Self->{TicketObject}->TicketLockSet(
                TicketID => $TicketID,
                Lock     => 'unlock',
                UserID   => $Self->{UserID},
            );
        }
    }

    # redirect parent window to last screen overview on closed tickets
    if ( !@NoAccess ) {
        my $LastView = $Self->{LastScreenOverview} || $Self->{LastScreenView} || 'Action=AgentDashboard';

        return $Self->{LayoutObject}->Redirect(
            OP => $LastView,
        );

    }
    else {
        return $Self->{LayoutObject}->ErrorScreen(
            Message => 'No Access to these Tickets (IDs: ' . join( ", ", @NoAccess ) . ')',
            Comment => 'Please contact the admin.',
        );
    }
}

1;
