#!/usr/local/bin/perl
#
# $Header: /var/lib/cvsd/root/game/web/cgi/labirint.cgi,v 1.14 2007/02/28 10:35:22 wws Exp $
#
# docker run -p8888:5000 -it --rm --name labirint -v "$PWD":/usr/src/labirint -w /usr/src/labirint wws22/labirint perl ./web/cgi/labirint.cgi
#
use strict;
use warnings;
use FindBin;
use lib '/usr/src/labirint/lib';
use Labirint::Object;
use Labirint::Object::User;
use Labirint::Object::Player;
use Labirint::Object::Cell;
use Labirint::Object::Cell::Hole;
use Labirint::Object::Cell::Puddle;
use Labirint::Object::Cell::Arsenal;
use Labirint::Object::Cell::Dry;
use Labirint::Object::Cell::Animal;
use Labirint::Object::Cell::Shop;
use Labirint::Object::Cell::Hospital;
use Labirint::Object::Cell::Key;
use Labirint::Object::Cell::Exit;
use Labirint::Object::Cell::Treasure;
use Labirint::Object::Cell::Lipa;
use Labirint::Object::Cell::Band;

use Labirint::World;
$Games::Object::AccessorMethod = 1;
$Games::Object::ActionMethod = 1;

use Engine; Engine::Run( #no_login => 1,
	#show_full_map => 1,
	header=>{
		-expires => 'now',
		-charset => 'utf-8'
	} 
);
#******************************************************************************
use constant MAX_WALLS => 10;		# Maximum for internal walls (max=20)
use constant USER_OBJ_PREFIX => 'User_';# Real World object prefix
use constant LSIZE => 5;		# Labirint square size
use constant SAVED => "labirint.save"; # Filename for saved file with RealWorld

sub main {
  my $self = shift;
  my $rcount = $self->engine->count();
  my $p; # Template params

  # Prepare RealWorld
  my $RealWorld;
  if($self->real_world){
    trace 'Use existing RealWorld';
    $RealWorld = $self->real_world;
  }else{
    if( -e SAVED ){
        trace 'Load RealWorld from file';
        $RealWorld = Labirint::World->load(SAVED);
    }
    unless($RealWorld){
        trace 'Create new RealWorld';
        $RealWorld = new Labirint::World();
    }
    $self->real_world($RealWorld);
  }

  my $user_id = USER_OBJ_PREFIX;
  $user_id .= $self->cookie('login') if defined($self->cookie('login'));

  my $user_key = $self->cookie('user_key');
  $user_key = '' unless defined($self->cookie('user_key'));

  my $User = $RealWorld->find($user_id);

  unless( defined($self->parent('no_login')) && $self->parent('no_login') ){
    return $self->do_login() unless(defined($User) && $User->check_key($user_key));
  }
  # Prepare Game World
  $self->{user_id} = $user_id; # Store user_id
  my $World;
  my $use_existing_world = 1;
  if($self->world){
    trace 'Use existing World';
    $World = $self->world;
    $World->request($self); # Init for make output is possible
  }else{
    trace 'Create new World';
    $World = $self->build_labirint();
    $use_existing_world = 0;
  }

  my $Player = $World->find('Player');
  $Player->clear('known_location');
  my $action = substr($self->fullname,length($self->name));
  if($action ne ''){
    $action = substr($action,1);
    if ($action eq 'logout'){
	return $self->do_logout();
    }elsif($action eq 'abort'){
	return $self->do_abort();
    }elsif($action =~ /\Ago_(\w+)/){

	$World->process();
	$Player->step($1);

    }elsif($action eq 'answer'){
	my $answer = $self->param('answer');
	$answer = '0' unless defined($answer);
	$Player->answer($answer);
	$Player->in_location(1);
    }elsif($action eq 'switch_map'){
	if($Player->is('show_full_map')){
		$Player->clear('show_full_map');
	}else{
		$Player->set('show_full_map');
		$Player->set('surrender');
	}
    }else{
    }
  }else{
	$Player->in_location($use_existing_world);
  }
  $Player->answer(''); # Drop player answer

  #$self->cout('Position: x='.$Player->x, ' y='.$Player->y.'<br>' );
  #$self->cout('<br>==================================================<br>');
  $p->{MAP} = $self->show_labirint();
  $p->{NAVY} = $self->navygation;
  $p->{USERMAP} = $self->usermap();
  $p->{LINES} = $self->{lines} if( $self->{lines} );
  #$p->{DUMP} = $self->dumpWorld;

  $Player->clear('begin_game');
  my $template = $self->template($self->name.'/main.tmpl',$p);
  $self->print( $template->output() ) if defined($template);

  # die "А потому, что нефиг!<br>";
  # Some cleanup
  $self->world->request(0);
}

