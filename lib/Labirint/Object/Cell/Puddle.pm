package Labirint::Object::Cell::Puddle;
# Subclass of Labirint::Object::Cell
# $Header: /var/lib/cvsd/root/game/lib/Labirint/Object/Cell/Puddle.pm,v 1.5 2007/02/27 22:23:20 wws Exp $
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
		['O:manager', 'output', 'Куда вы пойдёте от лужи?<br>'],
		['TRUE'],
	],
	'NOCHECK',
	['O:self', 'is', 'visited' ],
	FAIL => [
		['O:manager', 'output', '<br>Вы попали в глубокую лужу.'],
	],
	['O:self', 'is_not', 'visited' ],
	FAIL => [
		['O:manager', 'output', 'Вы опять попали в лужу.'],
	],
	['O:other', 'is_not', 'dry'],
	FAIL => [ # У игрока были сухие шмотки
		'NOCHECK',
		['O:self', 'if', 'O:other->bullets() == 0'],
		FAIL => [
			'NOCHECK',
			['O:self', 'if', 'O:other->wet_bullets()' ],
			FAIL => ['O:manager', 'output', ' Все ваши патроны' ],
			['O:self', 'if', 'O:other->wet_bullets() == 0' ],
			FAIL => [
				['O:manager', 'output', '(O:other->bullets() < 2 ? " Ваш последний сухой патрон" : " Ваши ".O:other->bullets()." сухих патрон".(O:other->bullets() < 5 ? "а": "ов" ) )' ],
			],
			['O:other', 'clear', 'dry' ],
		],
		['O:other', 'is_not', 'skins'],
		FAIL => [
			'NOCHECK',
			['O:other', 'is', 'dry'],
			FAIL => ['O:manager', 'output', ' и добытые шкуры' ],
			['O:other', 'is_not', 'dry'],
			FAIL => ['O:manager', 'output', ' Добытые вами шкуры' ],
			['O:other', 'clear', 'dry' ],
		],
		['O:manager', 'output', ' промокли!' ],
	],
	['O:self',  'set', 'visited' ],
	['O:other', 'set', 'puddles' ],
	'CHECK',
	['O:manager', 'output', '<br>Куда вы пойдёте теперь?<br>'],
      ],
    );
    bless $self, $class;

    $self->new_flag( -name => 'visited', -value =>0 );

    $self->type('лужа');
    $self->short_type('лужа');
    $self->hidden_type($self->short_type);
    $self->umap_type($self->short_type);
    return $self;
}

sub helper { # Another action after Player->in(Cell)
  my ($self, $other ) = @_;
  $other = '' unless defined($other);
  my $hlp=<<_EOT_;
&nbsp;&nbsp;&nbsp;
Лужа, она есть лужа. Мокрая и противная. Наша - несколько глубже чем те, что можно встретить на улице. По счастью, она в лабиринте всего одна.
_EOT_
  $self->manager->help($hlp);
  return 1;
}

1;

__END__
