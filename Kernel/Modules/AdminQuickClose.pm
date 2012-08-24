# --
# Kernel/Modules/AdminQuickClose.pm - provides admin notification translations
# Copyright (C) 2011 Perl-Services.de, http://www.perl-services.de
# --
# $Id: AdminQuickClose.pm,v 1.1.1.1 2011/04/15 07:49:58 rb Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminQuickClose;

use strict;
use warnings;

use Kernel::System::QuickClose;
use Kernel::System::HTMLUtils;
use Kernel::System::Valid;
use Kernel::System::State;
use Kernel::System::Queue;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.1.1.1 $) [1];

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check all needed objects
    my @Objects = qw(
        ParamObject DBObject LayoutObject ConfigObject LogObject TicketObject 
    );
    for my $Needed (@Objects) {
        if ( !$Self->{$Needed} ) {
            $Self->{LayoutObject}->FatalError( Message => "Got no $Needed!" );
        }
    }

    # create needed objects
    $Self->{QuickCloseObject} = Kernel::System::QuickClose->new(%Param);
    $Self->{ValidObject}      = Kernel::System::Valid->new(%Param);
    $Self->{HTMLUtilsObject}  = Kernel::System::HTMLUtils->new(%Param);
    $Self->{StateObject}      = Kernel::System::State->new(%Param);
    $Self->{QueueObject}      = Kernel::System::Queue->new(%Param);

    # get config of frontend module
    $Self->{Config} = $Self->{ConfigObject}->Get("Ticket::Frontend::AgentTicketClose");

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my @Params = (qw(ID Name StateID Body ValidID UserID ArticleTypeID QueueID));
    my %GetParam;
    for (@Params) {
        $GetParam{$_} = $Self->{ParamObject}->GetParam( Param => $_ ) || '';
    }

    # ------------------------------------------------------------ #
    # get data 2 form
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Edit' || $Self->{Subaction} eq 'Add' ) {
        my %Subaction = (
            Edit => 'Update',
            Add  => 'Save',
        );

        my $Output       = $Self->{LayoutObject}->Header();
        $Output .= $Self->{LayoutObject}->NavigationBar();
        $Output .= $Self->_MaskQuickCloseForm(
            %GetParam,
            %Param,
            Subaction => $Subaction{ $Self->{Subaction} },
        );
        $Output .= $Self->{LayoutObject}->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # update action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Update' ) {

        # challenge token check for write action
        $Self->{LayoutObject}->ChallengeTokenCheck();
 
        # server side validation
        my %Errors;
        if (
            !$GetParam{ValidID} ||
            !$Self->{ValidObject}->ValidLookup( ValidID => $GetParam{ValidID} )
            )
        {
            $Errors{ValidIDInvalid} = 'ServerError';
        }

        for my $Param (qw(Name StateID Body)) {
            if ( !$GetParam{$Param} ) {
                $Errors{ $Param . 'Invalid' } = 'ServerError';
            }
        }

        if ( %Errors ) {
            $Self->{Subaction} = 'Edit';

            my $Output = $Self->{LayoutObject}->Header();
            $Output .= $Self->{LayoutObject}->NavigationBar();
            $Output .= $Self->_MaskQuickCloseForm(
                %GetParam,
                %Param,
                %Errors,
                Subaction => 'Update',
            );
            $Output .= $Self->{LayoutObject}->Footer();
            return $Output;
        }

        my $Update = $Self->{QuickCloseObject}->QuickCloseUpdate(
            %GetParam,
            UserID => $Self->{UserID},
        );

        if ( !$Update ) {
            return $Self->{LayoutObject}->ErrorScreen();
        }
        return $Self->{LayoutObject}->Redirect( OP => "Action=AdminQuickClose" );
    }

    # ------------------------------------------------------------ #
    # insert invoice state
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Save' ) {

        # challenge token check for write action
        $Self->{LayoutObject}->ChallengeTokenCheck();

        # server side validation
        my %Errors;
        if (
            !$GetParam{ValidID} ||
            !$Self->{ValidObject}->ValidLookup( ValidID => $GetParam{ValidID} )
            )
        {
            $Errors{ValidIDInvalid} = 'ServerError';
        }

        for my $Param (qw(Name StateID Body)) {
            if ( !$GetParam{$Param} ) {
                $Errors{ $Param . 'Invalid' } = 'ServerError';
            }
        }

        if ( %Errors ) {
            $Self->{Subaction} = 'Add';

            my $Output = $Self->{LayoutObject}->Header();
            $Output .= $Self->{LayoutObject}->NavigationBar();
            $Output .= $Self->_MaskQuickCloseForm(
                %GetParam,
                %Param,
                %Errors,
                Subaction => 'Save',
            );
            $Output .= $Self->{LayoutObject}->Footer();
            return $Output;
        }

        my $Success = $Self->{QuickCloseObject}->QuickCloseAdd(
            %GetParam,
            UserID => $Self->{UserID},
        );

        if ( !$Success ) {
            return $Self->{LayoutObject}->ErrorScreen();
        }
        return $Self->{LayoutObject}->Redirect( OP => "Action=AdminQuickClose" );
    }

    elsif ( $Self->{Subaction} eq 'Delete' ) {
        $Self->{QuickCloseObject}->QuickCloseDelete( %GetParam );
        return $Self->{LayoutObject}->Redirect( OP => "Action=AdminQuickClose" );
    }

    # ------------------------------------------------------------ #
    # else ! print form
    # ------------------------------------------------------------ #
    else {
        my $Output = $Self->{LayoutObject}->Header();
        $Output .= $Self->{LayoutObject}->NavigationBar();
        $Output .= $Self->_MaskQuickCloseForm();
        $Output .= $Self->{LayoutObject}->Footer();
        return $Output;
    }
}

