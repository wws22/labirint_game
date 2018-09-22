#
# $Header: /var/lib/cvsd/root/game/lib/Engine/Debuger.pm,v 1.2 2007/02/16 14:52:47 wws Exp $
#
package Engine::Debuger;

use Data::Dumper;

require Exporter; 
@ISA=qw{Exporter}; 
@EXPORT=	qw{&error &warning &trace &info &Dumper}; 
@EXPORT_OK=	qw{&error &warning &trace &info &Dumper};

use Class::ISA;

use config;
use Engine::Globals;
use Data::Dumper;
use Engine::Log;
use strict;

sub mylog;
sub myprint;
sub error;
sub warning;
sub trace;
sub info;

my %dbgs; # Debugger objects pool for MOD-PERL compability

#******************************************************************************
#* constructor
#* new Engine::Debuger( [LogObject] )
#******************************************************************************
sub new 
{
  my $classname = shift;
  my $self = {
		LOG       => undef, # Log object
		FH_IN     => undef, # Used handles (IO::Handle)
		FH_OUT    => undef,
		FH_ERR    => undef
	     };
  bless( $self, $classname );
  $self->_init( @_ );
  #$self->log->print(INFO,$self." created\n"); # INTERNAL DEBUG
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
      if ( exists($hashargs{LOG}) )
      {
	  # Push all values into my internal hash.
	  foreach my $key (keys %hashargs) {
	      $self->{$key} = $hashargs{$key};
          }
      }
      else {$self->_initAnotherStyle( @_ );}
  }
  else {$self->_initAnotherStyle( @_ );}

  unless(defined($self->log)){
    $self->log($self->create_new_log());
  }
  $dbgs{$$} = $self unless defined($dbgs{$$});
}

#******************************************************************************
#* initialize using positional parameter style
#******************************************************************************
sub _initAnotherStyle {
  my $self = shift;
  $self->{LOG} = shift;
}

sub log { # set/get Engine::Log object
  my $self = shift;
  my $set = shift;
  return $self->{LOG} if !defined($set);
  $self->{LOG} = $set;
}

#******************************************************************************
#* create new log object
#* create_new_log ( [log_file_name] )
#******************************************************************************
sub create_new_log {
    my $self = shift;
    my $filename = shift; # Optional.
    $filename = LOGFILE unless defined($filename);
    my $need_close=0;

    my $Log;  # Future Engine::Log object
    my $log_ha; # Log filehandle
    my $log_error=undef; # SEE BOTTOM: When LOGFILE is not open or another error
    my $log_pfx='[%p] '; # For Apache log or STDOUT
    if($filename eq ''){
      if( defined($self->{FH_ERR}) ){ $log_ha = $self->{FH_ERR}; }
      else{ $log_ha = \*STDERR; }
    }elsif($filename eq '*STDERR'){
      if( defined($self->{FH_ERR}) ){ $log_ha = $self->{FH_ERR}; }
      else{ $log_ha = \*STDERR; }
    }elsif($filename eq '*STDOUT'){
      if( defined($self->{FH_OUT}) ){ $log_ha = $self->{FH_OUT}; }
      else{ $log_ha = \*STDOUT; }
    }else{
	if( open( $log_ha, '>>'.$filename )){
		$log_pfx='%t [%p] '; 
		$need_close=1; 
	}else{
                if( defined($self->{FH_ERR}) ){ $log_ha = $self->{FH_ERR}; }
                else{ $log_ha = \*STDERR; }

		$log_error="Can't open >>".$filename." ... Using STDERR.";
	}
    }
    $Log = new Engine::Log(	HANDLER   => $log_ha,
				DEBUG     => DEBUG,
				PREFIX    => $log_pfx,
				SEPARATOR => "",
				BUFSIZE   => LOGSTACK,
				NEED_CLOSE=> $need_close 
    );
    if(defined($log_error)){
	$Log->print(WARNING,$log_error);
    }
    return $Log;
}
#******************************************************************************
#* dumper 
#******************************************************************************
sub dumper {
    my $self = shift;
    return Dumper($self);
}

#******************************************************************************
#* Not class members !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1111!!
#******************************************************************************
sub info	{ return unless (LOGSTACK || DEBUG>=INFO);
		  myprint(INFO,mylog(0,1,@_));	}
sub trace	{ return unless (LOGSTACK || DEBUG>=TRACE);
		  myprint(TRACE,mylog(0,1,@_));	}
sub warning	{ return unless ( LOGSTACK || DEBUG>=WARNING);
		  myprint(WARNING,mylog(0,1,@_));	}
#******************************************************************************
#* error - is special case
#******************************************************************************
sub error	{
	return unless ( LOGSTACK || DEBUG>=ERROR );
	my $Log=$dbgs{$$}->{LOG};
	if(DEBUG<INFO && LOGSTACK && $Log->records()){
		my $tab='  | ';
		my $gb = $tab.$dbgs{$$}->{LOG}->getback('');
		$gb =~ s/\n\Z//;
		$gb =~ s/\n/\n$tab/g;
		$Log->print(ERROR,	"... see after BackTrace ...\n".
				"BackTrace start\n".
				$gb."\n".
				"BackTrace finish\n");
		$Log->flush();
	}
	$Log->print(ERROR,mylog(0,1,@_));
	$Log->flush();
}

#******************************************************************************
#* myprint( LogLevel, Message) # Internal print to LOG
#******************************************************************************
sub myprint 
{
	$dbgs{$$}->{LOG}->print(shift,shift);
}

#******************************************************************************
#* mylog ( recurse_level, can_use_native_dumper, [...] ) # Prepare ... to print 
#******************************************************************************
sub mylog 
{
	my $depth = 1 + shift;
	my $can_native_method = shift;
	my $out='';
	foreach my $value (@_){
		my $r = ref($value);
		if ($r eq ''){
			$out.=$value."\n";
		}elsif( $r eq 'ARRAY' ){
			my $i=0; $out.='ARRAY:'."\n";
			foreach(@{$value}){
				 $out.= ( '      ' x $depth ) .
					sprintf("[%03u]:",$i++).
					mylog($depth,1,$_);
			}
		}elsif( $r ne 'HASH'   && $can_native_method &&
			$r ne 'SCALAR' && $r ne 'GLOB' && 
			$r ne 'LVALUE' && $r ne 'REF' &&
			$value->can('dumper')
			){
			my $res = $value->dumper();
			if(defined($res)){
				if (ref($res) eq ''){
					$out .= $res;
				}else{
					$out .= mylog($depth,0,$res);
				}
			}else{
				$out.=$r.'::dumper() return undef'."\n";
			}
		}else{
			$out.=$r.':'.Dumper($value);
		}
	}
	return $out;
}

1;

__END__
#******************************************************************************
#* INTERNAL DEBUG destructor
#******************************************************************************
sub DESTROY {
    my $self = shift;
    if(defined($self->log)){
	$self->log->print(INFO,$self." destroyed\n"); 
	$self->log->close(); 
    }
}
