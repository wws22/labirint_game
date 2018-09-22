#
# $Header: /var/lib/cvsd/root/game/lib/Engine/Log.pm,v 1.1.1.1 2007/02/05 14:42:06 wws Exp $
#
package Engine::Log;

use FileHandle;
use strict;
#******************************************************************************
#* constructor
#* new Engine::Log(     HANDLER   => LogFileHandler,
#*                      DEBUG     => Loglevel, # [0..4]
#*                      PREFIX    => "", # Message prefix (see FORMAT)
#*                      SEPARATOR => "\n", # Row separator
#*                      BUFSIZE   => 500, # Buffer size in records
#*                      NEED_CLOSE=> 0, # Close Handle during destroy object
#*                      LEVELNAMES=> 'SILENT  |ERROR   |WARNING |TRACE   |INFO    ', # Possible "||||"
#*                );
#* OR
#* new Engine::Log( handler, debug [,message_prefix] [,separator]
#*                  [,bufsize] [,need_close] [,levelnames] );
#*
#* FORMAT for prefix
#* "Any string with/without templates %p %t" where:
#*                      %p -  PID
#*                      %t -  localtime string
#******************************************************************************
sub new
{
  my $classname = shift;
  my $self = {
	       HANDLER => 0,
	       DEBUG => 1,
	       PREFIX => '%t [%p] ',
	       SEPARATOR => "\n",
	       BUFSIZE => 500,
	       NEED_CLOSE => 0,
	       BUFFER => [],
	       RECORDS => 0,
	       LEVEL => [ '[SILENT]  ','[ERROR]   ','[WARNING] ','[TRACE]   ','[INFO]    ' ],
	       LEVELNAMES => undef,
               PREFIX_OUT => []
	     };
  bless( $self, $classname );
  $self->_init( @_ );
  #print STDERR $self." created\n"; # INTERNAL DEBUG
  return $self;
}

#******************************************************************************
#* initialize - check for style one params
#******************************************************************************
sub _init {
  my $self = shift;

  # if it looks like a hash
  if ( @_ && (scalar( @_ ) % 2 == 0) )
  {
      # ... like a hash ...
      my %hashargs = @_;
      if ( defined($hashargs{HANDLER}) )
      {
	  # Push all values into my internal hash.
	  foreach my $key (keys %hashargs) {
	      $self->{$key} = $hashargs{$key};
          }
      }
      else {$self->_initAnotherStyle( @_ );}
  }
  else {$self->_initAnotherStyle( @_ );}
  $self->prefix($self->{PREFIX}); 
  if(defined($self->{LEVELNAMES})){
	@{$self->{LEVEL}} = split(/\|/,$self->{LEVELNAMES});
  }
  $self->{HANDLER}->autoflush(1);
}

#******************************************************************************
#* initialize using positional parameter style
#******************************************************************************
sub _initAnotherStyle {
  my $self = shift;
  $self->handler( shift );
  $self->debug( shift );
  $self->prefix( shift );
  $self->separator( shift );
  $self->bufsize( shift );
  $self->{NEED_CLOSE} = shift;
  $self->{LEVELNAMES} = shift;
}

#******************************************************************************
#* set/get HANDLER
#******************************************************************************
sub handler
{
  my $self = shift;
  my $set = shift;
  return $self->{HANDLER} if !defined($set);
  $self->{HANDLER} = $set;
}

#******************************************************************************
#* set/get DEBUG
#******************************************************************************
sub debug
{
  my $self = shift;
  my $set = shift;
  return $self->{DEBUG} if !defined($set);
  $self->{DEBUG} = $set;
}

#******************************************************************************
#* set/get PREFIX
#******************************************************************************
sub prefix
{
  my $self = shift;
  my $set = shift;
  return $self->{PREFIX} if !defined($set);
  $self->{PREFIX} = $set;
  $set =~ s/\%p/$$/g;
  @{$self->{PREFIX_OUT}} = split(/\%t/, $set);
}

#******************************************************************************
#* set/get SEPARATOR
#******************************************************************************
sub separator
{
  my $self = shift;
  my $set = shift;
  return $self->{SEPARATOR} if !defined($set);
  $self->{SEPARATOR} = $set;
}

#******************************************************************************
#* set/get NEED_CLOSE
#******************************************************************************
sub need_close
{
  my $self = shift;
  my $set = shift;
  return $self->{NEED_CLOSE} if !defined($set);
  $self->{NEED_CLOSE} = $set;
}

#******************************************************************************
#* set/get BUFSIZE
#******************************************************************************
sub bufsize
{
  my $self = shift;
  my $set = shift;
  return $self->{BUFSIZE} if !defined($set);
  $self->{BUFSIZE} = $set;
}

#******************************************************************************
#* set/get RECORDS
#******************************************************************************
sub records
{
  my $self = shift;
  my $set = shift;
  return $self->{RECORDS} if !defined($set);
  $self->{RECORDS} = $set;
}

#******************************************************************************
#* close - Close FILHANDLE
#******************************************************************************
sub close
{
  my $self = shift;
  $self->flush();
  return 1 if($self->{HANDLER} == \*STDERR); # STDERR - never close
  return $self->{HANDLER}->close() if($self->{NEED_CLOSE});
  return 0;
}

#******************************************************************************
#* flush - erase LOG buffer
#******************************************************************************
sub flush
{
  my $self = shift;
  $self->records(0);
  return $self->{BUFFER}=[];
}

#******************************************************************************
#* getback( [separator] ) - return LOG buffer as string
#*      where separator = "\n" by default
#******************************************************************************
sub getback
{
  my $self = shift;
  my $sep = shift;
  $sep = "\n" if !defined($sep);
  return join("$sep",@{$self->{BUFFER}});
}

#******************************************************************************
#* print( LogLevel, Message)
#******************************************************************************
sub print
{
  my $self = shift;
  my $ll = shift;
  my $msg = shift;
  my $res = 0;
  my $t = localtime(time);
  my $str = join( $t, @{$self->{PREFIX_OUT}}).
            $self->{LEVEL}->[$ll].$msg.$self->{SEPARATOR};
  if( $ll <= $self->{DEBUG} ){
    $res = $self->{HANDLER}->print($str);
  }
  if($self->{BUFSIZE}>0){
  	push( @{$self->{BUFFER}}, $str);
  	shift @{$self->{BUFFER}} if( $self->{RECORDS}++ >= $self->{BUFSIZE} );
  }
  return $res;
}

#******************************************************************************
#* destructor
#******************************************************************************
sub DESTROY {
  my $self = shift;
  $self->close();
  #print STDERR $self." destroyed\n"; # INTERNAL DEBUG
}

1;
__END__
