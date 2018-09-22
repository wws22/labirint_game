package Labirint::World;
# Safety wrapper for Games::Object::Manager
# $Header: /var/lib/cvsd/root/game/lib/Labirint/World.pm,v 1.4 2007/02/25 16:37:34 wws Exp $
#

use strict;
use Engine::Debuger;
use URI::Escape;

use Games::Object::Manager qw(REL_NO_CIRCLE);
use vars qw(@ISA);
@ISA = qw(Games::Object::Manager);
use warnings;

#******************************************************************************
#* Constructor
#******************************************************************************
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $e_params; # my specific params
  ($e_params, @_) = $proto->_init( @_ );
  my $self = $class->SUPER::new( @_ );
  foreach (keys %{$e_params} ){
	$self->{$_} = $e_params->{$_};
  }
  bless $self, $class;
  $self->quiet(0);
  $self->define_relation( -name => 'contain',	-flags => REL_NO_CIRCLE, );
  info $self." created";
  return $self;
}

#******************************************************************************
#* initialize - check engine specific parameters
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
        unless( /\A\-/ ){ # All Games::Object::Manager parms started with '-'
	  $own{$_} = $hashargs{$_};
	  delete($hashargs{$_});
        }
      }
      return ( \%own, %hashargs );
  }
  return ( \%own, @_ );
}

sub add {
  my $self = shift;
  my @r = $self->SUPER::add( @_ );
  if( defined($_[0]) ){ 
    push @{$self->{_managed}}, $_[0]->id;
  }
  return @r;
}

#******************************************************************************
#* Destructors
#******************************************************************************
sub DESTROY {
  my $self = shift;
  $self->destroy;
  info $self." destroyed";
}

#******************************************************************************
#* destroy( ) # Remove all objects from World for cleanup
#* or
#* destroy( Object ) # Remove one objects from World
#*
#******************************************************************************
sub destroy { 
  my $self = shift;
  my $Object = shift;
  if( defined($Object) ) {
    my $Obj = $self->find($Object);
    return 0 unless $self->managed($Obj);
    my %rel = %{$self->relations($Obj)};
    foreach (keys %rel){
	$self->unrelate(
          -how    => $_,
          -self   => $rel{$_},
          -object => $Obj,
          -force  => 1,
	);
    }
    $self->remove($Obj);
    my @managed = grep( $Obj ne $_ , @{$self->{_managed}});
    @{$self->{_managed}} = @managed;
  }else{
    foreach(@{$self->{_managed}}){
      my $Obj = $self->find($_);
      if( defined($Obj) && defined($Obj->id()) ){
	local ($^W) = 0; $self->remove($_); # Because author of Object::Manager don't use warnings
	delete($self->{index}->{$_});
      }
    }
    delete($self->{_managed});
  }
  return 1;
}

#******************************************************************************
#* related( 'relation_name', Object ) # Return list of ID related objects
#* or
#* related( 'relation_name', Object, Object2 ) # Return true if Object2 
#*                                             # related with Object
#*
#******************************************************************************
sub related {
  my $self = shift;
  my $relation_name = shift;
  my $obj = shift;
  my $other = shift;
  if(!defined($other)){
    return [] unless defined($obj);
    my $Object = $self->find($obj);
    return [] unless defined($Object);
    return [] unless exists($self->{relate_from}->{$Object}->{$relation_name});
    return $self->{relate_from}->{$Object}->{$relation_name};
  }else{
    return 0 unless defined($obj);
    my $Object = $self->find($obj);
    return 0 unless defined($Object);
    my $Other = $self->find($other);
    return 0 unless defined($Other);
    return 0 unless exists($self->{relate_from}->{$Object}->{$relation_name});
    $_ = grep( $_ eq $Other , @{$self->{relate_from}->{$Object}->{$relation_name}} );
    return $_;
  }
}

#******************************************************************************
#* relations( Object ) # Return HASHREF of Object relations 
#*                     # { ralation_name => relative_object }
#*
#******************************************************************************
sub relations {
  my $self = shift;
  my $obj = shift;
  return {} unless defined($obj);
  my $Object = $self->find($obj);
  return {} unless defined($Object);
  return {} unless exists($self->{relate_to}->{$Object});
  return $self->{relate_to}->{$Object};
}

#******************************************************************************
#* managed( ) # Return list of ID managed objects
#* or
#* managed( Object ) # Return true if Object managed
#*
#******************************************************************************
sub managed {
  my $self = shift;
  my $obj = shift;
  if(!defined($obj)){
    return [] unless exists($self->{_managed});
    return $self->{_managed};
  }else{
    return 0 unless exists($self->{_managed});
    my $Object = $self->find($obj);
    return 0 unless defined($Object);
    $_ = grep( $_ eq $Object , @{$self->{_managed}} );
    return $_;
  }
}


#******************************************************************************
#* Game specific methodes
#******************************************************************************
sub request { # Set/Get request  NB!!! Special case request(0) -  delete
  my $self = shift;
  my $set = shift;
  return $self->{request} if !defined($set);
  $self->{request} = $set;
  delete $self->{request} if $set == 0;
}

sub quiet { # Flag for Suppress all output messages 
  my $self = shift;
  my $set = shift;
  return $self->{quiet} if !defined($set);
  $self->{quiet} = $set;
}

sub output {
  my $self = shift;
  return 1 if $self->quiet; # Quiet mode
  my $str = join( '', @_ );	
  $self->{request}->cout($str) if( defined($self->{request}) && $str ne '' );
  return 1;
}

sub help {
  my $self = shift;
  return 1 if $self->quiet; # Quiet mode
  my $str = join( '', @_ );	
  $self->{request}->help($str) if( defined($self->{request}) && $str ne '' );
  return 1;
}

#******************************************************************************
#* question ( format ); # Qustion to player
#*
#* Where: format is string "Text one::value1|text other::value2..."
#*
#******************************************************************************
sub question { 
  my $self = shift;
  my $question = shift;
  return 0 unless defined($question);
  my @var = split( /\|/, $question );
  return 0 if ($#var < 0);
  my $script = $self->request->script();
  my @str;
  foreach my $ans (@var){
    my ($text,$value) = split( '::', $ans );
    push @str, "<a href='".$script."?answer\&answer=".uri_escape($value)."'>".$text."</a>";
  }
  $self->output( join( ' / ', @str ) );
  return 1;
}

1;

__END__
