package Labirint::Object::Cell::Dry;
# Subclass of Labirint::Object::Cell
# $Header: /var/lib/cvsd/root/game/lib/Labirint/Object/Cell/Dry.pm,v 1.6 2007/02/27 22:23:20 wws Exp $
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
		['O:other', 'is', 'can_go'],
		FAIL => [
			'NOCHECK',
			['O:self', 'if', 'O:other->answer ne "yes"' ],
			FAIL => [
				'NOCHECK',
				['O:self', 'if', 'O:other->money() == 0' ],
				FAIL => [
					['O:other', 'mod_money', -1 ],
					['O:other', 'set', 'dry' ], # Появились сухие вещи
					['O:other', 'clear', 'puddles' ], # В луже пока не побывали
					['O:manager', 'output', 'Ваши вещи теперь высушены.<br>'],
				],
			],
			['O:other', 'set', 'can_go' ],
			['O:other', 'answer', '' ], # unset player answer
		],
		['O:manager', 'output', 'Куда вы пойдёте из сушилки?<br>'],
		['TRUE'],
	],
	'NOCHECK',
	['O:self', 'is', 'visited' ],
	FAIL => [
		'NOCHECK',
		['O:other', 'is_not', 'puddles' ],
		FAIL => ['O:manager', 'output', 'Поздравляем! '],
	],
	['O:manager', 'output', 'Вы попали в сушилку.<br>'],
	['O:self', 'set', 'visited' ],
	['O:other', 'is_not', 'puddles' ],
	FAIL => [ # С последней сушки мы вновь посещали лужу
		['O:self', 'if', 'O:other->money() == 0' ],
		FAIL => [
			['O:manager', 'output', 'Будете сушить свои вещи? Это стоит одну монету.<br>' ],
			['O:manager', 'question', 'да::yes|нет::no' ],
			['O:other', 'clear', 'can_go' ],
			'TRUE',
		],
		['O:manager', 'output', 'Только у вас нет денег, чтобы заплатить за сушку вещей.<br>' ],
	],
	'CHECK',
	['O:other', 'is_not', 'can_go' ],
	FAIL => [
		['O:manager', 'output', 'Куда вы пойдёте теперь?<br>'],
		'TRUE',
	],
      ],
    );
    bless $self, $class;

    $self->new_flag( -name => 'visited', -value =>0 );

    $self->type('сушилка');
    $self->short_type('сушка');
    $self->hidden_type($self->short_type);
    $self->umap_type($self->short_type);
    return $self;
}

sub helper { # Another action after Player->in(Cell)
  my ($self, $other ) = @_;
  $other = '' unless defined($other);
  my $hlp=<<_EOT_;
&nbsp;&nbsp;&nbsp;
Сушилка это то место, где можно сушить разные вещи. Запомните это место, 
оно в лабиринте всего одно, и, наверняка, оно вам ещё понадобится.
_EOT_
  $self->manager->help($hlp);
  return 1;
}

1;

__END__