sub _MaskQuickCloseForm {
    my ( $Self, %Param ) = @_;

    if ( $Self->{Subaction} eq 'Edit' ) {
        my %QuickClose = $Self->{QuickCloseObject}->QuickCloseGet( ID => $Param{ID} );
        for my $Key ( keys %QuickClose ) {
            $Param{$Key} = $QuickClose{$Key} if !$Param{$Key};
        }
    }

    # add rich text editor
    if ( $Self->{ConfigObject}->Get( 'Frontend::RichText' ) ) {
        $Self->{LayoutObject}->Block(
            Name => 'RichText',
            Data => \%Param,
        );
    }

    my $ValidID = $Self->{ValidObject}->ValidLookup( Valid => 'valid' );

    $Param{ValidSelect} = $Self->{LayoutObject}->BuildSelection(
        Data       => { $Self->{ValidObject}->ValidList() },
        Name       => 'ValidID',
        Size       => 1,
        SelectedID => $Param{ValidID} || $ValidID,
        HTMLQuote  => 1,
    );

    my $StateTypes = $Self->{ConfigObject}->Get( 'QuickClose::StateTypes' ) || [ 'closed' ];

    my %States = $Self->{StateObject}->StateGetStatesByType(
        StateType => $StateTypes,
        Result    => 'HASH',
    );

    $Param{StateSelect} = $Self->{LayoutObject}->BuildSelection(
        Data       => \%States,
        Name       => 'StateID',
        Size       => 1,
        SelectedID => $Param{StateID},
        HTMLQuote  => 1,
    );

    my %Queues;

    if ( $Self->{ConfigObject}->Get( 'QuickClose::QueueMove' ) ) {
        %Queues = $Self->{QueueObject}->QueueList();
    }

    $Param{QueueSelect} = $Self->{LayoutObject}->BuildSelection(
        Data         => \%Queues,
        Name         => 'QueueID',
        Size         => 1,
        SelectedID   => $Param{QueueID},
        HTMLQuote    => 1,
        PossibleNone => 1,
        TreeView     => 1,
    );

    # build ArticleTypeID string
    my %ArticleType;
    if ( !$Param{ArticleTypeID} ) {
        $ArticleType{SelectedValue} = $Self->{Config}->{ArticleTypeDefault};
    }
    else {
        $ArticleType{SelectedID} = $Param{ArticleTypeID};
    }

    # get possible notes
    my %DefaultNoteTypes = %{ $Self->{Config}->{ArticleTypes} };
    my %NoteTypes = $Self->{TicketObject}->ArticleTypeList( Result => 'HASH' );
    for my $KeyNoteType ( keys %NoteTypes ) {
        if ( !$DefaultNoteTypes{ $NoteTypes{$KeyNoteType} } ) {
            delete $NoteTypes{$KeyNoteType};
        }
    }
    $Param{ArticleTypeSelect} = $Self->{LayoutObject}->BuildSelection(
        Data => \%NoteTypes,
        Name => 'ArticleTypeID',
        %ArticleType,
    );

    if ( $Self->{Subaction} ne 'Edit' && $Self->{Subaction} ne 'Add' ) {

        my %QuickCloseList = $Self->{QuickCloseObject}->QuickCloseList();
  
        if ( !%QuickCloseList ) {
            $Self->{LayoutObject}->Block(
                Name => 'NoQuickCloseFound',
            );
        }

        for my $QuickCloseID ( sort keys %QuickCloseList ) {
            my %QuickClose = $Self->{QuickCloseObject}->QuickCloseGet(
                ID => $QuickCloseID,
            );

            $Self->{LayoutObject}->Block(
                Name => 'QuickCloseRow',
                Data => \%QuickClose,
            );
        }
    }

    $Param{SubactionName} = 'Update';
    $Param{SubactionName} = 'Save' if $Self->{Subaction} && $Self->{Subaction} eq 'Add';

    my $TemplateFile = 'AdminQuickCloseList';
    $TemplateFile = 'AdminQuickCloseForm' if $Self->{Subaction};

    return $Self->{LayoutObject}->Output(
        TemplateFile => $TemplateFile,
        Data         => \%Param
    );
}

1;
