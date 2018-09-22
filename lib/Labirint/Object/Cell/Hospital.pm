package Labirint::Object::Cell::Hospital;
# Subclass of Labirint::Object::Cell
# $Header: /var/lib/cvsd/root/game/lib/Labirint/Object/Cell/Hospital.pm,v 1.3 2007/02/27 22:23:20 wws Exp $
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
					['O:other', 'bites', 0 ],
					['O:manager', 'output', 'Теперь вы можете забыть о последствиях ранее полученных укусов.<br>'],
				],
			],
			['O:other', 'set', 'can_go' ],
			['O:other', 'answer', '' ], # unset player answer
		],
		['O:manager', 'output', 'Куда вы пойдёте из больницы?<br>'],
		['TRUE'],
	],
	'NOCHECK',
	['O:other', 'if', 'O:other->bites() == 0 || O:other->money() == 0' ],
	FAIL => ['O:manager', 'output', 'Поздравляем! '],
	['O:manager', 'output', 'Вы попали в больницу.<br>'],
	['O:other', 'if', 'O:other->bites() == 0' ],
	FAIL => [ 
		['O:self', 'if', 'O:other->money() == 0' ],
		FAIL => [
			['O:manager', 'output', 'Здесь, всего за одну монету, вам могут подлечить ваши раны. Будете ли вы лечиться?<br>' ],
			['O:manager', 'question', 'да::yes|нет::no' ],
			['O:other', 'clear', 'can_go' ],
			'TRUE',
		],
		['O:manager', 'output', 'К сожалению, у вас совсем не осталось монет, чтобы заплатить за оказание медицинской помощи.<br>' ],
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

    $self->type('больница');
    $self->short_type('боль-<br>ница');
    $self->hidden_type($self->short_type);
    $self->umap_type($self->short_type);
    return $self;
}

1;

__END__
