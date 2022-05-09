# --
# Copyright (C) 2011 - 2022 Perl-Services.de, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminQuickClose;

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
    Kernel::System::Group
    Kernel::System::Valid
    Kernel::System::Priority
    Kernel::System::QuickClose
    Kernel::System::Web::Request
    Kernel::Output::HTML::Layout
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get config of frontend module
    $Self->{Config} = $ConfigObject->Get("Ticket::Frontend::AgentTicketClose");

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject      = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject     = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $QuickCloseObject = $Kernel::OM->Get('Kernel::System::QuickClose');
    my $ValidObject      = $Kernel::OM->Get('Kernel::System::Valid');

    my @Params = qw(
        ID Name StateID Body ValidID UserID ArticleType ArticleCustomer
        QueueID Subject Unlock OwnerSelected PendingDiff ForceCurrentUserAsOwner
        AssignToResponsible ShowTicketZoom FixHour Group PriorityID
        ResponsibleSelected TimeUnits ToType ToAddress
    );

    my %GetParam;
    for my $ParamName (@Params) {
        $GetParam{$ParamName} = $ParamObject->GetParam( Param => $ParamName ) || '';
    }

    my @ArrayParams = qw(RoleID);
    for my $ArrayName (@ArrayParams) {
        $GetParam{$ArrayName} = [ $ParamObject->GetArray( Param => $ArrayName ) ];
    }

    # ------------------------------------------------------------ #
    # get data 2 form
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Edit' || $Self->{Subaction} eq 'Add' ) {
        my %Subaction = (
            Edit => 'Update',
            Add  => 'Save',
        );

        my $Output       = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $Self->_MaskQuickCloseForm(
            %GetParam,
            %Param,
            Subaction => $Subaction{ $Self->{Subaction} },
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # update action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Update' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();
 
        # server side validation
        my %Errors;
        if (
            !$GetParam{ValidID} ||
            !$ValidObject->ValidLookup( ValidID => $GetParam{ValidID} )
            )
        {
            $Errors{ValidIDInvalid} = 'ServerError';
        }

        my $CreateArticle = $ParamObject->GetParam( Param => 'CreateArticle' );

        my @RequiredParams;
        if ( $CreateArticle ) {
            @RequiredParams = qw/Body Subject/;
        }

        for my $Param (qw(Name), @RequiredParams ) {
            if ( !$GetParam{$Param} ) {
                $Errors{ $Param . 'Invalid' } = 'ServerError';
            }
        }

        if ( %Errors ) {
            $Self->{Subaction} = 'Edit';

            my $Output = $LayoutObject->Header();
            $Output .= $LayoutObject->NavigationBar();
            $Output .= $Self->_MaskQuickCloseForm(
                %GetParam,
                %Param,
                %Errors,
                Subaction => 'Update',
                Submitted => 1,
            );
            $Output .= $LayoutObject->Footer();
            return $Output;
        }

        my $Update = $QuickCloseObject->QuickCloseUpdate(
            %GetParam,
            Permission    => {
                RoleID => $GetParam{RoleID},
            },
            UserID        => $Self->{UserID},
            OwnerID       => $GetParam{OwnerSelected},
            ResponsibleID => $GetParam{ResponsibleSelected},
        );

        if ( !$Update ) {
            return $LayoutObject->ErrorScreen();
        }
        return $LayoutObject->Redirect( OP => "Action=AdminQuickClose" );
    }

    # ------------------------------------------------------------ #
    # insert invoice state
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Save' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # server side validation
        my %Errors;
        if (
            !$GetParam{ValidID} ||
            !$ValidObject->ValidLookup( ValidID => $GetParam{ValidID} )
            )
        {
            $Errors{ValidIDInvalid} = 'ServerError';
        }

        my $CreateArticle = $ParamObject->GetParam( Param => 'CreateArticle' );

        my @RequiredParams;
        if ( $CreateArticle ) {
            @RequiredParams = qw/Body Subject/;
        }

        for my $Param (qw(Name), @RequiredParams ) {
            if ( !$GetParam{$Param} ) {
                $Errors{ $Param . 'Invalid' } = 'ServerError';
            }
        }

        $GetParam{Body} //= '';

        if ( %Errors ) {
            $Self->{Subaction} = 'Add';

            my $Output = $LayoutObject->Header();
            $Output .= $LayoutObject->NavigationBar();
            $Output .= $Self->_MaskQuickCloseForm(
                %GetParam,
                %Param,
                %Errors,
                Subaction => 'Save',
            );
            $Output .= $LayoutObject->Footer();
            return $Output;
        }

        my $Success = $QuickCloseObject->QuickCloseAdd(
            %GetParam,
            Permission    => {
                RoleID => $GetParam{RoleID},
            },
            UserID        => $Self->{UserID},
            OwnerID       => $GetParam{OwnerSelected},
            ResponsibleID => $GetParam{ResponsibleSelected},
        );

        if ( !$Success ) {
            return $LayoutObject->ErrorScreen();
        }
        return $LayoutObject->Redirect( OP => "Action=AdminQuickClose" );
    }

    elsif ( $Self->{Subaction} eq 'Delete' ) {
        $QuickCloseObject->QuickCloseDelete( %GetParam );
        return $LayoutObject->Redirect( OP => "Action=AdminQuickClose" );
    }

    # ------------------------------------------------------------ #
    # else ! print form
    # ------------------------------------------------------------ #
    else {
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $Self->_MaskQuickCloseForm();
        $Output .= $LayoutObject->Footer();
        return $Output;
    }
}

