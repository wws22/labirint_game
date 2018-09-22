package Labirint::Object::Cell::Hole;
# Subclass of Labirint::Object::Cell
# $Header: /var/lib/cvsd/root/game/lib/Labirint/Object/Cell/Hole.pm,v 1.5 2007/02/24 20:13:10 wws Exp $
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
		['O:manager', 'output', 'Вы побывали в дыре, вылетели из неё, и сейчас стоите прямо над ней!<br>Куда вы выйдете из дыры?<br>'],
		['TRUE'],
	],
	['O:manager', 'output', 'Вы попали в дыру.<br>И вылетели из неё в другом месте.<br>'],
	['O:other', 'x', 'O:self->exit_x' ],
	['O:other', 'y', 'O:self->exit_y' ],
	['O:manager', 'output', 'Куда вы пойдёте теперь?<br>'],
      ],
    );
    bless $self, $class;
    # Add attributes
    $self->new_attr(
	-name	 => 'exit_x',
	-type	 => 'int',
	-value	 => 0,
	-minimum => 0,
	-maximum => $self->lsize,
    );
    $self->new_attr(
	-name	 => 'exit_y',
	-type	 => 'int',
	-value	 => 0,
	-minimum => 0, # 1..5
	-maximum => $self->lsize,
    );
    $self->new_attr(
	-name	 => 'hole_number',
	-type	 => 'int',
	-value	 => 0,
	-on_change => ['O:self', 'hidden_type', 'O:self->short_type().A:new'],
    );
    $self->type('дыра');
    $self->short_type('<font size=+1>O</font>');
    $self->hidden_type($self->short_type);
    $self->umap_type($self->short_type);
    return $self;
}

sub helper { # Another action after Player->in(Cell)
  my ($self, $other ) = @_;
  $other = '' unless defined($other);
  my $hlp=<<_EOT_;
&nbsp;&nbsp;&nbsp;
Всего в лабиринте имеется восемь дыр. Попав в первую дыру, вы
оказываетесь во второй. Чтобы попасть в третью, необходимо сперва выйти
из второй дыры, а затем, вновь войти в неё. Третья дыра ведет к четвертой и т.д.
<br>&nbsp;&nbsp;&nbsp;
Восьмая дыра приведет вас обратно к первой.
<br>&nbsp;&nbsp;&nbsp;
Почти все прочие клеточки в лабиринте, представлены в единственном экземпляре.
_EOT_
  $self->manager->help($hlp);
  return 1;
}

1;

__END__
