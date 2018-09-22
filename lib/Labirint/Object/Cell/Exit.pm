package Labirint::Object::Cell::Exit;
# Subclass of Labirint::Object::Cell
# $Header: /var/lib/cvsd/root/game/lib/Labirint/Object/Cell/Exit.pm,v 1.5 2007/02/27 22:40:30 wws Exp $
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
			['O:other', 'set', 'can_go' ],
			['O:other', 'is_not', 'surrender' ],
			FAIL => [ 
				'NOCHECK',
				['O:manager', 'output', 'Если бы вы не подглядывали в план лабиринта, то вас можно было бы поздравить с тем, что вы умудрились выйти из лабиринта живым.'],
				['O:other', 'clear', 'alive' ], 
				['O:other', 'clear', 'can_go' ],
				'TRUE',
			],
			['O:self', 'if', 'O:other->answer ne "no"' ],
			FAIL => [
				'NOCHECK',
				['O:manager', 'output', 'Вы не выиграли, но'],
				['O:other', 'is_not', 'money_lost'],
				FAIL => ['O:manager', 'output', ', потеряв некоторое количество монет,'],
				['O:manager', 'output', ' смогли выйти живым из лабиринта.'],
				['O:other', 'clear', 'alive' ], 
				['O:other', 'clear', 'can_go' ],
	  			['O:other', 'set', 'show_full_map'],
				'TRUE',
			],
		],
		['O:other', 'is', 'alive' ],
		FAIL => [ 'TRUE', ], # конец игры
		['O:manager', 'output', 'Куда вы пойдёте от выхода из лабиринта?<br>'],
		['TRUE'],
	],
	'NOCHECK',
	['O:self', 'is', 'visited' ],
	FAIL => [
		['O:manager', 'output', 'Вы попали на лестницу, в конце которой имеется выход из лабиринта. '],
	],
	['O:self', 'is_not', 'visited' ],
	FAIL => ['O:manager', 'output', 'Вы попали к выходу из лабиринта. '],
	['O:other', 'is', 'have_key' ],
	FAIL => ['O:manager', 'output', 'Правда у вас нет ключа от этой двери.' ],
	['O:manager', 'output', '<br>'],
	['O:other', 'is_not', 'have_key' ],
	FAIL => [
		['O:other', 'is_not', 'treasure' ],
		FAIL => [
			['O:other', 'clear', 'can_go'],
			['O:other', 'set', 'you_win'],
  			['O:other', 'set', 'show_full_map'],
			['O:other', 'clear', 'alive'],
			['O:other', 'is_not', 'surrender' ],
			FAIL => [ 
				['O:manager', 'output', 'Если бы вы не подглядывали в план лабиринта, то вас можно было бы поздравить с тем, что вы справились с поставленной задачей - нашли клад и сумели выйти живым из лабиринта.'],
				'TRUE',
			],
			['O:manager', 'output', '"Поздравляем! Вы справились с поставленной задачей - нашли клад и сумели выйти живым из лабиринта. (".O:other->steps()." ходов)"'],
			'TRUE',
		],
		'NOCHECK',
		['O:other', 'is_not', 'lipa' ],
		FAIL => [
			['O:manager', 'output', 'Выйдя на солнечный свет, вы открываете сундук с сокровищами и обнаруживаете, что в нем лишь дешёвая чешская бижутерия. Вы можете вернуться в лабиринт и продолжить поиски настоящего клада, либо решить, что жизнь дороже, и закончить игру.<br>Что вы выберете?<br>'],
			['O:other', 'set', 'oups' ],
		],
		['O:other', 'if', 'O:other->is("lipa") || O:other->is("treasure")' ],
		FAIL => [
			['O:manager', 'output', 'Сейчас вы можете решить, что ваша жизнь гораздо дороже любых сокровищ, и выйти из лабиринта ни с чем. Или можете вернуться в лабиринт и продолжить поиски клада.<br>Что вы выберете?<br>'],
		],
		['O:manager', 'question', 'продолжить игру::yes|жизнь дороже::no' ],
		['O:other', 'clear', 'can_go' ],
	],
	['O:self', 'set', 'visited' ],
	['O:other', 'is', 'alive' ],
	FAIL => [ 'TRUE', ], # конец игры
	['O:other', 'is', 'can_go' ],
	FAIL => [ 'TRUE', ],
	['O:manager', 'output', 'Куда вы пойдёте?<br>'],
      ],
    );
    bless $self, $class;

    $self->new_flag( -name => 'visited', -value => 0 );

    $self->type('выход из лабиринта');
    $self->short_type('выход');
    $self->hidden_type($self->short_type);
    $self->umap_type($self->short_type);
    return $self;
}

1;

__END__
