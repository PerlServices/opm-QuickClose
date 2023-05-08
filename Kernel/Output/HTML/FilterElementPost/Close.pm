# --
# Copyright (C) 2011 - 2023 Perl-Services.de, https://www.perl-services.de/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FilterElementPost::Close;

use strict;
use warnings;

use Kernel::System::Encode;
use Kernel::System::Time;
use Kernel::System::QuickClose;
use Kernel::System::Web::UploadCache;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Ticket
    Kernel::System::Group
    Kernel::Output::HTML::Layout
    Kernel::System::QuickClose
    Kernel::System::Web::Request
    Kernel::System::Web::UploadCache
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $UploadCacheObject = $Kernel::OM->Get('Kernel::System::Web::UploadCache');
    my $QuickCloseObject  = $Kernel::OM->Get('Kernel::System::QuickClose');
    my $ParamObject       = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject      = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $GroupObject       = $Kernel::OM->Get('Kernel::System::Group');
    my $TicketObject      = $Kernel::OM->Get('Kernel::System::Ticket');

    # get template name
    my $Templatename = $Param{TemplateFile} || '';
    return 1 if !$Templatename;

    return if $Templatename  !~ m{AgentTicketZoom\z};

    my @UserRoles = $GroupObject->GroupUserRoleMemberList(
        UserID => $LayoutObject->{UserID},
        Result => 'ID',
    );

    my ($TicketID) = $ParamObject->GetParam( Param => 'TicketID' );

    return 1 if !$TicketID;

    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $TicketID,
        UserID        => $LayoutObject->{UserID},
        DynamicFields => 1,
    );

    return 1 if !%Ticket;

    if ( $ConfigObject->Get('QuickClose::ShowOnlyForOwner') && $LayoutObject->{UserID} != $Ticket{OwnerID} ) {
        return 1;
    }

    if ( $Ticket{Lock} eq 'lock' && $ConfigObject->Get('QuickClose::RequiredLock') && $LayoutObject->{UserID} != $Ticket{OwnerID} ) {
        return 1;
    }

    my $FormID     = $UploadCacheObject->FormIDCreate();
    my %List       = $QuickCloseObject->QuickCloseList(
        Valid      => 1,
        GroupBy    => 1,
        Permission => {
            RoleID => \@UserRoles,
        },
    );

    return 1 if !%List;

    my $Config    = $ConfigObject->Get('QuickClose') || {};
    my $Labels    = $ConfigObject->Get( 'QuickClose::Labels' ) || {};
    my $Dropdowns = '';
    my $UseGroups = $ConfigObject->Get('QuickClose::UseGroups');

    if ( !$UseGroups ) {
        my %Tmp = %List;

        %List = ( '' => \%Tmp );
    }

    GROUP:
    for my $Group ( sort { $a cmp $b }keys %List ) {
        my %Entries = %{ $List{$Group} || {} };

        # check ticket ACLs
        my %FakeActions = map {
            my $Name       = $Entries{$_};
            my $FakeAction = sprintf 'AgentTicketQuickClose_%s', $Name;
            $FakeAction => $FakeAction;
        } keys %Entries;

        my $Success = $TicketObject->TicketAcl(
            %Ticket,
            Data          => \%FakeActions,
            ReturnType    => 'Action',
            ReturnSubType => '-',
            UserID        => $LayoutObject->{UserID},
        );

        my %AllowedActions = $TicketObject->TicketAclData();

        if ( $Success ) {
            for my $ID ( keys %Entries ) {
                my $FakeAction = sprintf 'AgentTicketQuickClose_%s', $Entries{$ID};
                delete $Entries{$ID} if !$AllowedActions{$FakeAction};
            }
        }

        next GROUP if !%Entries;

        my @Indexes = sort{ $Entries{$a} cmp $Entries{$b} }keys %Entries;
        my @Data    = map{ { Key => $_, Value => $Entries{$_} } }@Indexes;

        my $Label   = $Labels->{$Group} || $Config->{NoneLabel} || 'QuickClose';

        unshift @Data, {
            Key   => '0',
            Value => "- $Label -",
        };

        my $Select = $LayoutObject->BuildSelection(
            Data         => \@Data,
            Name         => 'QuickClose',
            ID           => 'QuickClose' . $Group,
            Size         => 1,
            HTMLQuote    => 1,
            Class        => 'QuickCloseSelect Modernize Small',
        );

        $Dropdowns .= $LayoutObject->Output(
            TemplateFile => 'QuickCloseSnippet',
            Data         => {
                TicketID         => $TicketID,
                QuickCloseSelect => $Select,
                FormID           => $FormID,
            },
        );
    }

    #scan html output and generate new html input
    my $LinkType = $ConfigObject->Get('Ticket::Frontend::MoveType');
    if ( $LinkType eq 'form' ) {
        ${ $Param{Data} } =~ s{(<li \s+ class="" .*? <select [^>]*? name="DestQueueID".*?</li>)}{$Dropdowns $1}xms;
    }
    else {
        ${ $Param{Data} } =~ s{(<li> \s+ <a \s+ href="[^"]*?Action=AgentTicketMove;TicketID=\d+;".*?</li>)}{$Dropdowns $1}xms;
    }

    return 1;
}

1;
