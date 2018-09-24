package Labirint::Object::Player;
# Subclass of Labirint::Object
# $Header: /var/lib/cvsd/root/game/lib/Labirint/Object/Player.pm,v 1.12 2007/02/28 10:35:22 wws Exp $
#

use strict;
use Engine::Debuger;

use Labirint::Object;
use vars qw(@ISA);
@ISA = qw(Labirint::Object);
use warnings;

use constant LSIZE => 5; # Labirint square size

sub new {
    # Create object
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $e_params; # my specific params
    ($e_params, @_) = $proto->_init( @_ );
    my $self = $class->SUPER::new( @_ ,
      #**************************************************************************
      #* go( dx=>+-1 dy=>+-1 ) # Step to another cell 
      # O:other - current location
      #**************************************************************************
      -on_go => [
	['O:self', 'is', 'can_go' ],
	FAIL => [
		['O:manager', 'output', 'Вы не можете пока никуда пойти!<br>' ],
		['O:self', 'in_location', 1 ],
	],
	# Check walls
	['O:other', 'is_not', 'A:eng_dir' ],
	FAIL => ['O:manager', 'output', '"Попытались пойти ".A:dir.", а там cтенка."' ],
	['O:manager', 'output', '"Идем ".A:dir.". "' ],
	# Change position
	['O:self', 'mod_x', 'A:dx' ],
	['O:self', 'mod_y', 'A:dy' ],
	['O:self', 'is_not', 'debug' ],
	FAIL => [ 'TRUE' ], # Wallchecker mode
	# And new_cell actions here
	['O:self', 'in_location', 0, 'A:eng_dir' ],
      ],
    ); 
    $self->{$_} = $e_params->{$_} foreach (keys %{$e_params} );
    bless $self, $class;
    $self->type('Игрок'); 

    # Add attributes
    $self->new_attr(
	-name	=> 'x',
	-type	=> 'int',
	-value	=> defined($self->{x}) ? $self->{x} : int(rand(LSIZE))+1 , # 1..5
	-minimum => 1,
	-maximum => LSIZE,
    );
    $self->new_attr(
	-name	=> 'y',
	-type	=> 'int',
	-value	=> defined($self->{y}) ? $self->{y} : int(rand(LSIZE))+1 , # 1..5
	-minimum => 1,
	-maximum => LSIZE,
    );
    $self->new_attr( # What says player?
	-name	=> 'answer',
	-type	=> 'string',
	-value  => ''
    );
    $self->new_attr(
	-name	=> 'bullets',
	-type	=> 'int',
	-value	=> 7,
    );
    $self->new_attr(
	-name	=> 'wet_bullets',
	-type	=> 'int',
	-value	=> 0,
    );

    $self->new_attr(
	-name	=> 'bites',
	-type	=> 'int',
	-value	=> 0,
	-minimum => 0,
	-maximum => 3,
	-on_maximum => [
	  ['O:self', 'clear', 'can_go' ],
	  ['O:manager', 'output', '<br>Это был фатальный укус! Вы не выжили и погибли в лабиринте.' ],
	  ['O:self', 'set', 'show_full_map'],
	  ['O:self', 'clear', 'alive' ],
	],
    );
    $self->new_attr(
	-name	=> 'money',
	-type	=> 'int',
	-value	=> 5,
	-minimum => 0,
	-on_change => [
	  ['O:self', 'if', 'A:new >= A:old' ],
	  FAIL => [
		['O:self', 'set', 'money_lost'],
		'TRUE',
	  ],
	],
    );
    $self->new_flag( -name => 'money_lost', -value => 0 ); # Деньги теряли?

    $self->new_attr( # Количество сделанных ходов
	-name	=> 'steps',
	-type	=> 'int',
	-value	=> 0,
    );
    $self->mod_attr(
	-name => 'steps',
	-modify => 1,
	-incremental => 1,
	-persist_as => "spell:going",
    );
    $self->new_flag( -name => 'begin_game', -value => 1 ); # Только начали играть?

    $self->new_flag( -name => 'can_go', -value => 1 ); # Мы можем идти дальше?
    $self->new_flag( -name => 'skins',  -value => 0 ); # Есть хоть одна шкура?
    $self->new_flag( -name => 'dry',    -value => 1,   # Есть хоть одна сухая шмотка?
	-on_clear => ['O:self', 'things_dry', '0' ],   # Мочим шмотки
    );
    $self->new_flag( -name => 'puddles', -value => 0,  # Лужу [опять] посещали?
	-on_clear => ['O:self', 'things_dry', '1' ],   # Сушим шмотки
    );
    $self->new_flag( -name => 'alive',	-value => 1 ); # Player is alive?
    $self->new_flag( -name => 'you_win',-value => 0 ); # You win?
    $self->new_flag( -name => 'have_key',-value => 0); # Нашли ключ от выхода?
    $self->new_flag( -name => 'treasure',-value => 0); # Клад при нас?
    $self->new_flag( -name => 'lipa',	-value => 0 ); # Ложный клад при нас?
    $self->new_flag( -name => 'oups',	-value => 0 ); # Второй раз попали в клад?
                                                       # (или выходили на свет)
    $self->new_flag( -name => 'surrender', -value => 0 ); # Он сдался и подсмотрел карту.

    $self->new_flag( -name => 'show_full_map',	-value => 0 );
    $self->new_flag(
	-name => 'debug', 
	-value => 0,
	-on_set => ['O:self', 'set', 'can_go' ], 
    );
    $self->set('container');

    # User map attrs
    $self->new_attr( # Player's track
	-name	=> 'track',
	-type	=> 'string',
	-value	=> '',
    );
    $self->new_flag( -name => 'known_location', -value => 0 );
    $self->new_attr( -name => 'max_px', -type => 'int', -value => 2*LSIZE+(LSIZE-1) );
    $self->new_attr( -name => 'p_x', -type => 'int', -value => 0 );
    $self->new_attr( -name => 'p_y', -type => 'int', -value => 0 );

    return $self;
}

