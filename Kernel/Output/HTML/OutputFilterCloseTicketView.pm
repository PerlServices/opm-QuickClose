# --
# Kernel/Output/HTML/OutputFilterCloseTicketView.pm
# Copyright (C) 2011 - 2014 Perl-Services.de, http://www.perl-services.de/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::OutputFilterCloseTicketView;

use strict;
use warnings;

use Kernel::System::Encode;
use Kernel::System::Time;
use Kernel::System::QuickClose;
use Kernel::System::Web::UploadCache;

our $VERSION = 0.02;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Encode
    Kernel::System::Log
    Kernel::System::Main
    Kernel::System::Time
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

    # get template name
    my $Templatename = $Param{TemplateFile} || '';
    return 1 if !$Templatename;

    if ( $Templatename  =~ m{AgentTicketOverview(?:Small|Medium|Preview)\z} ) {
        my $FormID = $UploadCacheObject->FormIDCreate();
        my %List   = $QuickCloseObject->QuickCloseList( Valid => 1 );
        
        my @Indexes = sort{ $List{$a} cmp $List{$b} }keys %List;
        my @Data    = map{ { Key => $_, Value => $List{$_} } }@Indexes;

        my $Config = $ConfigObject->Get('QuickClose') || {};
        
        unshift @Data, {
            Key   => '', 
            Value => ' - ' . ($Config->{NoneLabel} || 'QuickClose')  . ' - ',
        };
        
        my $Select = $LayoutObject->BuildSelection(
            Data      => \@Data,
            Name      => 'QuickClose',
            Size      => 1,
            HTMLQuote => 1,
        );

        my $Snippet = $LayoutObject->Output(
            TemplateFile => 'QuickCloseSnippetTicketView',
            Data         => {
                QuickCloseSelect => $Select,
                FormID           => $FormID,
            },
        ); 

        #scan html output and generate new html input
        ${ $Param{Data} } =~ s{(<ul \s+ class="Actions"> \s* <li .*? /li>)}{$1 $Snippet}xmgs;
    }

    return ${ $Param{Data} };
}

1;
