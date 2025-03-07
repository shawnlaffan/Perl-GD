package GD::Polygon;

use strict;
use Carp 'carp';
use GD;
use vars '$VERSION';
$VERSION = '2.81';

# old documentation error
*GD::Polygon::delete = \&deletePt;

=head1 NAME

GD::Polygon - Polygon class for the GD image library

=head1 SYNOPSIS

See L<GD>

=head1 DESCRIPTION

See L<GD>

=head1 AUTHOR

The GD.pm interface is copyright 1995-2005, Lincoln D. Stein.  It is
distributed under the same terms as Perl itself.  See the "Artistic
License" in the Perl source code distribution for licensing terms.

The latest versions of GD.pm are available on CPAN:

  http://www.cpan.org

=head1 SEE ALSO

L<GD>
L<GD::Polyline>,
L<GD::SVG>,
L<GD::Simple>,
L<Image::Magick>

=cut

### The polygon object ###
# create a new polygon
sub new {
    my $class = shift;
    return bless { 'length'=>0,'points'=>[] },$class;
}

# automatic destruction of the polygon
sub DESTROY {
    my $self = shift;
    undef $self->{'points'};
}

sub clear {
  my $self = shift;
  $self->{'points'} = [];
  $self->{'length'} = 0;
}

# add an x,y vertex to the polygon
sub addPt {
    my($self,$x,$y) = @_;
    push(@{$self->{'points'}},[$x,$y]);
    $self->{'length'}++;
}

# get a vertex
sub getPt {
    my($self,$index) = @_;
    return () unless ($index >= 0) && ($index < $self->{'length'});
    return @{$self->{'points'}->[$index]};
}

# change the value of a vertex
sub setPt {
    my($self,$index,$x,$y) = @_;
    unless (($index>=0) && ($index<$self->{'length'})) {
	carp "Attempt to set an undefined polygon vertex";
	return undef;
    }
    @{$self->{'points'}->[$index]} = ($x,$y);
    1;
}

# return the total number of vertices
sub length {
    shift->{'length'}
}

# return the array of vertices.
# each vertex is an two-member (x,y) array
sub vertices {
    @{shift->{'points'}}
}

# return the bounding box of the polygon
# (smallest rectangle that contains it)
sub bounds {
    my $self = shift;
    my($top,$bottom,$left,$right) = @_;
    $top =    99999999;
    $bottom =-99999999;
    $left =   99999999;
    $right = -99999999;
    my $v;
    foreach $v ($self->vertices) {
	$left = $v->[0] if $left > $v->[0];
	$right = $v->[0] if $right < $v->[0];
	$top = $v->[1] if $top > $v->[1];
	$bottom = $v->[1] if $bottom < $v->[1];
    }
    return ($left,$top,$right,$bottom);
}

# delete a vertex, returning it, just for fun
sub deletePt {
     my($self,$index) = @_;
     unless (($index>=0) && ($index<@{$self->{'points'}})) {
 	carp "Attempt to delete an undefined polygon vertex";
 	return undef;
     }
      my($vertex) = splice(@{$self->{'points'}},$index,1);
     $self->{'length'}--;
      return @$vertex;
  }

# translate the polygon in space by deltaX and deltaY
sub offset {
    my($self,$dh,$dv) = @_;
    my $size = $self->length;
    my($i);
    for ($i=0;$i<$size;$i++) {
	my($x,$y)=$self->getPt($i);
	$self->setPt($i, $x+$dh, $y+$dv);
    }
}

# map the polygon from sourceRect to destRect,
# translating and resizing it if necessary
sub map {
    my($self,$srcL,$srcT,$srcR,$srcB,$destL,$destT,$destR,$destB) = @_;
    my($factorV) = ($destB-$destT)/($srcB-$srcT);
    my($factorH) = ($destR-$destL)/($srcR-$srcL);
    my($vertices) = $self->length;
    my($i);
    for ($i=0;$i<$vertices;$i++) {
	my($x,$y) = $self->getPt($i);
	$x = int($destL + ($x - $srcL) * $factorH);
	$y = int($destT + ($y - $srcT) * $factorV);
	$self->setPt($i,$x,$y);
    }
}

# These routines added by Winfriend Koenig.
sub toPt {
    my($self, $dx, $dy) = @_;
    unless ($self->length > 0) {
	$self->addPt($dx,$dy);
	return;
    }
    my ($x, $y) = $self->getPt($self->length-1);
    $self->addPt($x+$dx,$y+$dy);
}

sub transform($$$$$$$) {
    # see PostScript Ref. page 154
    # documented as the affine transformation matrix: (xx,yx,xy,yy,x0,y0)
    # note that even the libgd doc is wrong here for yy.
    my($self, $sx, $sy, $rx, $ry, $tx, $ty) = @_;
    my $size = $self->length;
    for (my $i=0; $i<$size; $i++) {
        my($x,$y) = $self->getPt($i);
        # gdAffineApplyToPointF:
	# dst->x = x * affine[0] + y * affine[2] + affine[4];
	# dst->y = x * affine[1] + y * affine[3] + affine[5];
	$self->setPt($i, $x*$sx + $y*$ry + $tx, $x*$rx + $y*$sy + $ty);
    }
}

sub scale {
    my($self, $sx, $sy, $tx, $ty) = @_;
    $sy = $sx unless defined $sy;
    $self->offset(-$tx,-$ty) if defined $tx or defined $ty;
    $self->transform($sx,$sy,0,0,$tx,$ty);
}

# clockwise in radians
sub rotate {
    my($self, $r) = @_;
    my ($s, $c) = (sin($r), cos($r));
    $self->transform($c,$c,-$s,$s, 0,0);
}

1;