sub real_world {
  my $self = shift;
  my $set = shift;
  return $self->engine->{RealWorld} if !defined($set);
  $self->engine->{RealWorld} = $set;
}

sub world {
  my $self = shift;
  my $set = shift;
  return $self->engine->{Worlds}->{$self->{user_id}} if !defined($set);
  $self->engine->{Worlds}->{$self->{user_id}} = $set;
}

sub dumpWorld {
  my $self = shift;
  $self->world->request(0);
  return Dumper($self->world);
}

sub cout {
  my $self = shift;
  return unless( @_ );
  push @{$self->{lines}}, { line => join( '', @_ ) };
  return 1;
}

sub help {
  my $self = shift;
  return unless( @_ );
  push @{$self->{help}}, { line => join( '', @_ ) };
  return 1;
}

sub dumper { # If defined - used when ERROR or $self->fail(...) called
             # When not defined $self dumped to app_log only
  my $self = shift;
  return $self.''; # For object name only to app_log and STDOUT
  # return $self; # For object Dumper to app_log only
  # return Dumper($self); # For object Dumper to app_log and STDOUT
}

sub cleanup { # If defined - used for cleanup when ERROR 
              # or $self->fail(...) called
  my $self = shift;
  if( defined($self->{user_id}) && defined($self->world) ){
    trace 'Destroying broken World';
    $self->world->destroy();
    delete($self->engine->{Worlds}->{$self->{user_id}});
  }
  trace 'cleanup() - done';
}

sub do_login {
  my $self = shift;
  my $RealWorld = $self->real_world;
  my $p; # Params for template

  $p->{login} = $self->param('login');
  $p->{login} = $self->cookie('login') unless defined($p->{login});
  $p->{login} = '' unless defined($p->{login});

  my $password = $self->param('password');
  if( defined($password) ){
    my $User; 
    $User = $RealWorld->find(USER_OBJ_PREFIX.$p->{login}) if defined($p->{login});
    if( defined($self->param('enter.x')) && $self->param('enter.x') > 70 ){
    # Registration
      if( defined($User) ){ # User already exists
	$p->{userexists} = 1;
      }else{ # Register user
	$User = new Labirint::Object::User( -id => USER_OBJ_PREFIX.$p->{login} );
	$User->login($p->{login});
	$User->password($password);
	$RealWorld->add($User);
          $RealWorld->save(SAVED);
      }
    }
    # Login
    if( defined($User) ){
        my $new_key = $User->generate_key($password);
	if( $User->check_key($new_key) ){
	  $self->cookie( 'login', $p->{login} );
	  $self->cookie( 'user_key', $new_key );
	  $self->redirect($self->script);
	  return;
	}
    }
  }
  $p->{script} = $self->script;
  my $template = $self->template($self->name.'/login.tmpl',$p);
  $self->print( $template->output() ) if defined($template);
}

sub do_logout {
  my $self = shift;
  my $Player = $self->world->find('Player');
  $self->world->request(0);
  unless($Player->is('alive')){
      trace 'User exited! Destroying World...';
      $self->world->destroy();
      delete($self->engine->{Worlds}->{$self->{user_id}});
  }
  $self->cookie( 'user_key', '' );
  return $self->redirect($self->script);
}

sub do_abort {
  my $self = shift;
  if( defined($self->{user_id}) && defined($self->world) ){
      trace 'User aborted! Destroying World...';
      $self->world->destroy();
      $self->world->request(0);
      delete($self->engine->{Worlds}->{$self->{user_id}});
  }
  return $self->redirect($self->script);
}