#******************************************************************************
#* initialize - specific parameters
#******************************************************************************
sub _init {
  my $self = shift;
  my %own;
  # if it looks like a hash
  if ( @_ && (scalar( @_ ) % 2 == 0) )
  {
      # ... like a hash ...
      my %hashargs = @_;
      foreach (keys %hashargs){
        unless( /\A\-/ ){ # All Games::Object params started with '-'
	  $own{$_} = $hashargs{$_};
	  delete($hashargs{$_});
        }
      }
      return ( \%own, %hashargs );
  }
  return ( \%own, @_ );
}

sub step {
  my ($self,$to) = @_;
  return unless defined($to);
  my ($dx, $dy, $dir);
  if($to eq 'up'){
	$dx = 0;	$dy = 1;	$dir = 'наверх';
  }elsif($to eq 'down'){
	$dx = 0;	$dy = -1;	$dir = 'вниз';
  }elsif($to eq 'left'){
	$dx = -1;	$dy = 0 ;	$dir = 'налево';
  }elsif($to eq 'right'){
	$dx = +1;	$dy = 0 ;	$dir = 'направо';
  }else{
	return 0;
  }
  my $Cell = $self->manager->find("Cell_".$self->x."_".$self->y);
  my $result = $self->on_go(
	$Cell, { dx => $dx, dy => $dy, dir => $dir, eng_dir => $to }
  );
  unless($self->is('debug')){
    unless($result || $self->is_not('can_go') ){
      $Cell->set('p_'.$to); # Set player's wall
      info "In $Cell set wall '$to'";
      unless( $Cell->is('known_location') ) {
	if($to eq 'up'){
	  $Cell->p_m_up($Cell->p_m_up.':'.$Cell->p_x.'_'.$Cell->p_y.':');
	}elsif($to eq 'down'){
	  $Cell->p_m_down($Cell->p_m_down.':'.$Cell->p_x.'_'.$Cell->p_y.':');
	}elsif($to eq 'left'){
	  $Cell->p_m_left($Cell->p_m_left.':'.$Cell->p_x.'_'.$Cell->p_y.':');
	}elsif($to eq 'right'){
	  $Cell->p_m_right($Cell->p_m_right.':'.$Cell->p_x.'_'.$Cell->p_y.':');
	}
      }
    }
  }
  return $result;
}

