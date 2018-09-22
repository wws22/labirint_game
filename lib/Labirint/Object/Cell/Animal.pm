package Labirint::Object::Cell::Animal;
# Subclass of Labirint::Object::Cell
# $Header: /var/lib/cvsd/root/game/lib/Labirint/Object/Cell/Animal.pm,v 1.6 2007/02/27 22:23:20 wws Exp $
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
		'NOCHECK',
		['O:self', 'umap_type', 'O:self->hidden_type' ],
		['O:other', 'is', 'can_go'],
		FAIL => [
			'NOCHECK',
			['O:self', 'if', 'O:other->answer() <= O:other->bullets() && O:other->answer() >= 0' ],
			FAIL => [
				'NOCHECK',
				['O:manager', 'output', '"Ай, ай, ай! Пока вы пытались сжульничать, кто-то укусил вас два раза.<br>"'],
				['O:self', 'if', '0 + O:other->answer() < 0' ],
				FAIL => ['O:other', 'mod_bullets', '0 - O:other->answer()' ],
				['O:other', 'mod_bites', +2 ],
				['O:other', 'is', 'alive' ],
				FAIL => [ 'TRUE', ], # Проигрыш
				['O:other', 'set', 'can_go'],
				['O:manager', 'output', 'Мораль - не надо жульничать! Куда пойдем?<br>'],
				'TRUE',
			],
			['O:other', 'mod_bullets', '0 - O:other->answer()' ],
			['O:self', 'if', 'O:other->answer() <= O:self->health()' ],
			FAIL => [ # Изрешетили нахрен
				'NOCHECK',
				['O:self', 'health' ],
				FAIL => [ # Зеркало или корова, коза и.т.п безобидные
					'NOCHECK',
					['O:self', 'is', 'mirror'],
					FAIL=> ['O:manager', 'output', '"Вы лишились ". O:self->animal_name().".<br>"'],
					['O:self', 'is_not', 'mirror'],
					FAIL=> ['O:manager', 'output', 'Вы разбили зеркало. '],
				],
				['O:self', 'if', 'O:self->health() == 0' ],
				FAIL => [ # Зверь
					['O:manager', 'output', '"Вы, только что, испортили шкуру ".O:self->animal_name().".<br>"'],
				],
				['O:self', 'clear', 'alive' ],
			],
			['O:self', 'if', 'O:other->answer() != O:self->health()' ],
			FAIL => [ # Попали как надо или не стреляли
				'CHECK',
				['O:self', 'health'],
				FAIL => [ # Безобидное
					['O:manager', 'output', '"Правильно, это всего лишь ".O:self->type().". "'],
					['O:other', 'set', 'can_go' ],
				],
				# Не безобидное и у нас есть чья-то шкура
				['O:self', 'clear', 'alive' ],
				['O:manager', 'output', '"Поздравляем! Теперь у вас есть шкура ".O:self->animal_name().", за которую вы можете получить в лавке ".O:self->health()." патрон".((O:self->health() > 1) ? "а. " : ". ")'],
				['O:manager', 'contain', 'O:other', 'O:self'],
				['O:other', 'set', 'skins' ], # Появились шкуры
				['O:other', 'set', 'dry' ],   # Появилась сухая шмотка
			],
			# Тут всего один вариант - какое-то кусучее
			'NOCHECK',
			['O:self', 'if', 'O:other->answer() >= O:self->health()' ],
			FAIL => [ # И нас оно покусало
				'NOCHECK',
				['O:self', 'if', 'O:other->answer() + 0 > 0 ' ],
				FAIL => [
					['O:self', 'if', 'O:other->bullets() <= O:self->health()' ],
					FAIL => ['O:manager', 'output', 'Надо было стрелять! ' ],
				],
				['O:self', 'if', 'O:other->answer() + 0 <= 0 ' ],
				FAIL => ['O:manager', 'output', 'O:other->answer()." это слишком мало! "'],
				['O:manager', 'output', '"Это оказался ".O:self->type().". Чтобы его убить, надо было сделать не менее ".O:self->health().((O:self->health() > 1) ? "-х выстрелов" : "-го выстрела").". Он укусил вас и скрылся в темноте. "'],
				['O:other', 'mod_bites', +1 ],
			],
			['O:other', 'is', 'alive' ],
			FAIL => [ 'TRUE', ], # конец игры
			['O:other', 'set', 'can_go' ],
		],
		['O:other', 'is', 'alive' ],
		FAIL => [ 'TRUE', ], # конец игры
		['O:manager', 'output', 'Куда вы пойдёте дальше?<br>'],
		['TRUE'],
	],
	'NOCHECK',
	['O:self', 'is', 'alive' ],
	FAIL => [
		['O:manager', 'output', '"Перед вами ".O:self->dead_type().". <br>Куда вы направитесь от них?"'],
		'TRUE',
	],
	['O:manager', 'output', 'Впереди зелёные глаза в темноте.<br>'],
	['O:self', 'if', 'O:other->bullets() == 0' ],
	FAIL => [
		['O:manager', 'output', 'Сколько выстрелов вы сделаете в них?<br>' ],
		['O:other', 'clear', 'can_go' ],
		['O:self', 'shutting', 'O:other' ],
		'TRUE',
	],
	['O:self', 'umap_type', 'O:self->hidden_type' ],
	['O:manager', 'output', 'А вам нечем стрелять! '],
	['O:self', 'health'],
	FAIL => [
		['O:manager', 'output', '"Это всего-лишь ".O:self->type().".<br>Куда вы пойдёте от ".O:self->animal_name()."?<br>"'],
		'TRUE',
	],
	['O:manager', 'output', '"Это оказался ".O:self->type().".<br>Чтобы его убить, нужно не менее ".O:self->health().((O:self->health() > 1) ? "-х выстрелов" : "-го выстрела").". Разумеется, он вас укусил."'],
	['O:other', 'mod_bites', +1 ], # Увеличиваем количество укусов
	'CHECK',
	['O:other', 'is', 'can_go' ], # Это мог быть и фатальный укус.
	['O:manager', 'output', '<br>Куда вы будете убегать?<br>'],
      ],
    );
    bless $self, $class;

    $self->new_flag( -name => 'alive', -value =>1,
      -on_clear => [
	[ 'O:self', 'dead_type', '"кости ".O:self->animal_name()' ],
	[ 'O:self', 'set', 'known_location' ],
	[ 'O:self', 'is_not', 'mirror' ],
	FAIL => [ 'O:self', 'dead_type', '"осколки ".O:self->animal_name()' ],
      ],
    );
    $self->new_attr( # Здесь будет наименование в родительном падеже
	-name	=> 'animal_name',
	-type	=> 'string',
	-value  => '',
    );
    $self->new_attr( # Здесь будет наименование убитого животного
	-name	=> 'dead_type',
	-type	=> 'string',
	-value  => '',
    );
    $self->new_flag( # !!!!!!!!!!!! Special case for mirror !!!!!!!!!!!!!!
	-name	=> 'mirror', -value  => 0,
    );
    $self->new_flag( -name => 'dry',    -value => 1 ); # For skins

    $self->new_attr(
	-name	 => 'health',
	-type	 => 'int',
	-value	 => 0,
	-minimum => 0,
	-maximum => 4,
    );

    $self->type('зелёные глаза');
    $self->short_type('глаза');
    $self->hidden_type($self->short_type);
    return $self;
}

sub shutting {
  my ( $self, $Player ) = @_;
  my $question = 'ни одного::0'; 
  my @vars = ('|один::1','|два::2','|три::3','|четыре::4');
  for(my $i=0 ; ($i < $Player->bullets && $i<4 ); $i++ ){ $question .= $vars[$i]; }
  return $self->manager->question($question);
}

sub helper { # Another action after Player->in(Cell)
  my ($self, $other ) = @_;
  $other = '' unless defined($other);
  my $hlp=<<_EOT_;
&nbsp;&nbsp;&nbsp;
Всего в лабиринте водится четыре страшных хищника, на уничтожение которых
требуется от одного до четырех выстрелов. Если выстрелить недостаточное
количество раз, вы получите укус. Если выпустить слишком много пуль, вы
изрешите его шкуру, и сделаете её непригодной для продажи.
<br>&nbsp;&nbsp;&nbsp;
Получение третьего по счету укуса означает верную смерть.
<br>&nbsp;&nbsp;&nbsp;
Ещё в лабиринте имеются чья-то корова и комната с зеркалом, которые тоже
выглядят точь-в-точь, как зеленые глаза в темноте.
_EOT_
  $self->manager->help($hlp);
  return 1;
}

1;

__END__
