# --
# Kernel/Modules/AgentQuickClose.pm - provides admin notification translations
# Copyright (C) 2011 - 2014 Perl-Services.de, http://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentQuickClose;

use strict;
use warnings;

our $VERSION = 0.02;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Log
    Kernel::System::Encode
    Kernel::System::Main
    Kernel::System::DB
    Kernel::System::QuickClose
    Kernel::System::Web::Request
    Kernel::Output::HTML::Layout
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject      = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $QuickCloseObject = $Kernel::OM->Get('Kernel::System::QuickClose');
    my $LayoutObject     = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my @Params = (qw(ID));
    my %GetParam;
    for (@Params) {
        $GetParam{$_} = $ParamObject->GetParam( Param => $_ ) || '';
    }

    my %Data = $QuickCloseObject->QuickCloseGet(
        ID => $GetParam{ID},
    );

    my $JSON = my $TemplateDump
        = $LayoutObject->JSONEncode( Data => \%Data );

    return $LayoutObject->Attachment(
        ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
        Content     => $JSON || '',
        Type        => 'inline',
        NoCache     => 0,
    );
}

1;
