package Labirint::Object::Cell::Lipa;
# Subclass of Labirint::Object::Cell
# $Header: /var/lib/cvsd/root/game/lib/Labirint/Object/Cell/Lipa.pm,v 1.4 2007/02/27 22:23:20 wws Exp $
#

use strict;
use Engine::Debuger;

use Labirint::Object::Cell;
use vars qw(@ISA);
@ISA = qw(Labirint::Object::Cell);
use warnings;

sub new {
    # Create object
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_,
      -on_entrance => [ # O:other = Player O:self = Cell
	['O:self', 'if', '! A:safe'],
	FAIL => [
		['O:manager', 'output', 'Куда вы пойдёте из клетки где находился сундук с кладом?<br>'],
		'TRUE',
	],
	'NOCHECK',
	['O:other', 'is', 'lipa' ],
	FAIL => [
		['O:manager', 'output', 'Поздравляем, вы нашли сундук с кладом!<br>'],
	],
	['O:other', 'is_not', 'lipa' ],
	FAIL => [
		['O:manager', 'output', 'Вы попали в то место, где стоял сундук с кладом.<br>'],
	],
	['O:other', 'set', 'lipa' ],
	['O:other', 'is_not', 'treasure' ],
	FAIL => [
		'NOCHECK',
		['O:other', 'is', 'oups'],
		FAIL => [
			['O:manager', 'output', 'Не удивляйтесь, в лабиринте спрятано два клада, и лишь один из них настоящий.<br>'],
			['O:other', 'set', 'oups'],
		],
	],
	'CHECK',
	['O:other', 'set', 'lipa' ],
	['O:manager', 'output', 'Куда вы пойдёте дальше?<br>'],
      ],
    );
    bless $self, $class;

    $self->type('ложный клад');
    $self->short_type('клад');
    $self->hidden_type('клад<br>ложн.');
    $self->umap_type($self->short_type);
    return $self;
}

sub helper { # Another action after Player->in(Cell)
  my ($self, $other ) = @_;
  $other = '' unless defined($other);
  my $hlp=<<_EOT_;
&nbsp;&nbsp;&nbsp;
Много тут всяких сундуков понаставили.
_EOT_
  $self->manager->help($hlp);
  return 1;
}

1;

__END__