sub _MaskQuickCloseForm {
    my ( $Self, %Param ) = @_;

    my $ParamObject      = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject     = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $QuickCloseObject = $Kernel::OM->Get('Kernel::System::QuickClose');
    my $ValidObject      = $Kernel::OM->Get('Kernel::System::Valid');
    my $ConfigObject     = $Kernel::OM->Get('Kernel::Config');
    my $TicketObject     = $Kernel::OM->Get('Kernel::System::Ticket');
    my $StateObject      = $Kernel::OM->Get('Kernel::System::State');
    my $QueueObject      = $Kernel::OM->Get('Kernel::System::Queue');
    my $GroupObject      = $Kernel::OM->Get('Kernel::System::Group');
    my $PriorityObject   = $Kernel::OM->Get('Kernel::System::Priority');

    if ( $Self->{Subaction} eq 'Edit' ) {
        my %QuickClose = $QuickCloseObject->QuickCloseGet( ID => $Param{ID} );
        for my $Key ( keys %QuickClose ) {
            $Param{$Key} = $QuickClose{$Key} if !$Param{$Key};
        }

        $Param{RoleID} = $QuickClose{Permission}->{Role} if !@{ $Param{RoleID} || [] };
    }

    $Param{CreateArticle} = 1 if $Param{Body};

    $Param{ToTypeSelect} = $LayoutObject->BuildSelection(
        Data         => [ qw/Customer Owner Other/ ],
        Name         => 'ToType',
        PossibleNone => 1,
        SelectedID   => $Param{ToType},
        Class        => 'Modernize',
    );

    $Param{RoleSelect} = $LayoutObject->BuildSelection(
        Data       => { $GroupObject->RoleList( Valid => 1 ) },
        Name       => 'RoleID',
        Size       => 5,
        SelectedID => $Param{RoleID},
        HTMLQuote  => 1,
        Multiple   => 1,
        Class      => 'Modernize',
    );

    my $ValidID = $ValidObject->ValidLookup( Valid => 'valid' );

    $Param{ValidSelect} = $LayoutObject->BuildSelection(
        Data       => { $ValidObject->ValidList() },
        Name       => 'ValidID',
        Size       => 1,
        SelectedID => $Param{ValidID} || $ValidID,
        HTMLQuote  => 1,
        Class      => 'Modernize',
    );

    $Param{PrioritySelect} = $LayoutObject->BuildSelection(
        Data         => { $PriorityObject->PriorityList( Valid => 1 ) },
        Name         => 'PriorityID',
        Size         => 1,
        SelectedID   => $Param{PriorityID},
        HTMLQuote    => 1,
        PossibleNone => 1,
        Class        => 'Modernize',
    );

    my $StateTypes = $ConfigObject->Get( 'QuickClose::StateTypes' ) || [ 'closed' ];

    my %States = $StateObject->StateGetStatesByType(
        StateType => $StateTypes,
        Result    => 'HASH',
    );

    $Param{ForceSelected}       = $Param{ForceCurrentUserAsOwner} ? 'checked="checked"' : '';
    $Param{ResponsibleSelected} = $Param{AssignToResponsible}     ? 'checked="checked"' : '';
    $Param{ZoomSelected}        = $Param{ShowTicketZoom}          ? 'checked="checked"' : '';
    $Param{CustomerSelected}    = $Param{ArticleCustomer}         ? 'checked="checked"' : '';

    $Param{StateSelect} = $LayoutObject->BuildSelection(
        Data         => \%States,
        Name         => 'StateID',
        Size         => 1,
        SelectedID   => $Param{StateID},
        HTMLQuote    => 1,
        PossibleNone => 1,
        Class        => 'Modernize',
    );

    $Param{UnlockSelect} = $LayoutObject->BuildSelection(
        Data        => {
            0 => Translatable('No'),
            1 => Translatable('Yes'),
        },
        Name        => 'Unlock',
        Size        => 1,
        SelectedID  => $Param{Unlock},
        Translation => 1,
        Class       => 'Modernize',
    );

    my %Queues;

    if ( $ConfigObject->Get( 'QuickClose::QueueMove' ) ) {
        %Queues = $QueueObject->QueueList();
    }

    $Param{QueueSelect} = $LayoutObject->BuildSelection(
        Data         => \%Queues,
        Name         => 'QueueID',
        Size         => 1,
        SelectedID   => $Param{QueueID},
        HTMLQuote    => 1,
        PossibleNone => 1,
        TreeView     => 1,
        Class        => 'Modernize',
    );

    # get possible notes
    my %NoteTypes = map{  $_ => $_ }qw/Internal Phone Email/;

    $Param{ArticleTypeSelect} = $LayoutObject->BuildSelection(
        Data       => \%NoteTypes,
        Name       => 'ArticleType',
        Class      => 'Modernize',
        SelectedID => $Param{ArticleType},
    );

    my $UserAutoCompleteConfig
        = $ConfigObject->Get('QuickClose::Frontend::UserSearchAutoComplete');


    $LayoutObject->Block(
        Name => 'UserSearchAutoComplete',
        Data => {
            minQueryLength      => $UserAutoCompleteConfig->{MinQueryLength}      || 2,
            queryDelay          => $UserAutoCompleteConfig->{QueryDelay}          || 0.1,
            maxResultsDisplayed => $UserAutoCompleteConfig->{MaxResultsDisplayed} || 20,
            dynamicWidth        => $UserAutoCompleteConfig->{DynamicWidth}        || 'false',
        },
    );

    my $ActiveAutoComplete = 'true';
    if ( !$UserAutoCompleteConfig->{Active} ) {
        $ActiveAutoComplete = 'false';
    }

    $LayoutObject->Block(
        Name => 'UserSearchInit',
        Data => {
            ActiveAutoComplete => $ActiveAutoComplete,
            ItemID             => 'Owner',
        },
    );

    $LayoutObject->Block(
        Name => 'UserSearchInit',
        Data => {
            ActiveAutoComplete => $ActiveAutoComplete,
            ItemID             => 'Responsible',
        },
    );

    if ( $Self->{Subaction} ne 'Edit' && $Self->{Subaction} ne 'Add' ) {

        my %QuickCloseList = $QuickCloseObject->QuickCloseList();
  
        if ( !%QuickCloseList ) {
            $LayoutObject->Block(
                Name => 'NoQuickCloseFound',
            );
        }

        for my $QuickCloseID ( sort { $QuickCloseList{$a} cmp $QuickCloseList{$b} } keys %QuickCloseList ) {
            my %QuickClose = $QuickCloseObject->QuickCloseGet(
                ID => $QuickCloseID,
            );

            $LayoutObject->Block(
                Name => 'QuickCloseRow',
                Data => \%QuickClose,
            );
        }
    }

    $Param{SubactionName} = 'Update';
    $Param{SubactionName} = 'Save' if $Self->{Subaction} && $Self->{Subaction} eq 'Add';

    my $TemplateFile = 'AdminQuickCloseList';
    $TemplateFile = 'AdminQuickCloseForm' if $Self->{Subaction};

    # add rich text editor
    if ( $LayoutObject->{BrowserRichText} ) {

        my $Config = $Kernel::OM->Get('Kernel::Config')->Get("Ticket::Frontend::AgentTicketEmail");

        # use height/width defined for this screen
        $Param{RichTextHeight} = $Config->{RichTextHeight} || 0;
        $Param{RichTextWidth}  = $Config->{RichTextWidth}  || 0;

        # set up rich text editor
        $LayoutObject->SetRichTextParameters(
            Data => \%Param,
        );
    }

    return $LayoutObject->Output(
        TemplateFile => $TemplateFile,
        Data         => \%Param
    );
}

1;
