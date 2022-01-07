# --
# Copyright (C) 2012 - 2021 Perl-Services.de, https://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentTicketCloseBulk;

use strict;
use warnings;

use Kernel::Language qw(Translatable);

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
    Kernel::System::User
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

    my $ParamObject        = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $UploadCacheObject  = $Kernel::OM->Get('Kernel::System::Web::UploadCache');
    my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject       = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $QuickCloseObject   = $Kernel::OM->Get('Kernel::System::QuickClose');
    my $TicketObject       = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ArticleObject      = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $TimeObject         = $Kernel::OM->Get('Kernel::System::Time');
    my $UserObject         = $Kernel::OM->Get('Kernel::System::User');
    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $TemplateGenerator  = $Kernel::OM->Get('Kernel::System::TemplateGenerator');

    my @TicketIDs = $ParamObject->GetArray( Param => 'TicketID' );
    my $ID        = $ParamObject->GetParam( Param => 'QuickClose' );

    my %GetParam;
    for my $WebParam ( qw(Subject OrigTicketID GoToZoom) ) {
        $GetParam{$WebParam} = $ParamObject->GetParam( Param => $WebParam ) || '';
    }

    if ( !$GetParam{Subject} ) {
        $GetParam{Subject} =
            $ConfigObject->Get( 'QuickClose::DefaultSubject' ) ||
            $LayoutObject->{LanguageObject}->Translate('Close');
    }

    # check needed stuff
    if ( !@TicketIDs ) {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('No TicketID is given!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    if ( !$ID ) {
        $ID = $ConfigObject->Get( 'QuickClose::DefaultID' ) || 1;
    }

    # get QuickClose data
    my %CloseData = $QuickCloseObject->QuickCloseGet( ID => $ID );

    if ( !%CloseData ) {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('No QuickClose data found!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    delete $CloseData{Subject} if !length $CloseData{Subject};

    my @NoAccess;
    my @CloseNotAllowed;

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

        my %Ticket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            UserID        => $Self->{UserID},
            DynamicFields => 1,
        );

        # check if the Quickclose action is forbidden via Ticket ACLs
        my $FakeAction = sprintf 'AgentTicketQuickClose_%s', $CloseData{Name};

        my $ACLInAction = $TicketObject->TicketAcl(
            %Ticket,
            Data => { 
                $FakeAction => $FakeAction,
            },
            ReturnType => 'Action',
            ReturnSubType => '-',
            UserID        => $Self->{UserID},
        );

        my %ACLData = $TicketObject->TicketAclData();
        if ( $ACLInAction && !exists $ACLData{$FakeAction} ) {
            push @CloseNotAllowed, $TicketID;
            next TICKETID;
        }

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $ResponsibleEnabled = $ConfigObject->Get('Ticket::Responsible');

        if ( $ResponsibleEnabled && $CloseData{AssignToResponsible} ) {
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

        if ( $CloseData{ForceCurrentUserAsResponsible} && $ResponsibleEnabled) {
            $TicketObject->TicketResponsibleSet(
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

        if ( $ResponsibleEnabled && $CloseData{ResponsibleID} ) {
            $TicketObject->TicketResponsibleSet(
                TicketID  => $TicketID,
                NewUserID => $CloseData{ResponsibleID},
                UserID    => $Self->{UserID},
            );
        }

        my $To = '';

        if ( $Ticket{OwnerID} != $Self->{UserID} ) {
            my %User = $UserObject->GetUserData(
                UserID => $Ticket{OwnerID},
            );

            $To = qq~"$User{UserFullname}" <$User{UserEmail}>~;
        }

        my $Signature = $TemplateGenerator->Signature(
            QueueID => $Ticket{QueueID},
            UserID  => $Self->{UserID},
            Data    => {},
        );

        my $ToType = $CloseData{ToType} || '';
        my $Method = 'ArticleCreate';
        my $BR     = $LayoutObject->{BrowserRichText} ? '<br>' : "\n";

        my $Body = $CloseData{Body};

        if ( $ToType eq 'Customer' && $Ticket{CustomerUserID} ) {
            my %CustomerData = $CustomerUserObject->CustomerUserDataGet(
                User => $Ticket{CustomerUserID},
            );

            $Method = 'ArticleSend';
            $To     = $Ticket{CustomerUserID};

            if ( %CustomerData ) {
                $To = qq~"$CustomerData{UserFullname}" <$CustomerData{UserEmail}>~;
            }

            $Body .= "$BR$BR-- $BR" . $Signature if $Signature;
        }
        elsif ( $ToType eq 'Other' && $CloseData{ToAddress} ) {
            $Method = 'ArticleSend';
            $To     = $CloseData{ToAddress};

            $Body .= "$BR$BR-- $BR" . $Signature if $Signature;
        }

        $Body = $Self->_ReplaceMacros(
            Text      => $Body,
            RichText  => $LayoutObject->{BrowserRichText},
            Ticket    => {%Ticket},
            Language  => $LayoutObject->{UserLanguage},    # used for translating states and such
            UserID    => $Self->{UserID},
        );

        if ( $Body ) {
            # add note
            my $ArticleID = '';
            my $MimeType = 'text/plain';
            if ( $LayoutObject->{BrowserRichText} ) {
                $MimeType = 'text/html';

                # verify html document
                $Body = $LayoutObject->RichTextDocumentComplete(
                    String => $Body,
                );
            }

            my $Subject = $TicketObject->TicketSubjectBuild(
                TicketNumber => $Ticket{TicketNumber},
                Subject      => $CloseData{Subject} || $Ticket{Title},
                Action       => 'Reply',
            );

            $Subject = $Self->_ReplaceMacros(
                Text      => $Subject,
                RichText  => 0,
                Ticket    => {%Ticket},
                Language  => $LayoutObject->{UserLanguage},    # used for translating states and such
                UserID    => 1,
            );

            $CloseData{IsVisibleForCustomer} = $CloseData{ArticleCustomer};

            my $From = "$Self->{UserFirstname} $Self->{UserLastname} <$Self->{UserEmail}>";

            if ( $ConfigObject->Get('QuickClose::UseQueueSender') ) {
                $From = $TemplateGenerator->Sender(
                    QueueID => $Ticket{QueueID},
                    UserID  => $Self->{UserID},
                );
            }

            my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => $CloseData{ArticleType} );

            $ArticleID = $ArticleBackendObject->$Method(
                TicketID       => $TicketID,
                SenderType     => 'agent',
                From           => $From,
                To             => $To,
                MimeType       => $MimeType,
                Charset        => $LayoutObject->{UserCharset},
                UserID         => $Self->{UserID},
                HistoryType    => $Self->{Config}->{HistoryType}, 
                HistoryComment => $Self->{Config}->{HistoryComment}, 
                ArticleTypeID  => $CloseData{ArticleTypeID},
                %GetParam,
                %CloseData,
                Body           => $Body,
                Subject        => $Subject,
            );

            if ( !$ArticleID ) {
                return $LayoutObject->ErrorScreen();
            }

            if ( $ArticleID && $CloseData{TimeUnits} ) {
                $TicketObject->TicketAccountTime(
                    TicketID  => $TicketID,
                    ArticleID => $ArticleID,
                    TimeUnit  => $CloseData{TimeUnits},
                    UserID    => $Self->{UserID},
                );
            }
        }

        if ( $CloseData{PriorityID} ) {
            $TicketObject->TicketPrioritySet(
                TicketID   => $TicketID,
                PriorityID => $CloseData{PriorityID},
                UserID     => $Self->{UserID},
            );
        }

        if ( $ConfigObject->Get( 'QuickClose::QueueMove' ) && $CloseData{QueueID} ) {
            $TicketObject->TicketQueueSet(
                TicketID => $TicketID,
                QueueID  => $CloseData{QueueID},
                UserID   => $Self->{UserID},
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
                    SystemTime => $TimeObject->SystemTime() + ( $Diff * 60 ),
                );

                if ( $CloseData{FixHour} ) {
                    my ($TmpHour, $TmpMin) = split /:/, $CloseData{FixHour};
                    $Hour = $TmpHour // 0;
                    $Min  = $TmpMin  // 0;
                }
    
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
    if ( !@NoAccess && !@CloseNotAllowed ) {
        my $LastView = $Self->{LastScreenOverview} || $Self->{LastScreenView} || 'Action=AgentDashboard';

        if ( scalar( @TicketIDs ) == 1 && $CloseData{ShowTicketZoom} ) {
            $LastView = 'Action=AgentTicketZoom&TicketID=' . $TicketIDs[0];
        }
        elsif ( $GetParam{GoToZoom} && $GetParam{OrigTicketID} ) {
            $LastView = 'Action=AgentTicketZoom&TicketID=' . $GetParam{OrigTicketID};
        }

        return $LayoutObject->Redirect(
            OP => $LastView,
        );

    }
    else {
        my @NotAllowed    = ('No Access to these Tickets (IDs: %s)', join( ", ", @NoAccess ));
        my @NotApplicable = ('QuickClose not applicable for these Tickets (IDs: %s)', join( ", ", @CloseNotAllowed ));

        my @Messages;
        push @Messages, $LayoutObject->{LanguageObject}->Translate( @NotAllowed )    if @NoAccess;
        push @Messages, $LayoutObject->{LanguageObject}->Translate( @NotApplicable ) if @CloseNotAllowed;

        return $LayoutObject->ErrorScreen(
            Message => (join ', ', @Messages),
            Comment => Translatable('Please contact the administrator.'),
        );
    }
}

sub _ReplaceMacros {
    my ( $Self, %Param ) = @_;

    my $LogObject       = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
    my $UserObject      = $Kernel::OM->Get('Kernel::System::User');
    my $HTMLUtilsObject = $Kernel::OM->Get('Kernel::System::HTMLUtils');

    # check needed stuff
    for my $Needed (qw(Text UserID Ticket Language)) {
        if ( !defined $Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my $Text = $Param{Text};

    # determine what "macro" delimiters are used
    my $Start = '<';
    my $End   = '>';
    my $NL    = "\n";

    # with richtext enabled, the delimiters change
    if ( $Param{RichText} ) {
        $Start = '&lt;';
        $End   = '&gt;';
        $NL    = '<br />';
        $Text =~ s{ (\n|\r) }{}xmsg;

        $Param{Articles} = [ map{ $_ =~ s!\n!<br />!g; $_ }@{ $Param{Articles} || [] } ];
    }

    # translate Ticket values, where appropriate
    my $LanguageObject = Kernel::Language->new(
        UserLanguage => $Param{Language},
    );

    my %TicketData = %{ $Param{Ticket} };
    for my $Field (qw(State Priority)) {
        $TicketData{$Field} = $LanguageObject->Translate( $TicketData{$Field} );
    }

    # replace config options
    my $Tag = $Start . 'OTRS_CONFIG_';
    $Text =~ s{ $Tag (.+?) $End }{$ConfigObject->Get($1)}egx;

    # cleanup
    $Text =~ s{ $Tag .+? $End }{-}gi;

    $Tag = $Start . 'OTRS_Agent_';
    my $Tag2 = $Start . 'OTRS_CURRENT_';
    my %CurrentUser = $UserObject->GetUserData( UserID => $Param{UserID} );

    # html quoting of content
    if ( $Param{RichText} ) {
        KEY:
        for my $Key ( sort keys %CurrentUser ) {
            next KEY if !$CurrentUser{$Key};
            $CurrentUser{$Key} = $HTMLUtilsObject->ToHTML(
                String => $CurrentUser{$Key},
            );
        }
    }

    # replace it
    KEY:
    for my $Key ( sort keys %CurrentUser ) {
        next KEY if !defined $CurrentUser{$Key};
        $Text =~ s{ $Tag $Key $End }{$CurrentUser{$Key}}gxmsi;
        $Text =~ s{ $Tag2 $Key $End }{$CurrentUser{$Key}}gxmsi;
    }

    # replace other needed stuff
    $Text =~ s{ $Start OTRS_FIRST_NAME $End }{$CurrentUser{UserFirstname}}gxms;
    $Text =~ s{ $Start OTRS_LAST_NAME $End }{$CurrentUser{UserLastname}}gxms;

    # cleanup
    $Text =~ s{ $Tag .+? $End}{-}xmsgi;
    $Text =~ s{ $Tag2 .+? $End}{-}xmsgi;

    # replace <OTRS_TICKET_... tags
    {
        my $Tag = $Start . 'OTRS_TICKET_';

        # html quoting of content
        if ( $Param{RichText} ) {
            KEY:
            for my $Key ( sort keys %TicketData ) {
                next KEY if !$TicketData{$Key};
                $TicketData{$Key} = $HTMLUtilsObject->ToHTML(
                    String => $TicketData{$Key},
                );
            }
        }

        # replace it
        KEY:
        for my $Key ( sort keys %TicketData ) {
            next KEY if !defined $TicketData{$Key};
            $Text =~ s{ $Tag $Key $End }{$TicketData{$Key}}gxmsi;
        }

        # cleanup
        $Text =~ s{ $Tag .+? $End}{-}gxmsi;
    }

    return $Text;
}


1;
