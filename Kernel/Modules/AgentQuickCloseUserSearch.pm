# --
# Kernel/Modules/AgentQuickCloseUserSearch.pm - a module used for the autocomplete feature
# Copyright (C) 2011 - 2022 Perl-Services.de, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentQuickCloseUserSearch;

use strict;
use warnings;

our $VERSION = 0.02;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Log
    Kernel::System::Encode
    Kernel::System::Main
    Kernel::System::DB
    Kernel::System::Group
    Kernel::System::User
    Kernel::System::Web::Request
    Kernel::Language
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get config for frontend
    $Self->{Config} = $ConfigObject->Get("QuickCloseChange::Frontend::$Self->{Action}");

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $UserObject   = $Kernel::OM->Get('Kernel::System::User');
    my $GroupObject  = $Kernel::OM->Get('Kernel::System::Group');
    my $EncodeObject = $Kernel::OM->Get('Kernel::System::Encode');

    my $JSON = '';

    # search users
    if ( !$Self->{Subaction} ) {

        # get needed params
        my $Search = $ParamObject->GetParam( Param => 'Term' )   || '';
        my $Groups = $ParamObject->GetParam( Param => 'Groups' ) || '';
        my $MaxResults = int( $ParamObject->GetParam( Param => 'MaxResults' ) || 20 );

        # get all members of the groups
        my %GroupUsers;
        if ($Groups) {
            my @GroupNames = split /,\s+/, $Groups;

            GROUPNAME:
            for my $GroupName (@GroupNames) {

                # allow trailing comma
                next GROUPNAME if !$GroupName;

                my $GroupID = $GroupObject->GroupLookup(
                    Group => $GroupName,
                );

                next GROUPNAME if !$GroupID;

                # get users in group
                my %Users = $GroupObject->GroupMemberList(
                    GroupID => $GroupID,
                    Type    => 'ro',
                    Result  => 'HASH',
                    Cached  => 1,
                );

                my @UserIDs = keys %Users;
                @GroupUsers{@UserIDs} = @UserIDs;
            }
        }

        # get user list
        my %UserList = $UserObject->UserSearch(
            Search => $Search,
            Valid  => 1,
        );

        my $MaxResultCount = $MaxResults;

        # the data that will be sent as response
        my @Data;

        USERID:
        for my $UserID ( sort { $UserList{$a} cmp $UserList{$b} } keys %UserList ) {

            # if groups are required and user is not member of one of the groups
            # then skip the user
            if ( $Groups && !$GroupUsers{$UserID} ) {
                next USERID;
            }

            # The values in %UserList are in the form: 'mm Max Mustermann'.
            # So assemble a neater string for display.
            # (Actually UserSearch() contains code for formating, but that is usually not called.)
            my %User = $UserObject->GetUserData(
                UserID => $UserID,
                Valid  => $Param{Valid},
            );

            my $UserValue = sprintf '"%s %s" <%s>',
                $User{UserFirstname},
                $User{UserLastname},
                $User{UserEmail};

            push @Data, {
                UserKey   => $UserID,
                UserValue => $UserValue,
            };

            $MaxResultCount--;
            last USERID if $MaxResultCount <= 0;
        }

        # build JSON output
        $JSON = $LayoutObject->JSONEncode(
            Data => \@Data,
        );
    }

    # send JSON response
    return $LayoutObject->Attachment(
        ContentType => 'text/plain; charset=' . $LayoutObject->{Charset},
        Content     => $JSON || '',
        Type        => 'inline',
        NoCache     => 1,
    );

}

1;
