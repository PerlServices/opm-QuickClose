# --
# Kernel/Output/HTML/OutputFilterClose.pm
# Copyright (C) 2011 Perl-Services.de, http://www.perl-services.de/
# --
# $Id: OutputFilterClose.pm,v 1.1 2011/04/19 10:21:42 rb Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::OutputFilterClose;

use strict;
use warnings;

use Kernel::System::Encode;
use Kernel::System::Time;
use Kernel::System::QuickClose;
use Kernel::System::Web::UploadCache;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.1 $) [1];

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    for my $Object (
        qw(MainObject ConfigObject LogObject LayoutObject ParamObject)
        )
    {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    if ( $Param{EncodeObject} ) {
        $Self->{EncodeObject} = $Param{EncodeObject};
    }
    else {
        $Self->{EncodeObject} = Kernel::System::Encode->new( %{$Self} );
    }

    if ( $Param{TimeObject} ) {
        $Self->{TimeObject} = $Param{TimeObject};
    }
    else {
        $Self->{TimeObject} = Kernel::System::Time->new( %{$Self} );
    }

    if ( $Self->{LayoutObject}->{DBObject} ) {
        $Self->{QuickCloseObject} = Kernel::System::QuickClose->new(
            %{$Self},
            DBObject => $Self->{LayoutObject}->{DBObject},
        );

        $Self->{UploadCacheObject} = Kernel::System::Web::UploadCache->new(
            %{$Self},
            DBObject => $Self->{LayoutObject}->{DBObject},
        );
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get template name
    my $Templatename = $Param{TemplateFile} || '';
    return 1 if !$Templatename;

    if ( $Templatename  =~ m{AgentTicketZoom\z} ) {
        my ($TicketID) = ${$Param{Data}} =~ m{TicketID=(\d+)};
        my $FormID     = $Self->{UploadCacheObject}->FormIDCreate();

        my %List   = $Self->{QuickCloseObject}->QuickCloseList( Valid => 1 );
        
        my @Indexes = sort{ $List{$a} cmp $List{$b} }keys %List;
        my @Data    = map{ { Key => $_, Value => $List{$_} } }@Indexes;
        
        unshift @Data, {
            Key => '', 
            Value => ' - ' . ($Self->{ConfigObject}->Get( 'QuickClose###NoneLabel' ) || 'QuickClose')  . ' - ',
        };
        
        my $Select = $Self->{LayoutObject}->BuildSelection(
            Data         => \@Data,
            Name         => 'QuickClose',
            Size         => 1,
            HTMLQuote    => 1,
        );

        my $Snippet = $Self->{LayoutObject}->Output(
            TemplateFile => 'QuickCloseSnippet',
            Data         => {
                TicketID         => $TicketID,
                QuickCloseSelect => $Select,
                FormID           => $FormID,
            },
        ); 

        #scan html output and generate new html input
        my $LinkType = $Self->{ConfigObject}->Get('Ticket::Frontend::MoveType');
        if ( $LinkType eq 'form' ) {
            ${ $Param{Data} } =~ s{(<select name="DestQueueID".*?</li>)}{$1 $Snippet}mgs;
        }
        else {
            ${ $Param{Data} } =~ s{(<a href=".*?Action=AgentTicketMove;TicketID=\d+;".*?</li>)}{$1 $Snippet}mgs;
        }
    }

    return ${ $Param{Data} };
}

1;