sub navygation {
  my $self = shift;
  my $Player = $self->world->find('Player');
  my $p; # Params for template
  $p->{script} = $self->script;
  $p->{can_go} = $Player->is('can_go');
  $p->{steps}  = $Player->steps;
  $p->{is_alive}  = $Player->is('alive');
  $p->{bullets} = $Player->bullets;
  $p->{wet_bullets} = $Player->wet_bullets;
  $p->{wbpraz} = ($Player->wet_bullets < 2) ? 'сырой' : 'сырые' ;
  $p->{all_bullets} = $Player->bullets + $Player->wet_bullets;
  $p->{all_bullets_is_wet} = ($p->{wet_bullets} == $p->{all_bullets});
  $p->{all_bwpraz} = $p->{all_bullets} < 2 ? 'он сырой' : 'они сырые' ;
  $p->{bites} = $Player->bites;
  $p->{money} = $Player->money;
  $p->{mpraz} = (
    ($Player->money < 20) ?
      (
	($Player->money < 2) ? 'а' : 
	(
		($Player->money < 5) ? 'ы' : ''
	)
      ) : (
	(($Player->money % 10) < 2) ? 'а' : 
	(
		(($Player->money %10) < 5) ? 'ы' : ''
	)
      )
  );
  if($Player->is('have_key')){
    push @{$p->{goods}}, { status  => 0, value   => 'ключ' };
  }
  if($Player->is('lipa') || $Player->is('treasure')){
    if(
	($Player->is('lipa') ? 1 : 0 ) + ($Player->is('treasure') ? 1 : 0 ) > 1
    ){
	push @{$p->{goods}}, { status  => 0, value   => 'два сундука' };
    }else{
	push @{$p->{goods}}, { status  => 0, value   => 'сундук с кладом' };
    }
  }

  my @contain = @{$Player->related('contain')};
  foreach my $C (@contain){
    my $Cell = $self->world->find($C);
    push @{$p->{goods}}, {
	status  => ($Cell->is('dry') ? 0 : 1),
	value   => 'шкура '.$Cell->animal_name(),
    };
  }

  my $template = $self->template($self->name.'/navy.tmpl',$p);
  return $template->output() if defined($template);
  return '';
}

sub show_labirint {
  my $self = shift;
  my $p; # Template params
  my $Player = $self->world->find('Player');
  my ( $cx, $cy ) = ( $Player->x , $Player->y );
  my $cell_size = 44;   # pixels
  $p->{help_height}  =  300; # map tr in pixels for helper
  $p->{total_width} = LSIZE * ($cell_size+2) + 2;
  $p->{cell_size} = $cell_size;
  my $mark_wall = " bgcolor='black'";
  $p->{ext_wall_color} = " bgcolor='black'"; # Externall walls
  $p->{cross_color} = " bgcolor='grey'"; # Crosspoint color
  $p->{script} = $self->script;
  $p->{maxcol} = LSIZE * 3 + 2;
  $p->{can_go} = $Player->is('can_go');
  $p->{help} = $self->{help} if( $self->{help} );
  $p->{show_map} = defined($self->parent('show_full_map')) && $self->parent('show_full_map');
  if( $Player->is_not('alive') || $Player->is('surrender') ) {
	$p->{show_map} = $Player->is('show_full_map') ? 1 : 0 ;
  }

  for(my $y=LSIZE;$y>=1;$y--){
    # Top walls
    my @twalls; 
    for(my $x=1;$x<=LSIZE;$x++){
	my $Cell = $self->world->find("Cell_$x\_$y");
	push @twalls, {
		tdprop  => ($Cell->is('up') ? $mark_wall : '')
	};
    }
    push @{$p->{rows}}, { twalls => \@twalls };
    # Cells
    my @cells;
    for(my $x=1;$x<=LSIZE;$x++){
	my $Cell = $self->world->find("Cell_$x\_$y");
	# Left wall
	push @cells, {
		tdprop  => ($Cell->is('left') ? $mark_wall : '')." width='1'",
	};
	# Cell
	push @cells, {
		# Mark player location
		tdprop  => " bgcolor='".(($cx==$x && $cy==$y) ? 'lightgreen' : '#ffffff')."' width='".$cell_size."' class='map'",
		# Cell name
		cell 	=> $Cell->hidden_type, #.' '.$Cell->zone, # Debug
	};
	# Right wall
	push @cells, {
		tdprop  => ($Cell->is('right') ? $mark_wall : '')." width='1'",
	};
    }
    push @{$p->{rows}}, { cells => \@cells };

    # Bottom walls
    my @bwalls;
    for(my $x=1;$x<=LSIZE;$x++){
	my $Cell = $self->world->find("Cell_$x\_$y");
	# Bottom wall
	push @bwalls, {
		tdprop  => ($Cell->is('down') ? $mark_wall : '')
	};
    }
    push @{$p->{rows}}, { bwalls => \@bwalls };
  }
  my $template = $self->template($self->name.'/map.tmpl',$p);
  return $template->output() if defined($template);
  return '';
}

