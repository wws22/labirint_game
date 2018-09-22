package Labirint::Object::Cell::Shop;
# Subclass of Labirint::Object::Cell
# $Header: /var/lib/cvsd/root/game/lib/Labirint/Object/Cell/Shop.pm,v 1.3 2007/02/27 22:23:20 wws Exp $
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
				['O:self', 'exchange', 'O:other' ],
				['O:manager', 'output', 'Вы успешно произвели обмен. '],
			],
			['O:other', 'set', 'can_go' ],
			['O:other', 'answer', '' ], # unset player answer
		],
		['O:manager', 'output', 'Куда вы пойдёте из лавки?<br>'],
		['TRUE'],
	],
	'NOCHECK',
	['O:other', 'if', 'O:other->is_not("skins") || O:other->is("puddles")' ],
	FAIL => [
		['O:manager', 'output', 'Поздравляем! '],
	],
	['O:manager', 'output', 'Вы попали в скорняжную лавку.<br>'],
	'CHECK',
	['O:other', 'is_not', 'skins' ],
	FAIL => [
		'NOCHECK',
		['O:other', 'if', 'O:other->is("puddles") && O:other->is_not("dry")' ],
		FAIL => [
			['O:manager', 'output', 'Здесь с удовольствием обменяют имеющиеся у вас сухие шкуры на новенькие патроны. Будете менять?<br>' ],
			['O:manager', 'question', 'да::yes|нет::no' ],
			['O:other', 'clear', 'can_go' ],
			'TRUE',
		],
		['O:manager', 'output', 'Правда, за имеющиеся у вас сырые шкуры, можно легко получить от скорняка не менее сырые патроны. '],
		['O:other', 'if', 'O:other->money() <= 0' ],
		FAIL => [ 'O:manager', 'output', 'Сперва вам стоит наведаться в сушилку. ' ],
		[ 'O:manager', 'output', '<br>' ],
		['O:manager', 'output', 'Куда вы пойдёте дальше?<br>'],
		'TRUE',
	],
	['O:manager', 'output', 'Куда вы из неё пойдёте?<br>'],
      ],
    );
    bless $self, $class;

    $self->type('скорняжная лавка');
    $self->short_type('лавка');
    $self->hidden_type($self->short_type);
    $self->umap_type($self->short_type);
    return $self;
}

sub exchange { # Меняем шкуры на патроны 
  my ($self, $Player ) = @_;
  my $World = $self->manager;
  my @contain = @{$Player->related('contain')};
  foreach(@contain){
    my $Animal = $World->find($_);
    if($Animal->is('dry')){
	$Player->mod_bullets($Animal->health);
	$World->uncontain($Animal,$Player);
    }
  }
  @contain = @{$Player->related('contain')};
  $Player->clear('skins') if ($#contain < 0);
  return 1;
}

1;

__END__
