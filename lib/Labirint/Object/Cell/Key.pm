package Labirint::Object::Cell::Key;
# Subclass of Labirint::Object::Cell
# $Header: /var/lib/cvsd/root/game/lib/Labirint/Object/Cell/Key.pm,v 1.3 2007/02/27 22:23:20 wws Exp $
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
	['O:self', 'set', 'known_location' ],
	['O:self', 'if', '! A:safe'],
	FAIL => [
		'NOCHECK',
		['O:manager', 'output', 'Куда вы пойдёте из клетки где находился ключ от выхода из лабиринта?<br>'],
		['TRUE'],
	],
	'NOCHECK',
	['O:self', 'is', 'visited' ],
	FAIL => [
		['O:manager', 'output', 'Поздравляем, вы только что нашли ключ от выхода из лабиринта!<br>'],
		['O:other', 'set', 'have_key' ],
	],
	['O:self', 'is_not', 'visited' ],
	FAIL => ['O:manager', 'output', 'Вы попали в то место, где был ключ от лабиринта.<br>'],
	'CHECK',
	['O:self', 'set', 'visited' ],
	['O:manager', 'output', 'Куда вы пойдёте дальше?<br>'],
      ],
    );
    bless $self, $class;

    $self->new_flag( -name => 'visited', -value => 0 );

    $self->type('ключ от выхода из лабиринта');
    $self->short_type('ключ');
    $self->hidden_type($self->short_type);
    $self->umap_type($self->short_type);
    return $self;
}

sub helper { # Another action after Player->in(Cell)
  my ($self, $other ) = @_;
  $other = '' unless defined($other);
  my $hlp=<<_EOT_;
&nbsp;&nbsp;&nbsp;
Ключ это то, без чего из лабиринта не выбраться. Он здесь всего один.
_EOT_
  $self->manager->help($hlp);
  return 1;
}

1;

__END__
