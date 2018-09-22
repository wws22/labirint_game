package Labirint::Object;
# Safety wrapper for Games::Object
# $Header: /var/lib/cvsd/root/game/lib/Labirint/Object.pm,v 1.2 2007/02/23 12:29:49 wws Exp $
#

use strict;
use Engine::Debuger;

use Games::Object;
use vars qw(@ISA);
@ISA = qw(Games::Object);
use warnings;

#******************************************************************************
#* Constructor
#******************************************************************************
sub new {
    # Create object
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_ ,
	-try_contain => [ 
	  [ 'O:self', 'is', 'container' ],
	  FAIL => [ 'O:manager', 'output', 'O:object', " can't be placed into ", 'O:self' ],
	  [ 'O:self', 'can', 'try__contain' ],
	  FAIL => [ 'TRUE' ], 
	  [ 'O:self', 'try__contain', 'O:self', 'O:object' ],
	],
	-try_uncontain => [ 
	  # WARNING!!! self=Who_is_owner_now object=Object other=Remove_from
	  [ 'O:other', 'related', 'contain', 'O:object' ],
	  FAIL => [ 'O:manager', 'output', 'O:object', " doesn't present in ", 'O:other' ],
	  [ 'O:other', 'is', 'container' ],
	  [ 'O:other', 'can', 'try__uncontain' ],
	  FAIL => [ 'TRUE' ], 
	  [ 'O:other', 'try__uncontain', 'O:object' ],
	],
    );
    bless $self, $class;
    $self->class($class);
    $self->new_attr( -name => '_fakemark', -value => 0  );
    $self->new_flag( -name => 'container', -value => 0 ); 
    $self->type('');
    $self->_selfinfo(' created');
    return $self;
}

#******************************************************************************
#* Smart debug info method for trace unreferenced object
#******************************************************************************
sub _selfinfo {
  my $self = shift;
  my $id = $self->id();
  $id = defined($id) ? " '".$id."'" : '';
  info ref($self).'=MARK'.substr($self->attr_ref('_fakemark'),6,11).$id.(shift);
}

#******************************************************************************
#* Destructors
#******************************************************************************
sub DESTROY {
  my $self = shift;
  $self->_selfinfo(' destroyed');
}

sub is_not { # Like !$Obj->is('flag')
  my $self = shift;
  return !( $self->is(@_) );
}

sub if { # Check conditions
  return $_[1];
}

sub class { # Set/Get class name
  my $self = shift;
  my $set = shift;
  return $self->{_CLASS} if !defined($set);
  $self->{_CLASS} = $set;
}

sub type { # Set/Get object type
  my $self = shift;
  my $set = shift;
  return $self->{_TYPE} if !defined($set);
  $self->{_TYPE} = $set;
}

sub fullname { # Get a full object name (includes object type)
  my $self = shift;
  return ($self->type eq '' ? '' : $self->type.' ' ).$self;
}

#******************************************************************************
#* related( 'relation_name' ) # Return list of ID related objects
#* or
#* related( 'relation_name', Object ) # Return true if Object related with self
#*
#******************************************************************************
sub related {
  my $self = shift;
  my $relation_name = shift;
  return 0 unless defined($relation_name);
  my $other = shift;
  if(!defined($other)){
    my $World = $self->manager || return 0;
    return $World->related($relation_name,$self);
  }else{
    my $World = $self->manager || return [];
    return $World->related($relation_name,$self,$other);
  }
}

#******************************************************************************
#* relations() # Return HASH of Object relations 
#*             # { relation_name => relative_object }
#*
#******************************************************************************
sub relations {
  my $self = shift;
  my $World = $self->manager || return {};
  return $World->relations($self);
}

#******************************************************************************
#* in_relation( relation_name ) # Return relative Object or undef 
#*
#******************************************************************************
sub in_relation {
  my $self = shift;
  my $relation_name = shift; 
  return undef unless defined($relation_name);
  return $self->manager->find($self->relations->{$relation_name});
}

#******************************************************************************
#* spelling( mod_attr, mod_value ) # Use it from $World->process as:
#*
#* $World->process( 'spelling', 'mod_attr', mod_value );
#*
#* Then all object with presented mod_attr should be modified
#*
#******************************************************************************
sub spelling { 
  my $self =  shift;
  my $spell_attr = shift;
  my $mod_value = shift;
  if(defined($spell_attr) && defined($mod_value)){
    if ($self->attr_exists($spell_attr)) {
        $self->mod_attr(-name => $spell_attr, -modify => $mod_value );
    }
  }
}

1;

__END__