#******************************************************************************
#* replace_cell( Old_Cell, New_Cell )
#******************************************************************************
sub replace_cell{
  my ($self, $Cell, $NewCell) = @_;
	# Copy walls info
	my ( $up,$down,$left,$right ) = ( $Cell->is('up'), $Cell->is('down'), $Cell->is('left'), $Cell->is('right') );
	# Copy zone info
	my $zone = $Cell->zone;
	# Copy ID
	my $id = $Cell.'';
	# Change
	$self->world->destroy($Cell);
	$NewCell->id($id);	
	$self->world->add($NewCell);
	$NewCell->set('up')	if $up;
	$NewCell->set('down')	if $down;
	$NewCell->set('left')	if $left;
	$NewCell->set('right')	if $right;
	$NewCell->zone($zone);
  return $NewCell;
}

sub build_labirint {
  my $self = shift;
  info "build_labirint started";
  my $World = new Labirint::World( request => $self );
  $self->world($World);
  for(my $x=1;$x<=LSIZE;$x++){
    for(my $y=1;$y<=LSIZE;$y++){
	$World->add(new Labirint::Object::Cell(-id=>"Cell_$x\_$y"));
    }
  }

  # Place walls
  my $max_walls = (MAX_WALLS < 20) ? MAX_WALLS : 20 ;
  my $walls = int($max_walls*0.4) + int(rand($max_walls*0.55)) + 1; # Walls be placed
  info "Trying to place '".$walls."' walls";
  my @dir = ('up','right','down','left');
  my $max_cycles = 50;
  while($walls && --$max_cycles>0 ){
    my $x = int(rand(LSIZE)+1);
    my $y = int(rand(LSIZE)+1);
    my $to = $dir[int(rand(4))];
    my $Cell = $World->find("Cell_$x\_$y");
    next if $Cell->is($to); 		# Already placed
    # my $before=$Cell->walls_placed; # Debug
    $Cell->set($to);
    # trace "Try Cell_$x\_$y\_$to before=$before after=".$Cell->walls_placed."\t".($Cell->is($to) ? 'PLACED' : 'FAILED'); # Debug
    next unless $Cell->is($to);		# Failed
    $walls--;
  }
  my $Player = new Labirint::Object::Player( -id=>'Player', 'x'=>1, 'y'=>1 );
  $World->add($Player);
  $Player->set('debug'); # Use player as wallchecker

  # Check perimeters
  info "Check perimetr started";
  $World->quiet(1); # Stop messages from manager
  my @cells;
  my $zone = 0;
  {
    my $Cell;
    my @shfts = ( 3, 0, 1, 2 );
    my $marked = 0;
    while( $marked < LSIZE * LSIZE ){
      $zone++;
      # Choice first cell
      my $found = 0;
      for(my $x=1;$x<=LSIZE;$x++){
	for(my $y=1;$y<=LSIZE;$y++){
	  $Player->x($x);
	  $Player->y($y);
	  $Cell = $World->find('Cell_'.$Player->x.'_'.$Player->y);
	  unless($Cell->zone){
		$found = 1;
	  }
	  last if $found;
	}
	last if $found;
      }
      my $go = 'never';
      my $turn = 1;
      my @dir = ( 'down', 'left', 'up', 'right'  );
      while( ! grep( $go.'_'.$Player->x.'_'.$Player->y.'_'.$zone eq $_, @cells  )){
	for(my $i=0;$i<$shfts[$turn];$i++){ push @dir, shift(@dir); }

	$Cell = $World->find('Cell_'.$Player->x.'_'.$Player->y);
	if( $Cell->zone() < $zone ){
	  if($Cell->zone()){ # If not null
	    # Oups it's already visited zone
	    my $exit = 1;
	    do{
	      my ($x,$y,$zn); 
	      ($_,$x,$y,$zn)= split(/\_/, pop(@cells));
	      my $C = $World->find('Cell_'.$x.'_'.$y);
	      #trace("$C  $zn == $zone  Cell->zone()=".$Cell->zone);
	      if( $zn == $zone ){ 
		$C->zone($Cell->zone); 
	      }else{ 
		$exit = 0;
	      }
	    }while($exit);
	    $zone--;
	    info "Oups in ".$Player->x.'_'.$Player->y." decrease zone count to:".$zone;
	    last;
	  }
	  $Cell->zone($zone);    # Mark cell
	  $marked++;
	}
	push @cells, $go.'_'.$Player->x.'_'.$Player->y.'_'.$zone;
	$turn=0;
	$go = $dir[$turn];
	next if $Player->step($go);
	$go = $dir[++$turn];
	next if $Player->step($go);
	$go = $dir[++$turn];
	next if $Player->step($go);
	$go = $dir[++$turn];
	next if $Player->step($go);
      }
      unless($Cell->zone()){ #Mark last cell when Cell->zone()==0
	$Cell->zone($zone);
	$marked++;
      }
      push @cells, $go.'_'.$Player->x.'_'.$Player->y.'_'.$Cell->zone;
    }
    info "AllTrace[".($#cells+1)."]: ".join( ' ', @cells);
  }
  info "Check perimetr finished. Total zones=".$zone;

  # Place holes
  # $zone is minimal required holes
  my $hole_placed=0;
  my @places=();
  for(my $x=1;$x<=LSIZE;$x++){
    for(my $y=1;$y<=LSIZE;$y++){
	push @places, "$x\_$y";
    }
  }
  my @holes=();
  my $realy_placed = 0;
  while($hole_placed<=$zone && $#places >= 0){
    my $r = int(rand($#places+1));
    my $Cell = $World->find("Cell_".$places[$r]);
    if( $Cell->zone() == ($hole_placed+1) ){
	$Cell->zone(++$hole_placed);
	my $NewCell = new Labirint::Object::Cell::Hole( -id=>'Tmp'.$Cell);
	$Cell = $self->replace_cell( $Cell, $NewCell );
	push @holes, "Cell_".$places[$r];
	$realy_placed++;
=pod
################################# Workaround for infinity loop fix
        my $z = $hole_placed+1;
	while( ! grep( /_$z\Z/, @cells) && $hole_placed<$zone ){ 
	  # skip missed zone
	  trace ("#" x 50);
	  trace "Skip missed zone $z";
          $hole_placed++;
	  $z = $hole_placed+1;
	}
################################# End of Workaround
=cut
    }
    splice(@places,$r,1) if $Cell->zone()<=$hole_placed;
  }
  info "Minimum sets of Holes placed: ".$realy_placed."=>[ ".join(', ',@holes)." ]";

  @places = ();
  for(my $x=1;$x<=LSIZE;$x++){
    for(my $y=1;$y<=LSIZE;$y++){
      my $Cell = $World->find("Cell_$x\_$y");
      if( $Cell->class() ne 'Labirint::Object::Cell::Hole' ){
	push @places, "$x\_$y";
      }
    }
  }

  $hole_placed=$realy_placed;
  while($hole_placed<8 && $#places >= 0){
    my $r = int(rand($#places+1));
    my $Cell = $World->find("Cell_".$places[$r]);
    $Cell->zone(++$hole_placed);
    my $NewCell = new Labirint::Object::Cell::Hole( -id=>'Tmp'.$Cell);
    $Cell = $self->replace_cell( $Cell, $NewCell );
    push @holes, "Cell_".$places[$r];
    splice(@places,$r,1);
  }
  info "All Holes placed =>[ ".join(', ',@holes)." ]";

  # Make holes links
  my $first_hole = int(rand($#holes+1));
  my $FirstHole = $World->find($holes[$first_hole]);
  splice(@holes,$first_hole,1);
  my ($pfx, $exit_x, $exit_y) = split(/\_/,$FirstHole);
  my $hole_number=1;
  while($#holes>=0){
    my $r = int(rand($#holes+1));
    my $Hole = $World->find($holes[$r]);
    $Hole->exit_x($exit_x);
    $Hole->exit_y($exit_y);
    $exit_x=$Hole->x;
    $exit_y=$Hole->y;
    $Hole->hole_number(9-$hole_number++);
    splice(@holes,$r,1);
  }
  $FirstHole->exit_x($exit_x);
  $FirstHole->exit_y($exit_y);
  $FirstHole->hole_number(9-$hole_number++);
  info "All Holes linked";

  # Place puddle 
  if($#places >= 0){
    my $r = int(rand($#places+1));
    my $Cell = $World->find("Cell_".$places[$r]);
    my $NewCell = new Labirint::Object::Cell::Puddle( -id=>'Tmp'.$Cell);
    $Cell = $self->replace_cell( $Cell, $NewCell );
    splice(@places,$r,1);
  }

  # Place arsenal
  if($#places >= 0){
    my $r = int(rand($#places+1));
    my $Cell = $World->find("Cell_".$places[$r]);
    my $NewCell = new Labirint::Object::Cell::Arsenal( -id=>'Tmp'.$Cell);
    $Cell = $self->replace_cell( $Cell, $NewCell );
    splice(@places,$r,1);
  }

  # Place dry
  if($#places >= 0){
    my $r = int(rand($#places+1));
    my $Cell = $World->find("Cell_".$places[$r]);
    my $NewCell = new Labirint::Object::Cell::Dry( -id=>'Tmp'.$Cell);
    $Cell = $self->replace_cell( $Cell, $NewCell );
    splice(@places,$r,1);
  }

  # Place exit
  if($#places >= 0){
    my $r = int(rand($#places+1));
    my $Cell = $World->find("Cell_".$places[$r]);
    my $NewCell = new Labirint::Object::Cell::Exit( -id=>'Tmp'.$Cell);
    $Cell = $self->replace_cell( $Cell, $NewCell );
    splice(@places,$r,1);
  }

  # Place animals
  if($#places >= 0){
    my $r = int(rand($#places+1));
    my $Cell = $World->find("Cell_".$places[$r]);
    my $NewCell = new Labirint::Object::Cell::Animal( -id=>'Tmp'.$Cell);
    $Cell = $self->replace_cell( $Cell, $NewCell );
    splice(@places,$r,1);
    $Cell->set('mirror');
    $Cell->type('зеркало');
    $Cell->health(0);
    $Cell->animal_name('зеркала');
    $Cell->hidden_type('зер-<br>кало');
    $Cell->umap_type($Cell->short_type);
  }

  if($#places >= 0){
    my $r = int(rand($#places+1));
    my $Cell = $World->find("Cell_".$places[$r]);
    my $NewCell = new Labirint::Object::Cell::Animal( -id=>'Tmp'.$Cell);
    $Cell = $self->replace_cell( $Cell, $NewCell );
    splice(@places,$r,1);
    $Cell->type('корова');
    $Cell->health(0);
    $Cell->animal_name('коровы');
    $Cell->hidden_type('корова');
    $Cell->umap_type($Cell->short_type);
  }

  if($#places >= 0){
    my $r = int(rand($#places+1));
    my $Cell = $World->find("Cell_".$places[$r]);
    my $NewCell = new Labirint::Object::Cell::Animal( -id=>'Tmp'.$Cell);
    $Cell = $self->replace_cell( $Cell, $NewCell );
    splice(@places,$r,1);
    $Cell->type('бронтозавр');
    $Cell->health(1);
    $Cell->animal_name('бронтозавра');
    $Cell->hidden_type('бронто-<br>завр');
    $Cell->umap_type($Cell->short_type);
  }

  if($#places >= 0){
    my $r = int(rand($#places+1));
    my $Cell = $World->find("Cell_".$places[$r]);
    my $NewCell = new Labirint::Object::Cell::Animal( -id=>'Tmp'.$Cell);
    $Cell = $self->replace_cell( $Cell, $NewCell );
    splice(@places,$r,1);
    $Cell->type('звероящер');
    $Cell->health(2);
    $Cell->animal_name('звероящера');
    $Cell->hidden_type('зверо-<br>ящер');
    $Cell->umap_type($Cell->short_type);
  }
  if($#places >= 0){
    my $r = int(rand($#places+1));
    my $Cell = $World->find("Cell_".$places[$r]);
    my $NewCell = new Labirint::Object::Cell::Animal( -id=>'Tmp'.$Cell);
    $Cell = $self->replace_cell( $Cell, $NewCell );
    splice(@places,$r,1);
    $Cell->type('ихитизавр');
    $Cell->health(3);
    $Cell->animal_name('ихтиозавра');
    $Cell->hidden_type('ихтио-<br>завр');
    $Cell->umap_type($Cell->short_type);
  }
  if($#places >= 0){
    my $r = int(rand($#places+1));
    my $Cell = $World->find("Cell_".$places[$r]);
    my $NewCell = new Labirint::Object::Cell::Animal( -id=>'Tmp'.$Cell);
    $Cell = $self->replace_cell( $Cell, $NewCell );
    splice(@places,$r,1);
    $Cell->type('птеродактель');
    $Cell->health(4);
    $Cell->animal_name('птеродактеля');
    $Cell->hidden_type('птеро-<br>дакт.');
    $Cell->umap_type($Cell->short_type);
  }

  # Place treasure
  if($#places >= 0){
    my $r = int(rand($#places+1));
    my $Cell = $World->find("Cell_".$places[$r]);
    my $NewCell = new Labirint::Object::Cell::Treasure( -id=>'Tmp'.$Cell);
    $Cell = $self->replace_cell( $Cell, $NewCell );
    splice(@places,$r,1);
  }

  # Place shop
  if($#places >= 0){
    my $r = int(rand($#places+1));
    my $Cell = $World->find("Cell_".$places[$r]);
    my $NewCell = new Labirint::Object::Cell::Shop( -id=>'Tmp'.$Cell);
    $Cell = $self->replace_cell( $Cell, $NewCell );
    splice(@places,$r,1);
  }

  # Place band
  if($#places >= 0){
    my $r = int(rand($#places+1));
    my $Cell = $World->find("Cell_".$places[$r]);
    my $NewCell = new Labirint::Object::Cell::Band( -id=>'Tmp'.$Cell);
    $Cell = $self->replace_cell( $Cell, $NewCell );
    splice(@places,$r,1);
  }

  # Place key
  if($#places >= 0){
    my $r = int(rand($#places+1));
    my $Cell = $World->find("Cell_".$places[$r]);
    my $NewCell = new Labirint::Object::Cell::Key( -id=>'Tmp'.$Cell);
    $Cell = $self->replace_cell( $Cell, $NewCell );
    splice(@places,$r,1);
  }

  # Place hospital
  if($#places >= 0){
    my $r = int(rand($#places+1));
    my $Cell = $World->find("Cell_".$places[$r]);
    my $NewCell = new Labirint::Object::Cell::Hospital( -id=>'Tmp'.$Cell);
    $Cell = $self->replace_cell( $Cell, $NewCell );
    splice(@places,$r,1);
  }

  # Place failed treasure (Lipa)
  if($#places >= 0){
    my $r = int(rand($#places+1));
    my $Cell = $World->find("Cell_".$places[$r]);
    my $NewCell = new Labirint::Object::Cell::Lipa( -id=>'Tmp'.$Cell);
    $Cell = $self->replace_cell( $Cell, $NewCell );
    splice(@places,$r,1);
  }

  # Place another cells
  info "Available places => [ ".join(', ',@places)." ]";

  $Player->clear('debug'); # Stop using player as wallchecker
  my $class = '::Cell::Hole';
  while( $class =~ /::Cell::Hole\Z/ ){
	$Player->x(int(rand(LSIZE)+1));
	$Player->y(int(rand(LSIZE)+1));
	my $Cell = $World->find('Cell_'.$Player->x.'_'.$Player->y);
        $class = $Cell->class();
  }
  $World->quiet(0); # Start messages from manager
  info "Player at position: ".$Player->x.",".$Player->y;
  info "Build labirint finished.";
  return $World;
}

sub usermap {
  my $self = shift;
  my $p; # Template params
  my $Player = $self->world->find('Player');
  return '' if $Player->is('begin_game');
  my ( $p_x, $p_y ) = ( $Player->p_x , $Player->p_y );
  my $cell_size = 40;   # pixels
  $p->{cell_size} = $cell_size;
  my $mark_wall = " bgcolor='red'";
  $p->{cross_color} = " bgcolor='grey'"; # Crosspoint color
  $p->{script} = $self->script;
  my $max_x = 0;
  my $max_y = 0;
  my $min_x = $Player->max_px + LSIZE;
  my $min_y = 1;
  my $umap;
  

  for( my $y=1 ; $y <= LSIZE ; $y++ ){
    for( my $x=1 ; $x <= LSIZE ; $x++ ){
	my $Cell = $self->world->find("Cell_$x\_$y");
	if($Cell->p_x && $Cell->p_y){
	  $umap->{($Cell->p_x).''}->{($Cell->p_y).''} = $Cell.'';
	  my @m = split(/\:/, $Cell->multi_loc);
	  for( my $i=0; $i<=$#m; $i++ ){
	    my ($x1,$y1) = split(/_/, $m[$i] );
	    $umap->{$x1}->{$y1} = $Cell.'';
	    $max_x = $x1 if $x1 > $max_x;
	    $max_y = $y1 if $y1 > $max_y;
	    $min_x = $x1 if $x1 < $min_x;
	    $min_y = $y1 if $y1 < $min_y;
	  }
	}
    }
  }
  my $wrap = 4;
  $max_x += LSIZE;
  $max_y = 2 * LSIZE - 1;  # 2*LSIZE+(LSIZE-1)
  #$Player->max_px( LSIZE * (int($max_x/LSIZE)+1) );
  $Player->max_px( int($max_x/(LSIZE * 2))*(LSIZE * 2) + LSIZE  );
  info "in show: max_x=$max_x set Player->max_px = ".($Player->max_px)."  min_x=$min_x";

  $min_x = $min_x > (LSIZE * 2) ? int($min_x/(LSIZE*2))*(LSIZE * 2)+1 : 1 ;

  info "in show: set min_x = $min_x";
  #$p->{total_height}  =  ($max_y-$min_y+1) * ($cell_size+2); # list height
  #$p->{total_width}   =  ($max_x-$min_x+1) * ($cell_size+2);
  $p->{total_width}   =  ( LSIZE * $wrap ) * ($cell_size+2);

  for(my $t=$min_x ; $t <= $max_x ; $t += LSIZE * $wrap ){
   my @rows;
   for( my $y=$max_y ; $y >= $min_y ; $y-- ){
    # Top walls
    my @twalls; 
    for( my $x=$t ; $x < $t + LSIZE * $wrap ; $x++ ){
      my $tdprop='';
      if(defined($umap->{$x}->{$y})) {
	my $Cell = $self->world->find($umap->{$x}->{$y});
	if( $Cell->is('p_up') ){
	  if( $Cell->is('known_location') || $Cell->p_m_up() =~ /\:$x\_$y\:/ ){
		$tdprop = $mark_wall;
	  }
	}
      }
      push @twalls, { tdprop  => $tdprop };
    }
    push @rows, { twalls => \@twalls };

    # Cells
    my @cells;
    for( my $x=$t ; $x < $t + LSIZE * $wrap ; $x++ ){
      if(defined($umap->{$x}->{$y})) {
	my $Cell = $self->world->find($umap->{$x}->{$y});
	# Left wall
	push @cells, {
		tdprop	=> (
		  (
			( $Cell->is('p_left')) && 
			( $Cell->is('known_location') || ($Cell->p_m_left() =~ /\:$x\_$y\:/) )
		  )
		  ? $mark_wall : ''
		)." width='1'",
	};
	# Cell
	push @cells, {
		# Mark player location
		tdprop	=> " bgcolor='".(($p_x==$x && $p_y==$y) ? 'lightgreen' : '#ffffff')."' width='".$cell_size."' class='map'",
		# Cell name
		cell	=> $Cell->is('known_location') || $Player->is('known_location')
		? 
		$Cell->hidden_type :
		( ($p_x==$x && $p_y==$y && $Player->is_not('can_go')) ? $Cell->short_type : $Cell->umap_type ),
	};
	# Right wall
	push @cells, {
		tdprop	=> (
		  (
			( $Cell->is('p_right')) && 
			( $Cell->is('known_location') || ($Cell->p_m_right() =~ /\:$x\_$y\:/) )
		  )
		  ? $mark_wall : ''
		)." width='1'",
	};
      }else{
	# Left wall
	push @cells, { tdprop  => " width='1'" };
	# Cell
	push @cells, {
		tdprop	=> " bgcolor='#ffffff' width='".$cell_size."' class='map'",
		cell	=> '',
	};
	# Right wall
	push @cells, { tdprop  => " width='1'" };
      }
    }
    push @rows, { cells => \@cells };

    # Bottom walls
    my @bwalls;
    for( my $x=$t ; $x < $t + LSIZE * $wrap ; $x++ ){
      my $tdprop='';
      if(defined($umap->{$x}->{$y})) {
	my $Cell = $self->world->find($umap->{$x}->{$y});
	if( $Cell->is('p_down') ){
	  if( $Cell->is('known_location') || $Cell->p_m_down() =~ /\:$x\_$y\:/ ){
		$tdprop = $mark_wall;
	  }
	}
      }
      push @bwalls, { tdprop  => $tdprop };
    }
    push @rows, { bwalls => \@bwalls };
   }
   push @{$p->{parts}}, { rows => \@rows };
  }
  my $template = $self->template($self->name.'/usermap.tmpl',$p);
  return $template->output() if defined($template);
  return '';
}


1;

__END__
