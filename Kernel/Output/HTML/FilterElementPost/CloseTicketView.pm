# --
# Kernel/Output/HTML/FilterElementPost/CloseTicketView.pm
# Copyright (C) 2011 - 2015 Perl-Services.de, http://www.perl-services.de/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FilterElementPost::CloseTicketView;

use strict;
use warnings;

use Kernel::System::Encode;
use Kernel::System::Time;
use Kernel::System::QuickClose;
use Kernel::System::Web::UploadCache;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Encode
    Kernel::System::Log
    Kernel::System::Main
    Kernel::System::Time
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
    my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject      = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $GroupObject       = $Kernel::OM->Get('Kernel::System::Group');

    # get template name
    my $Templatename = $Param{TemplateFile} || '';
    return 1 if !$Templatename;

    if ( $Templatename  =~ m{AgentTicketOverview(?:Small|Medium|Preview)\z} ) {
        my @UserRoles = $GroupObject->GroupUserRoleMemberList(
            UserID => $LayoutObject->{UserID},
            Result => 'ID',
        );

        my $FormID = $UploadCacheObject->FormIDCreate();
        my %List   = $QuickCloseObject->QuickCloseList(
            Valid   => 1,
            GroupBy => 1,
            Permission => {
                RoleID => \@UserRoles,
            },
        );

        my $Config    = $ConfigObject->Get('QuickClose') || {};
        my $Labels    = $ConfigObject->Get( 'QuickClose::Labels' ) || {};
        my $Dropdowns = '';
        my $UseGroups = $ConfigObject->Get('QuickClose::UseGroups');

        if ( !$UseGroups ) {
            my %Tmp = %List;

            %List = ( '' => \%Tmp );
        }

        for my $Group ( sort { $a cmp $b } keys %List ) {
            my %Entries = %{ $List{$Group} };
            my @Indexes = sort{ $Entries{$a} cmp $Entries{$b} }keys %Entries;
            my @Data    = map{ { Key => $_, Value => $Entries{$_} } }@Indexes;

            my $Label   = $Labels->{$Group} || $Config->{NoneLabel} || 'QuickClose';

            unshift @Data, {
                Key   => '',
                Value => "- $Label -",
            };

            my $Select = $LayoutObject->BuildSelection(
                Data         => \@Data,
                Name         => 'QuickClose',
                ID           => 'QuickClose' . $Group,
                Size         => 1,
                HTMLQuote    => 1,
                Class        => 'QuickCloseSelect',
            );

            $Dropdowns .= $LayoutObject->Output(
                TemplateFile => 'QuickCloseSnippetTicketView',
                Data         => {
                    QuickCloseSelect => $Select,
                    FormID           => $FormID,
                },
            ); 
        }

        #scan html output and generate new html input
        ${ $Param{Data} } =~ s{(<ul \s+ class="Actions"> \s* <li .*? /li>)}{$1 $Dropdowns}xmgs;
    }

    return ${ $Param{Data} };
}

1;