sub in_location { # Init game for player in location
  my $self = shift;
  my $safe = shift || 0; # It's really new location... Or after logout/begin?
  my $dir = shift;
  $dir = 'hole' unless defined($dir);

  my $World = $self->manager() || return 0;
  my $Cell = $World->find('Cell_'.$self->x.'_'.$self->y);
  $self->begin_game() if $self->is('begin_game');
  info "Begin in_location $Cell";
  my $result = $self->in($Cell, { safe => $safe } ); # Cell actions

  # User map knowledgebase
  unless($safe){
    # Really new location
    my ($tmp,$x2,$y2) = split(/\_/, $Cell);
    my ($x1,$y1);
    $self->track($self->track.':'.$Cell);
    info "Track = ".$self->track."\n$Cell x2=$x2, y2=$y2";
    my @backtrack = split(/\:/, $self->track);
    my $FirstCell = $World->find($backtrack[0]);
    if(
	( $Cell->is('known_from_'.$dir) || $self->is('known_location') ) &&	
	( $Cell->p_x && $Cell->p_y )
    ){
        info "It is known_location";
	my $C;
	for(my $i=$#backtrack-1; $i>=0; $i--){
	  ($tmp,$x1,$y1) = split(/\_/, $backtrack[$i]);
	  $C = $World->find($backtrack[$i]);
	  if($i){ # Last cell in track is special
            info "Processing $C p_x = Cell->p_x - (x2-x1) = ".($Cell->p_x)." - (".($x2)."-".($x1).") = ".($Cell->p_x - ($x2-$x1));
	    $C->p_x( $Cell->p_x - ($x2-$x1) );
	    $C->p_y( $Cell->p_y - ($y2-$y1) );
	    $C->multi_loc( ($C->p_x).'_'.($C->p_y) );
	    $C->p_m_up( $C->is('p_up') ? ':'.($C->p_x).'_'.($C->p_y).':' : '' );
	    $C->p_m_down( $C->is('p_down') ? ':'.($C->p_x).'_'.($C->p_y).':' : '' );
	    $C->p_m_left( $C->is('p_left') ? ':'.($C->p_x).'_'.($C->p_y).':' : '' );
	    $C->p_m_right( $C->is('p_right') ? ':'.($C->p_x).'_'.($C->p_y).':' : '' );
	  }
	}
	# Last cell
	my $abs_x = $C->p_x;
	my $abs_y = $C->p_y;
	for(my $x=1;$x<=LSIZE;$x++){
	  for(my $y=1;$y<=LSIZE;$y++){
	    $C = $World->find("Cell_$x\_$y");
	    if( $C->p_x && $C->p_y &&
	  	abs($abs_x - $C->p_x) <= LSIZE &&
	  	abs($abs_y - $C->p_y) <= LSIZE
	    ){
		$C->p_x( $Cell->p_x - ($x2 - $C->x) );
		$C->p_y( $Cell->p_y - ($y2 - $C->y) );
		$C->multi_loc( ($C->p_x).'_'.($C->p_y) );
		$C->p_m_up( $C->is('p_up') ? ':'.($C->p_x).'_'.($C->p_y).':' : '' );
		$C->p_m_down( $C->is('p_down') ? ':'.($C->p_x).'_'.($C->p_y).':' : '' );
		$C->p_m_left( $C->is('p_left') ? ':'.($C->p_x).'_'.($C->p_y).':' : '' );
		$C->p_m_right( $C->is('p_right') ? ':'.($C->p_x).'_'.($C->p_y).':' : '' );
	    }
	  }
	}
	$self->track($Cell.'');
    }else{
	info "unknown_location $Cell p_x=".($Cell->p_x)." p_y=".($Cell->p_y)."   First Cell in track=$FirstCell";
	unless( $Cell->p_x && $Cell->p_y ) {
	  $Cell->p_x( $FirstCell->p_x + ( $x2 - $FirstCell->x ) );
	  $Cell->p_y( $FirstCell->p_y + ( $y2 - $FirstCell->y ) );
	  $Cell->multi_loc( ($Cell->p_x).'_'.($Cell->p_y) );
	}else{
	  my $x3 = $FirstCell->p_x + ( $x2 - $FirstCell->x );
	  my $y3 = $FirstCell->p_y + ( $y2 - $FirstCell->y );
	  $Cell->p_x( $x3 );
	  $Cell->p_y( $y3 );
	  my $m3 = $Cell->multi_loc;
	  unless( $m3 =~ /$x3\_$y3/ ){
	    $Cell->multi_loc( $m3.':'."$x3\_$y3" );
	    info "Add $Cell multi location:".$Cell->multi_loc();
	  }
	}
    }
    if($Cell->class =~ /::Cell::Hole\Z/){
	  # Find more info about hole
	  info "Oups it's Hole! Entrance at $Cell";
	  my $Hole = $World->find('Cell_'.$self->x.'_'.$self->y);
	  my $Near;
	  if( $Hole->is_not('known_from_'.$dir) && $Hole->is('known_from_up') ){
		$Near = $World->find( 'Cell_'.($Cell->x).'_'.($Cell->y - 1) );
		if(defined($Near)){
			$Hole->set('known_from_'.$dir) if( 
				$Near->p_x == $Cell->p_x &&	
				$Near->p_y == $Cell->p_y - 1 );
		}
	  }
	  if( $Hole->is_not('known_from_'.$dir) && $Hole->is('known_from_down') ){
		$Near = $World->find( 'Cell_'.($Cell->x).'_'.($Cell->y + 1) );
		if(defined($Near)){
			$Hole->set('known_from_'.$dir) if( 
				$Near->p_x == $Cell->p_x &&	
				$Near->p_y == $Cell->p_y + 1 );
		}
	  }
	  if( $Hole->is_not('known_from_'.$dir) && $Hole->is('known_from_right') ){
		$Near = $World->find( 'Cell_'.($Cell->x - 1).'_'.($Cell->y) );
		if(defined($Near)){
			$Hole->set('known_from_'.$dir) if( 
				$Near->p_x == $Cell->p_x - 1 &&	
				$Near->p_y == $Cell->p_y );
		}
	  }
	  if( $Hole->is_not('known_from_'.$dir) && $Hole->is('known_from_left') ){
		$Near = $World->find( 'Cell_'.($Cell->x + 1).'_'.($Cell->y) );
		if(defined($Near)){
			$Hole->set('known_from_'.$dir) if( 
				$Near->p_x == $Cell->p_x + 1 &&	
				$Near->p_y == $Cell->p_y );
		}
	  }
	  # Hole check
	  $Cell = $Hole;
	  $self->track($Cell.'');
	  unless( $Cell->is('known_from_'.$dir) ) {
	    unless( $Cell->p_x && $Cell->p_y ){
	      $Cell->p_x( $self->max_px ); 
	      $Cell->p_y( LSIZE );
	      $Cell->multi_loc( ($Cell->p_x).'_'.($Cell->p_y) );
	    }else{
	      $Cell->p_x( $self->max_px ); 
	      $Cell->p_y( LSIZE );
	      $Cell->multi_loc( $Cell->multi_loc().':'.($self->max_px).'_'.( LSIZE ) );
	      info "Add Hole $Cell multi location:".$Cell->multi_loc();
	    }
	  }
    }
    $Cell->set('known_from_'.$dir);
    $self->mod_max_px( LSIZE+1 ) if $Cell->p_x >= $self->max_px;
    $self->p_x($Cell->p_x);
    $self->p_y($Cell->p_y);
  }
  return $result;
}

