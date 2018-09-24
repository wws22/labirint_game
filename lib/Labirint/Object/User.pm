package Labirint::Object::User;
# Subclass of Labirint::Object
# $Header: /var/lib/cvsd/root/game/lib/Labirint/Object/User.pm,v 1.1 2007/02/21 05:55:30 wws Exp $
#

use strict;
use Engine::Debuger;
use Digest::SHA1;

use Labirint::Object;
use vars qw(@ISA);
@ISA = qw(Labirint::Object);
use warnings;

use constant SHA_FILLER => 'my long filler for creating unique sha1 check-string';

sub new {
    # Create object
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_,
    );
    bless $self, $class;
    $self->type('Пользователь'); 
    # Add attributes
    $self->new_attr(
	-name	=> 'login',
	-type	=> 'string',
	-value	=> '',
    );
    $self->new_attr(
	-name	=> 'password',
	-type	=> 'string',
	-value	=> '',
    );
    return $self;
}

sub generate_key {
  my $self = shift;
  my $password = shift;
  $password = '' unless defined($password);
  return Digest::SHA1::sha1_hex( 
	$self->login.':'.
	$password.':'.
	#$ENV{'REMOTE_ADDR'}.':'.
	SHA_FILLER
  );
}

sub check_key {
  my $self = shift;
  my $key = shift;
  $key = '' unless defined($key);
  my $true_key = Digest::SHA1::sha1_hex( 
	$self->login.':'.
	$self->password.':'.
	#$ENV{'REMOTE_ADDR'}.':'.
	SHA_FILLER
  );
  return ($key eq $true_key);
}

1;

__END__
