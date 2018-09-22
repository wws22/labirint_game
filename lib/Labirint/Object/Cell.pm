package Labirint::Object::Cell;
# Subclass of Labirint::Object
# $Header: /var/lib/cvsd/root/game/lib/Labirint/Object/Cell.pm,v 1.7 2007/02/28 10:35:22 wws Exp $
#

use strict;
use Engine::Debuger;

use Labirint::Object;
use vars qw(@ISA);
@ISA = qw(Labirint::Object);
use warnings;

use constant LSIZE => 5; # Labirint square size

sub new {
    # Create object
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_,
      -on_in => [
	['O:self', 'if', 'O:self->class eq "Labirint::Object::Cell"'],
	FAIL => [
		['O:other', 'entrance', 'O:self', '{ safe => A:safe }' ],
		['O:self', 'helper', 'O:other' ],
		['TRUE'],
	],
	['O:self', 'set', 'known_location' ],
	['O:manager', 'output', 'Вы попали в пустую клеточку.'],
	['O:self', 'helper', 'O:other' ],
      ],
    );
    bless $self, $class;
    # Add attributes
    $self->new_attr(
	-name	=> 'lsize',
	-type	=> 'int',
	-value	=> LSIZE,
    );
    my $x=0;
    my $y=0;
    ($_,$x,$y) = split( /_/, $self->id() ) if defined($self->id);
    $self->new_attr(
	-name	=> 'x',
	-type	=> 'int',
	-value	=> $x, # 1..5
	-minimum => 0, # 0 is special case (CELL is out of labirint)
	-maximum => LSIZE,
    );
    $self->new_attr(
	-name	=> 'y',
	-type	=> 'int',
	-value	=> $y,
	-minimum => 0, # 1..5
	-maximum => LSIZE, # 0 is special case (CELL is out of labirint)
    );
    $self->new_attr( # Short type of cell (for place to map)
	-name	=> 'short_type',
	-type	=> 'string',
	-value  => ''
    );
    $self->new_attr( # Hiden type of cell (for place to hidden map)
	-name	=> 'hidden_type',
	-type	=> 'string',
	-value  => ''
    );
    $self->new_attr( # User map type of cell (for place to open map)
	-name	=> 'umap_type',
	-type	=> 'string',
	-value  => ''
    );

    #Walls
    my $dir = 'up';
    $self->new_flag( -name => $dir,	-value => ( $y==LSIZE	? 1 : 0 ),
	-on_set => ['O:self', 'set_walls_around', $dir, 1 ],
	-on_clear => ['O:self', 'set_walls_around', $dir, 0 ],
    );
    $dir = 'down';
    $self->new_flag( -name => $dir,	-value => ( $y==1	? 1 : 0 ),
	-on_set => ['O:self', 'set_walls_around', $dir, 1 ],
	-on_clear => ['O:self', 'set_walls_around', $dir, 0 ],
    );
    $dir = 'left';
    $self->new_flag( -name => $dir,	-value => ( $x==1	? 1 : 0 ),
	-on_set => ['O:self', 'set_walls_around', $dir, 1 ],
	-on_clear => ['O:self', 'set_walls_around', $dir, 0 ],
    );
    $dir = 'right';
    $self->new_flag( -name => $dir,	-value => ( $x==LSIZE	? 1 : 0 ),
	-on_set => ['O:self', 'set_walls_around', $dir, 1 ],
	-on_clear => ['O:self', 'set_walls_around', $dir, 0 ],
    );
    $self->new_attr(
	-name	=> 'walls_placed',
	-type	=> 'int',
	-value	=> (($y==LSIZE || $y==1) ? 1 : 0 ) + (($x==LSIZE || $x==1) ? 1 : 0 ),
    );
    # Checked zone - used when labirint builded
    $self->new_attr(
	-name	=> 'zone',
	-type	=> 'int',
	-value	=> 0,
    );

    $self->type('пустая клеточка');
    $self->short_type('пусто');
    $self->umap_type($self->short_type);
    $self->hidden_type($self->short_type);

    # Users map attrs
    $self->new_flag( -name => 'known_from_up', -value => 0 );
    $self->new_flag( -name => 'known_from_down', -value => 0 );
    $self->new_flag( -name => 'known_from_left', -value => 0 );
    $self->new_flag( -name => 'known_from_right', -value => 0 );
    $self->new_flag( -name => 'known_from_hole', -value => 0 );
    $self->new_flag( -name => 'known_location', -value =>0,
      -on_set => [
	['O:self', 'set', 'known_from_up' ],
	['O:self', 'set', 'known_from_down' ],
	['O:self', 'set', 'known_from_left' ],
	['O:self', 'set', 'known_from_right' ],
      ]
    );
    $self->new_attr(
	-name	=> 'p_x',
	-type	=> 'int',
	-value	=> 0,
    );
    $self->new_attr(
	-name	=> 'p_y',
	-type	=> 'int',
	-value	=> 0,
    );
    $self->new_attr(
	-name	=> 'multi_loc',
	-type	=> 'string',
	-value	=> '',
    );
    $self->new_flag( -name => 'p_up',	-value => 0 );
    $self->new_flag( -name => 'p_down',	-value => 0 );
    $self->new_flag( -name => 'p_left',	-value => 0 );
    $self->new_flag( -name => 'p_right',-value => 0 );
    $self->new_attr( -name => 'p_m_up',		-type => 'string', -value => '' );
    $self->new_attr( -name => 'p_m_down',	-type => 'string', -value => '' );
    $self->new_attr( -name => 'p_m_left',	-type => 'string', -value => '' );
    $self->new_attr( -name => 'p_m_right',	-type => 'string', -value => '' );

    return $self;
}

sub set_walls_around { # Set/Clear walls flags for nearest
  my $self = shift;
  my $dir = shift;
  my $set = shift;
  return 0 unless defined($dir);
  return 0 unless defined($set);
  if($set){
    $self->mod_walls_placed(+1);
  }else{
    $self->mod_walls_placed(-1);
  }
  if( $set && $self->walls_placed > 3 ){ # Maximum reached
	$self->clear($dir);
	return 0;
  }
  my $World=$self->manager || return 0;
  my $reverse;
  my $x=$self->x;
  my $y=$self->y;

  if( $dir eq 'up' ){
	$reverse='down'; $y++;
  }elsif( $dir eq 'down' ){
	$reverse='up'; $y--;
  }elsif( $dir eq 'left' ){
	$reverse='right'; $x--
  }elsif( $dir eq 'right' ){
	$reverse='left'; $x++;
  }else{
	return 0;
  }
  my $Near = $World->find('Cell_'.$x.'_'.$y);
  return 1 unless defined($Near);
  if( $set ){
    $Near->set($reverse);
    unless( $Near->is($reverse) ){
	$self->clear($dir);
	return 0;
    }
  }else{
    $Near->clear($reverse);
    if( $Near->is($reverse) ){
	$self->set($dir);
	return 0;
    }
  }
  return 1; # Success
}

sub helper { # Another action after Player->in(Cell)
  my ($self, $other ) = @_;
  $other = '' unless defined($other);
  my $hlp=<<_EOT_;
&nbsp;&nbsp;&nbsp;
_EOT_
  $self->manager->help($hlp);
  return 1;
}

1;

__END__