sub things_dry {
  my $self = shift;
  my $flag = shift; # 1: Сушим шмотки / 0: Мочим шмотки 
  if($flag){
	$self->mod_bullets($self->wet_bullets);
	$self->wet_bullets(0);
  }else{
	$self->mod_wet_bullets($self->bullets);
	$self->bullets(0);
  }
  my @contain = @{$self->related('contain')};
  foreach my $C (@contain){
    my $Cell = $self->manager->find($C);
    if($flag){
	$Cell->set('dry');
    }else{
	$Cell->clear('dry');
    }
  }
}

sub begin_game {
  my $self = shift;
  my $World = $self->manager() || return 0;
  $self->track("Cell_".$self->x."_".$self->y);
  my $Cell = $World->find("Cell_".$self->x."_".$self->y);
  $Cell->p_x(LSIZE); $Cell->p_y(LSIZE);
  $Cell->multi_loc( ($Cell->p_x).'_'.($Cell->p_y) );

  $World->help("<font color='red'>Внимание!!! Показ плана лабиринта ведет к автоматическому проигрышу!</font><hr>");
  $World->output(
	'&nbsp;&nbsp;Итак, вы попали в лабиринт.'.'<br>'.
	'&nbsp;&nbsp;Ваша задача найти сокровища и выйти живым из лабиринта. <br>&nbsp;&nbsp;Вы взяли с собой пять монет, которых вы вполне можете и лишиться. Но, в случае успеха, сокровища с лихвой покроют ваши затраты. <br>&nbsp;&nbsp;Итак, вы не знаете в какое место вы попали. Можем лишь сообщить, что лабиринт имеет размер 5 на 5 клеток. Подсказки будут появляться в ходе игры. Итак, начнем...<br>&nbsp;&nbsp;'
  );
}

1;

__END__
