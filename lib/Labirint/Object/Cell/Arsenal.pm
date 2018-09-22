package Labirint::Object::Cell::Arsenal;
# Subclass of Labirint::Object::Cell
# $Header: /var/lib/cvsd/root/game/lib/Labirint/Object/Cell/Arsenal.pm,v 1.5 2007/02/27 22:23:20 wws Exp $
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
			['O:self', 'if', 'O:other->answer ne "yes" || O:self->is("empty")' ],
			FAIL => [
				['O:other', 'mod_bullets', 7 ],
				['O:self', 'set', 'empty' ],
				['O:other', 'set', 'dry' ], # Появились сухие патроны
				['O:manager', 'output', 'Вы взяли семь сухих патронов. '],
			],
			['O:other', 'set', 'can_go' ],
			['O:other', 'answer', '' ], # unset player answer
		],
		['O:manager', 'output', 'Куда вы пойдёте из арсенала?<br>'],
		['TRUE'],
	],
	'NOCHECK',
	['O:manager', 'output', 'Вы попали в '],
	['O:self', 'is_not', 'empty' ],
	FAIL => [
		['O:manager', 'output', 'пустой '],
	],
	['O:manager', 'output', 'арсенал.<br>'],
	['O:self', 'is', 'empty' ],
	FAIL => [
		['O:manager', 'output', ' Вы можете взять здесь семь сухих патронов. Хотите их взять прямо сейчас?<br>' ],
		['O:manager', 'question', 'да::yes|нет::no' ],
		['O:other', 'clear', 'can_go' ],
		'TRUE',
	],
	'CHECK',
	['O:manager', 'output', 'Куда вы пойдёте теперь?<br>'],
      ],
    );
    bless $self, $class;

    $self->new_flag( -name => 'empty', -value => 0 );

    $self->type('арсенал');
    $self->short_type('арсе-<br>нал');
    $self->hidden_type($self->short_type);
    $self->umap_type($self->short_type);
    return $self;
}

sub helper { # Another action after Player->in(Cell)
  my ($self, $other ) = @_;
  $other = '' unless defined($other);
  my $hlp=<<_EOT_;
&nbsp;&nbsp;&nbsp;
В лабиринте есть всего один арсенал и в нем имеется всего одна обойма.
<br>&nbsp;&nbsp;&nbsp;
А что вы хотите? Много тут всяких искателей сокровищ шастает. Растащили всё.
_EOT_
  $self->manager->help($hlp);
  return 1;
}

1;

__END__
