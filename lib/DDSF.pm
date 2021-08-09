package DDSF;

use v5.014;
use strict;
use warnings;
use Carp qw(croak);
use Math::Random;

=head1 NAME

DDSF - Density dependent scale free network generator

=head1 VERSION

Version v0.001

=cut

our $VERSION = 'v0.001';

=head1 SYNOPSIS

    use DDSF;
    my $foo = DDSF->new( {nodes => n, edges => m, density => E<U+1D68>, outfile => 'OutFile' });
    $foo->ddsf();

=head1 DESCRIPTION

A graph of n nodes is grown by consecutvely adding a node to the seed network
where each new node carrying k edges preferentially attaches to existing nodes
with probability proportional to their degrees. Here k is computed using DDSF
algorithm.

=head2 Parameters
    
    nodes: int
               The number of nodes 
               
    edges: int 
               The number of edges
               
    density: float
                   The density of network
    
    outfile: string
                    The name of output file
                    
    Note: nodes is a mandatory argument, either of edges or density must be passed

=head2 Returns

    Return a DDSF graph G in the outfile

=cut

sub new {
    my ( $Class, $args ) = @_;
    my $Self = bless {
        %$args,
    }, $Class;
}

=head2 function2

=cut

sub ddsf {
    my $Self = shift;
    
    if ( !$Self->{density} && !$Self->{edges} ) {
        croak "Usage: DDSF->new( {nodes => x, edges|density => y });";
    } elsif ( $Self->{edges} && ! $Self->{density} ) {
        $Self->{density} = $Self->density();
    } elsif ( !$Self->{edges} && $Self->{density} ) {
        $Self->{edges} = int $Self->possible_edges();
    }
    
    return "DLow" if $Self->{density} < 2 / $Self->{nodes};                 # From identity dn = 2, where d is density and n is total number of nodes
    return "DLow" if $Self->{edges} < 1;
    
    $Self->{outfile} //= "OutFile";
    my $N = 2;
    open my $f1, ">", "$Self->{outfile}.in";
   
   #### Construct an all to all network----
    my @Visited =( 0, 1 );
    my @PrefAttach = ( 0, 1 );
    print $f1 "0\t1\n";
    
    my $CurrentNode = $Self->seed_net( $N, int $Self->recalculate_edges( \@Visited, \@PrefAttach ), \@Visited, \@PrefAttach, $f1 );
    exit() if $CurrentNode >= $Self->{nodes};
    return $Self->extend_seed( $CurrentNode, \@Visited, \@PrefAttach, $f1, $Self->{outfile});
}


sub seed_net {
    my $Self = shift;
    
    # populate seed network----
    my ( $CurrentNode, $M, $Visited, $PrefAttach, $f1 ) = @_;

    while ( $M > $CurrentNode ) {
        my $newLinks = $CurrentNode - 2;
        foreach my $i1 ( pref_attach( $PrefAttach, $newLinks ) ) {
            push @$PrefAttach, ($CurrentNode, $i1 );
            print $f1 "$i1\t$CurrentNode\n";
        }
        
        print "$M\t$CurrentNode\n";
        push @$Visited, $CurrentNode;
        $M = $Self->recalculate_edges( $Visited, $PrefAttach );
        
        $CurrentNode++;
    }
    return $CurrentNode;
}

sub extend_seed {
    my $Self = shift;
    my ($CurrentNode, $Visited, $PrefAttach, $f1, $path )= @_;
    
    # Recalculate the new density----
    my $Avg_NewLinks = $Self->recalculate_edges( $Visited, $PrefAttach );
    
    my $Cless0 = 0;
    while ( $CurrentNode < $Self->{nodes} ) {
        
        my ( $NewLinks ) = ( 0 );
        until ( $NewLinks > 0 && $NewLinks < @$Visited ) {
            $NewLinks = int (0.5 + random_normal( 1, $Avg_NewLinks, $Avg_NewLinks / 6 ) );
            $Cless0++ if $NewLinks <= 0;
        }
        
        print "$NewLinks\t$Avg_NewLinks\n";
        foreach my $key ( pref_attach( $PrefAttach, $NewLinks ) ) {
            push @$PrefAttach, ( $key, $CurrentNode );
            print $f1 "$key\t$CurrentNode\n";
        }

        push @$Visited, $CurrentNode;
        $CurrentNode++;
    }
    
    my $edg = @$PrefAttach / 2;
    system ("sed -i \"1i$CurrentNode $edg\" ${path}.in");
    return $edg, $Cless0;
}

sub recalculate_edges {
    my $Self = shift;
    my ( $Visited, $PrefAttach ) = @_;
    
    return ( $Self->{edges} - @$PrefAttach / 2 ) / ( $Self->{nodes} - @$Visited );
}

sub pref_attach {
    my ( $PrefAttach, $NewLinks ) = @_;

    my %link;
    while ( scalar keys %link < $NewLinks ) {            
        $link{ $PrefAttach->[ int rand( @$PrefAttach ) ] }++;
    }
    return keys %link;
}

sub density {
    my $Self = shift;
    my ($Nodes, $Edges) = @_;
    
    $Nodes //= $Self->{nodes};
    $Edges //= $Self->{edges};
    
    return 2 * $Edges / ($Nodes * ($Nodes - 1) );
}

sub possible_edges {
    my $Self = shift;
    my ($Nodes, $Density) = @_;
    
    $Nodes //= $Self->{nodes};
    $Density //= $Self->{density};
    
    return $Density * $Nodes * ( $Nodes - 1 ) / 2; # From equation dn(n-1) / 2
}


=head1 AUTHOR

Vikram Singh, C<< <vikram.singh7571 at gmail.com> >>

Vikram Singh*, PhD

=head1 BUGS

Please report any bugs or feature requests to C<bug-ddsf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DDSF>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DDSF


You can also look for information at:


=head1 LICENSE AND COPYRIGHT

Copyright 2019 Vikram Singh.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of DDSF
