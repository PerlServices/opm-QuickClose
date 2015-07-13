# --
# Kernel/Modules/AgentTicketCloseBulk.pm - bulk closing of tickets
# Copyright (C) 2012-2015 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentTicketCloseBulk;

use strict;
use warnings;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Log
    Kernel::System::Encode
    Kernel::System::Main
    Kernel::System::DB
    Kernel::System::State
    Kernel::System::Ticket
    Kernel::System::Queue
    Kernel::System::Time
    Kernel::System::QuickClose
    Kernel::System::Web::UploadCache
    Kernel::System::Web::Request
    Kernel::Output::HTML::Layout
    Kernel::Language
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    my $ParamObject       = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $UploadCacheObject = $Kernel::OM->Get('Kernel::System::Web::UploadCache');
    my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');

    # get form id
    $Self->{FormID} = $ParamObject->GetParam( Param => 'FormID' );

    # create form id
    if ( !$Self->{FormID} ) {
        $Self->{FormID} = $UploadCacheObject->FormIDCreate();
    }

    # get config of frontend module
    $Self->{Config} = $ConfigObject->Get("Ticket::Frontend::AgentTicketClose");

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject       = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $UploadCacheObject = $Kernel::OM->Get('Kernel::System::Web::UploadCache');
    my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
    my $LanguageObject    = $Kernel::OM->Get('Kernel::Language');
    my $LayoutObject      = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $QuickCloseObject  = $Kernel::OM->Get('Kernel::System::QuickClose');
    my $TicketObject      = $Kernel::OM->Get('Kernel::System::Ticket');
    my $TimeObject        = $Kernel::OM->Get('Kernel::System::Time');

    my @TicketIDs = $ParamObject->GetArray( Param => 'TicketID' );
    my $ID        = $ParamObject->GetParam( Param => 'QuickClose' );

    my %GetParam;
    for my $WebParam ( qw(Subject) ) {
        $GetParam{$WebParam} = $ParamObject->GetParam( Param => $WebParam ) || '';
    }

    if ( !$GetParam{Subject} ) {
        $GetParam{Subject} =
            $ConfigObject->Get( 'QuickClose::DefaultSubject' ) ||
            $LanguageObject->Get( 'Close' );
    }

    # check needed stuff
    if ( !@TicketIDs ) {
        return $LayoutObject->ErrorScreen(
            Message => 'No TicketID is given!',
            Comment => 'Please contact the admin.',
        );
    }

    if ( !$ID ) {
        $ID = $ConfigObject->Get( 'QuickClose::DefaultID' ) || 1;
    }

    # get QuickClose data
    my %CloseData = $QuickCloseObject->QuickCloseGet( ID => $ID );

    if ( !%CloseData ) {
        return $LayoutObject->ErrorScreen(
            Message => 'No QuickClose data found!',
            Comment => 'Please contact the admin.',
        );
    }

    delete $CloseData{Subject} if !length $CloseData{Subject};

    my @NoAccess;

    TICKETID:
    for my $TicketID ( @TicketIDs ) {

        # check permissions
        my $Access = $TicketObject->TicketPermission(
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
        $LayoutObject->ChallengeTokenCheck();

        # add note
        my $ArticleID = '';
        my $MimeType = 'text/plain';
        if ( $Self->{LayoutObject}->{BrowserRichText} ) {
            $MimeType = 'text/html';

            # verify html document
            $CloseData{Body} = $LayoutObject->RichTextDocumentComplete(
                String => $CloseData{Body},
            );
        }

        my $From = "$Self->{UserFirstname} $Self->{UserLastname} <$Self->{UserEmail}>"; 
        $ArticleID = $TicketObject->ArticleCreate(
            TicketID       => $TicketID,
            SenderType     => 'agent',
            From           => $From,
            MimeType       => $MimeType,
            Charset        => $LayoutObject->{UserCharset},
            UserID         => $Self->{UserID},
            HistoryType    => $Self->{Config}->{HistoryType}, 
            HistoryComment => $Self->{Config}->{HistoryComment}, 
            ArticleTypeID  => $CloseData{ArticleTypeID},
            %GetParam,
            %CloseData,
        );
        if ( !$ArticleID ) {
            return $LayoutObject->ErrorScreen();
        }

        if ( $ConfigObject->Get( 'QuickClose::QueueMove' ) && $CloseData{QueueID} ) {
            $TicketObject->TicketQueueSet(
                TicketID => $TicketID,
                QueueID  => $CloseData{QueueID},
                UserID   => $Self->{UserID},
            );
        }

        if ( $ConfigObject->Get('Ticket::Responsible') && $CloseData{AssignToResponsible} ) {
            my %Ticket = $TicketObject->TicketGet(
                TicketID => $TicketID,
                UserID   => $Self->{UserID},
            );

            if ( $Ticket{ResponsibleID} ) {
                $TicketObject->TicketOwnerSet(
                    TicketID  => $TicketID,
                    NewUserID => $Ticket{ResponsibleID},
                    UserID    => $Self->{UserID},
                );
            }
        }
        elsif ( $CloseData{ForceCurrentUserAsOwner} ) {
            $TicketObject->TicketOwnerSet(
                TicketID  => $TicketID,
                NewUserID => $Self->{UserID},
                UserID    => $Self->{UserID},
            );
        }

        if ( $CloseData{OwnerID} ) {
            $TicketObject->TicketOwnerSet(
                TicketID  => $TicketID,
                NewUserID => $CloseData{OwnerID},
                UserID    => $Self->{UserID},
            );
        }

        if ( $CloseData{StateID} ) {

            # set state
            $TicketObject->TicketStateSet(
                TicketID => $TicketID,
                StateID  => $CloseData{StateID},
                UserID   => $Self->{UserID},
            );
    
            my $Type = $QuickCloseObject->TicketStateTypeByStateGet(
                StateID => $CloseData{StateID},
            );
    
            if ( $Type =~ m{^pending}xms ) {
                my $Diff = $CloseData{PendingDiff} ||
                    $ConfigObject->Get( 'QuickClose::PendingDiffDefault' ) ||
                    ( 1 * 24 * 60 );
    
                my ($Sec, $Min, $Hour, $Day, $Month, $Year) = $TimeObject->SystemTime2Date(
                    SystemTime => $Self->{TimeObject}->SystemTime() + ( $Diff * 60 ),
                );
    
                $TicketObject->TicketPendingTimeSet(
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
                $TicketObject->TicketLockSet(
                    TicketID => $TicketID,
                    Lock     => 'unlock',
                    UserID   => $Self->{UserID},
                );
            }
        }
    }

    # redirect parent window to last screen overview on closed tickets
    if ( !@NoAccess ) {
        my $LastView = $Self->{LastScreenOverview} || $Self->{LastScreenView} || 'Action=AgentDashboard';

        if ( scalar( @TicketIDs ) == 1 && $CloseData{ShowTicketZoom} ) {
            $LastView = 'Action=AgentTicketZoom&TicketID=' . $TicketIDs[0];
        }

        return $LayoutObject->Redirect(
            OP => $LastView,
        );

    }
    else {
        return $LayoutObject->ErrorScreen(
            Message => 'No Access to these Tickets (IDs: ' . join( ", ", @NoAccess ) . ')',
            Comment => 'Please contact the admin.',
        );
    }
}

1;
