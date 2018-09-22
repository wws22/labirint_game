package Labirint::Object::Cell::Band;
# Subclass of Labirint::Object::Cell
# $Header: /var/lib/cvsd/root/game/lib/Labirint/Object/Cell/Band.pm,v 1.4 2007/02/27 22:23:20 wws Exp $
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
		['O:manager', 'output', 'Куда вы пойдёте от банды?<br>'],
		'TRUE',
	],
	'NOCHECK',
	['O:other', 'if', 'O:other->is("lipa") || O:other->is("treasure")' ],
	FAIL => [
		['O:self', 'is', 'visited'],
		FAIL => [
			['O:manager', 'output', 'Вы встретились с бандой разбойников, которая спрятала в лабиринте свои сокровища.<br>'],
		],
		['O:self', 'is_not', 'visited'],
		FAIL => [
			['O:manager', 'output', 'Вы опять встретились с бандой разбойников. К счастью, вы не обременены тяжелой поклажей.<br>'],
		],
	],
	['O:other', 'if', '!(O:other->is("lipa") || O:other->is("treasure"))' ],
	FAIL => [
		'NOCHECK',
		['O:self', 'is', 'visited'],
		FAIL => [
			['O:manager', 'output', 'Вы наткнулись на банду разбойников. Оказывается, это именно они спрятали в лабиринте свои сокровища. '],
		],
		['O:self', 'is_not', 'visited'],
		FAIL => [
			['O:manager', 'output', 'Вы опять напоролись на банду разбойников. '],
		],
		['O:other', 'if', 'O:other->is("lipa") && O:other->is("treasure")' ],
		FAIL => [
			['O:manager', 'output', 'Они отобрали у вас сундук с кладом, однако, освободившись от сундука, вам удается бежать.<br>'],
		],
		['O:other', 'if', '!(O:other->is("lipa") && O:other->is("treasure"))' ],
		FAIL => [
			['O:manager', 'output', 'Они отобрали у вас оба сундука, однако, освободившись от тяжелой поклажи, вам самому удается бежать.<br>'],
		],
	],
	['O:other', 'clear', 'treasure' ],
	['O:other', 'clear', 'lipa' ],
	['O:self', 'set', 'visited' ],
	['O:manager', 'output', 'Куда вы убежите от банды?<br>'],
      ],
    );
    bless $self, $class;
    $self->new_flag( -name => 'visited', -value => 0 );

    $self->type('банда разбойников');
    $self->short_type('банда');
    $self->hidden_type($self->short_type);
    $self->umap_type($self->short_type);
    return $self;
}

1;

__END__
