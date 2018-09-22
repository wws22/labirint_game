#
# $Header: /var/lib/cvsd/root/game/lib/Engine.pm,v 1.4 2007/02/22 10:49:19 wws Exp $
#
package Engine;

require Exporter; @ISA=qw{Exporter}; @EXPORT=qw{}; @EXPORT_OK=qw{};

use config;		push @EXPORT, qw{DEBUG LOGFILE LOGSTACK CHARSET TEMPLATES_DIR};
use Engine::Globals;	push @EXPORT, qw{SILENT ERROR WARNING TRACE INFO};
use Engine::Debuger;	push @EXPORT, qw{&error &warning &trace &info &Dumper};
use Engine::Request;
use Engine::DS;

use FCGI;
use CGI qw{header};
use strict;

sub Run {
  my @parent_params = @_; # Additional Engine parameters from parent
   
  my $count = 0;
  my $FCGIReq = FCGI::Request(\*STDIN, \*STDOUT, \*STDERR, \%ENV);
  my $Engine = new Engine( $FCGIReq );

  if(@parent_params){ # Additional params from perl-script reached
    if(scalar( @parent_params ) % 2 == 0){ # Looks good
	info "Setting up additional Engine parameters";
	my %hash = @parent_params;
	$Engine->parent(\%hash);
        if(exists($Engine->parent->{header})){
	  foreach my $k (keys %{$Engine->parent->{header}}) {
		$Engine->headers->{$k} = $Engine->parent->{header}->{$k};	
	  }
	}
    }
    else{ warning "Additional Engine parameters are not loaded!"; }
  }else{
	$Engine->parent({});
  }

  while($Engine->fcgireq->Accept() >= 0) {
    $Engine->count(++$count);
    my $Request =  new Engine::Request( $Engine );
    if($Request->can('main')){
	trace $Request.'->main('.$Request->fullname.') starting';
	eval { $Request->main() }; $Request->fail(join('',$@)) if ($@);
	trace $Request.'->main('.$Request->fullname.') finished';
	unless( $Request->is_fail() ){
	  $Request->output();
	}else{
	  $Request->cleanup() if $Request->can('cleanup');
	}
    }else{
	$Request->fail($Request.' Failed! Perhaps You forgot describe main()');
    }
    $Request = undef; # Destroy request object
    $Engine->log->flush();
    #$FCGIReq->Flush();
    $FCGIReq->Finish();
  }
}

#******************************************************************************
#* constructor
#* new Engine( FCGI_request )
#******************************************************************************
sub new
{
  my $classname = shift;
  my $self = {
	       FH_IN     => undef, # Used handles (IO::Handle)
	       FH_OUT    => undef,
	       FH_ERR    => undef,
	       DBG       => undef, # Debuger object
	       FCGIREQ   => undef, # FCGI request
	       REQCOUNT  => undef, # requset count
	       CGI       => undef, # CGI object
	       HEADERS   => {      # CGI headers
		'-type' => 'text/html',
		'-charset' => CHARSET,
		'-pragma' => 'public',
		'-cache-Control' => 'no-cache'
	       },
	       PARENT_PARAMS => {}, # Script .cgi params
	       TEMPLATES => {}      # Shared templates pool
	     };
  bless( $self, $classname );
  $self->_init( @_ );

  ($self->{FH_IN}, $self->{FH_OUT}, $self->{FH_ERR}) = $self->fcgireq->GetHandles();
  $self->dbg(new Engine::Debuger(
		LOG    => undef, # Log is not created yet
		FH_IN  => $self->{FH_IN},
		FH_OUT => $self->{FH_OUT},
		FH_ERR => $self->{FH_ERR}
  ));
  $self->cgi(new CGI('')); # Always use '' for both (CGI&FCGI) compability
  info $self." created";
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
      if ( defined($hashargs{FCGIREQ}) )
      {
	  # Push all values into my internal hash.
	  foreach my $key (keys %hashargs) {
	      $self->{$key} = $hashargs{$key};
          }
      }
      else {$self->_initAnotherStyle( @_ );}
  }
  else {$self->_initAnotherStyle( @_ );}
}

#******************************************************************************
#* initialize using positional parameter style
#******************************************************************************
sub _initAnotherStyle {
  my $self = shift;
  $self->fcgireq(shift);
}

sub fcgireq { # set/get FCGI request object
  my $self = shift;
  my $set = shift;
  return $self->{FCGIREQ} if !defined($set);
  $self->{FCGIREQ} = $set;
}

sub is_fcgi { # get FCGI flag
  my $self = shift;
  return $self->fcgireq->IsFastCGI();
}

sub count { # set/get requests count
  my $self = shift;
  my $set = shift;
  return $self->{REQCOUNT} if !defined($set);
  $self->{REQCOUNT} = $set;
}

sub dbg { # set/get Engine::Debuger object
  my $self = shift;
  my $set = shift;
  return $self->{DBG} if !defined($set);
  $self->{DBG} = $set;
}

sub log { # set/get Engine::Log object
  my $self = shift;
  my $set = shift;
  return $self->dbg->{LOG} if !defined($set);
  $self->dbg->{LOG} = $set;
}

sub cgi { # set/get CGI object
  my $self = shift;
  my $set = shift;
  return $self->{CGI} if !defined($set);
  $self->{CGI} = $set;
}

sub parent { # set/get engine parent params
  my $self = shift;
  my $set = shift;
  return $self->{PARENT_PARAMS} if !defined($set);
  $self->{PARENT_PARAMS} = $set;
}

sub headers { # set/get engine default cgi headers
  my $self = shift;
  my $set = shift;
  return $self->{HEADERS} if !defined($set);
  $self->{HEADERS} = $set;
}

sub templates_pool { # set/get engine shared templates pool
  my $self = shift;
  my $set = shift;
  return $self->{TEMPLATES} if !defined($set);
  $self->{TEMPLATES} = $set;
}

sub fh_in { # set/get IN IO::Handle
  my $self = shift;
  my $set = shift;
  return $self->{FH_IN} if !defined($set);
  $self->{FH_IN} = $set;
}

sub fh_out { # set/get OUT IO::Handle
  my $self = shift;
  my $set = shift;
  return $self->{FH_OUT} if !defined($set);
  $self->{FH_OUT} = $set;
}

sub fh_err { # set/get ERR IO::Handle
  my $self = shift;
  my $set = shift;
  return $self->{FH_ERR} if !defined($set);
  $self->{FH_ERR} = $set;
}

#******************************************************************************
#* template( name ) # Get engine shared template object by name
#* template( name, template_object ) # Set shared template object by name
#******************************************************************************
sub template { 
  my $self = shift;
  my $name = shift;
  my $set = shift;
  return $self->templates_pool->{$name} if !defined($set);
  $self->templates_pool->{$name} = $set;
}


sub DESTROY {
	my $self = shift;
	info $self." destroyed";
}

1;
__END__

