#
# $Header: /var/lib/cvsd/root/game/lib/Engine/Request.pm,v 1.8 2007/02/22 10:49:19 wws Exp $
#
package Engine::Request;

require Exporter; @ISA=qw{Exporter main::main}; @EXPORT=qw{}; @EXPORT_OK=qw{};

use config;
use Engine::Debuger;

use URI::Escape;
use HTML::Template;
use strict;

#******************************************************************************
#* constructor
#* new Engine::Request( EngineObject )
#******************************************************************************
sub new 
{
  my $classname = shift;
  my $self = {
	       _ENGINE	 => undef, # Engine object
	       _FAIL	 => 0,     # Request fail flag
	       _SCRIPT	 => undef, # Script's name
	       _NAME	 => undef, # Request's name
	       _FULLNAME => undef, # Request's original name (Be careful!)
	       _HEADERS	 => undef, # Additional headers
	       _REDIRECT => undef, # Redirect (as CGI::redirect)
	       _SET_COOK => undef, # Setting into browser cookies (ARRAY)
	       _GET_COOK => {},    # Received cookies 
	       _GET_PARM => {},    # Received request-params
	       _OUTPUT   => undef, # STDOUT buffer
	       _NUMBER   => undef, # Request number
	     };
  bless( $self, $classname );
  $self->_init( @_ );
  $self->is_fail(0);
  %{$self->{_HEADERS}} = %{$self->engine->headers};
  $self->_cookies();
  $_=$ENV{SCRIPT_NAME};
  $self->script($_);
    s/\A.*\///;
    s/\..*\Z//;
  $self->name($_);
  $self->_params(); # Always used after $self->name($_). Be careful!
  $self->{_NUMBER} = $self->engine->count();
  info $self.' created ['.$self->{_NUMBER}.']';
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
      if ( defined($hashargs{_ENGINE}) )
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
  $self->{_ENGINE} = shift;
}

#******************************************************************************
#* Get all cookies from browser and put into _GET_COOK
#******************************************************************************
sub _cookies {
  my $self = shift;
  return {} unless defined($ENV{HTTP_COOKIE});
  my @pairs = split(/; /, $ENV{HTTP_COOKIE});
  foreach (@pairs) {
    my ($name, $value) = split(/=/, $_, 2);
    $self->{_GET_COOK}->{uri_unescape($name)} = uri_unescape($value);
  }
  return $self->{_GET_COOK};
}

#******************************************************************************
#* Get all (GET & POST) params from browser and put into _GET_PARM
#******************************************************************************
sub _params {
  my $self = shift;
  my $post = '';

  my $in = $self->engine->fh_in(); # Get IO:Handle
  while(<$in>){	$post .= $_; }     # Read posting

  my @pairs = split(/&/, $ENV{QUERY_STRING});
  push( @pairs, split(/&/, $post) );
  foreach (@pairs) {
    my ($name, $value) = split(/=/, $_ , 2);
    next unless defined($name);
    unless(defined($value)){ 
	$value = '';
	unless( defined($self->{_FULLNAME}) ){      # Define request fullname
		$_ = uri_unescape($name);
		tr/a-zA-Z0-9_\-\///cd; # Only ( alpha : digit : _ : - : / ) allowed
		$self->fullname($self->name().'/'.$_);
	}
    }
    $value =~ tr/+/ /;
    $self->{_GET_PARM}->{uri_unescape($name)} = uri_unescape($value);
  }
}

#******************************************************************************
#* setters/getters
#******************************************************************************
sub engine { # set/get Engine object
  my $self = shift;
  my $set = shift;
  return $self->{_ENGINE} if !defined($set);
  $self->{_ENGINE} = $set;
}

sub is_fail { # get/set Request _FAIL flag
  my $self = shift;
  my $set = shift;
  return $self->{_FAIL} if !defined($set);
  $self->{_FAIL} = $set;
}

sub script { # set/get name of CGI script
  my $self = shift;
  my $set = shift;
  return $self->{_SCRIPT} if !defined($set);
  $self->{_SCRIPT} = $set;
}

sub name { # set/get request name
  my $self = shift;
  my $set = shift;
  return $self->{_NAME} if !defined($set);
  $self->{_NAME} = $set;
}

sub fullname { # set/get request fullname
  my $self = shift;
  my $set = shift;
  unless( defined($set) ){
	return $self->{_FULLNAME} if defined($self->{_FULLNAME});
	return $self->{_NAME}; # otherwise
  }
  $self->{_FULLNAME} = $set;
}

sub headers { # set/get request headers
  my $self = shift;
  my $set = shift;
  return $self->{_HEADERS} if !defined($set);
  $self->{_HEADERS} = $set;
}

sub parent { # parent( name ) # Get engine parent param -> name
  my $self = shift;
  my $name = shift;
  return undef if !defined($name);
  return $self->engine->parent->{$name};
}

#******************************************************************************
#* param( name ) # Get request params or undef
#* or
#* param() or
#* params()       # Return all request params  as reference to HASH:
#*                 {
#*                   param_name => 'value',
#*                   ...
#*                 }
#******************************************************************************
sub param {
  my $self = shift;
  my $name = shift;
  if( !defined($name) ){
	# Return all params
	return $self->{_GET_PARM};
  }
  return $self->{_GET_PARM}->{$name};
}

sub params {
  my $self = shift;
  return $self->{_GET_PARM};
}

#******************************************************************************
#* cookie(...) Provide cookie interface like a CGI::cookie
#*
#* Possible use:
#* 
#* cookie( -name=>'sessionID',  # Set up new cookie into browser
#*	   -value=>'xyzzy',
#*	   -expires=>'+1h',
#*	   -path=>'/cgi-bin/database',
#*	   -domain=>'.capricorn.org',
#*	   -secure=>1
#* ) or
#* cookie( 'name', 'value' )    # Set up new cookie as :
#*                              # cookie( -name=>'name', -value=>'value' )
#*
#* cookie( name ) # Return receipted from browser cookie-value or undef
#*
#* cookie() or
#* cookies() # Return all receipted from browser cookies as reference to HASH:
#*            { 
#*              cookie_name => 'value',
#*              ...
#*            }
#******************************************************************************
sub cookie {
  my $self = shift;
  if( @_ ){
    if( (scalar( @_ ) % 2 == 0) )  
    {
      if( scalar( @_ ) > 2 ){
        # Looks like a hash ... Create cookie
	push  @{$self->{_SET_COOK}}, CGI::cookie( @_ );
      }else{
        # Looks like pair: ( name, value )
	push  @{$self->{_SET_COOK}}, CGI::cookie( -name=>$_[0], -value=>$_[1] );
      }
    }else{
	# Return a single cookie-value
	return $self->{_GET_COOK}->{$_[0]};
    }
  }else{
	# Return all cookies
	return $self->{_GET_COOK};
  }
  return 1;
}

sub cookies {
  my $self = shift;
  return $self->{_GET_COOK};
}

#******************************************************************************
#* redirect(...) Provide redirect interface from CGI::redirect
#*
#* Possible use:
#* 
#* redirect( somewhere ) or 
#* redirect( -uri=>'somewhere', -status=>301, -nph=>1 );
#*          where status is
#*            301 Moved Permanently
#*            302 Found (Moved Temporarily) - by DEFAULT
#*            303 See Other
#*
#* redirect() - Return current CGI::redirect or undef
#******************************************************************************
sub redirect {
  my $self = shift;
  if( @_ ){
    if( scalar( @_ ) % 2 == 0 ){
	# Looks like a hash ... Create CGI::redirect object
	$self->{_REDIRECT} = CGI::redirect( @_ );
    }else{
	# Simle redirect
	unless(defined($self->{_SET_COOK})){
	  $self->{_REDIRECT} = CGI::redirect( '-uri' => $_[0] );
	}else{
	  $self->{_REDIRECT} = CGI::redirect( '-uri' => $_[0], '-cookie' => $self->{_SET_COOK} );
	}
    }
  }else{
	return $self->{_REDIRECT};
  }
}

#******************************************************************************
#* Create new or return exists shared template object
#* template( filename ) # Return: template object
#*
#* template( filename, template_params ) 
#*    Produce:
#*       1) Find exists or create new template object
#*       2) Clear template_params if object isn't new
#*       3) Apply new template_params to object
#*       4) Return template object
#*
#******************************************************************************
sub template {
  my $self = shift;
  my $filename = shift;
  my $params = shift;
  unless( defined($filename) ){
	$self->fail('Using Engine::Request::template(without filename)');
	return undef;
  }
  my $template = $self->engine->template($filename);
  my $new_flag = 0; 
  unless( defined($template) ){
	# Create new template
	info ("Create new template: ".$filename);
	$_ = $filename.'';
	tr/a-zA-Z0-9_\-\.\///cd; # Only ( alpha : digit : _ : - : . : / ) allowed
	s/\.\.//g; s/\A\/*//;    # Remove ".." and trail slashes
	$filename = $_;
	if( -e TEMPLATES_DIR.'/'.$filename ){
	  $template = HTML::Template->new(
		filename => $filename,
		shared_cache => 1,
		#shared_cache_debug => 1, # INTERNAL DEBUG
		global_vars => 1,
		loop_context_vars => 1,
		die_on_bad_params => 0,
		path => [ TEMPLATES_DIR ],
		search_path_on_include => 1
	  );
	}
	unless( defined($template) ){
	  $self->fail("Can't create new template: '".$filename."'");
	  return undef;
	}
	$self->engine->template($filename, $template);
	$new_flag = 1;
  }
  return $template unless defined($params);
  # Apply params
  info ("Apply params for template: ".$filename);
  $template->clear_params() unless $new_flag;
  $template->param($params);
  return $template;
}

#******************************************************************************
#* print - Prepare something for output to STDOUT
#******************************************************************************
sub print {
	my $self = shift;
	push @{$self->{_OUTPUT}}, @_;
}

#******************************************************************************
#* output - Output all result of Engine::Request->main() to STDOUT
#******************************************************************************
sub output {
  my $self = shift;
  my $Engine = $self->engine();
  my $CGI = $Engine->cgi();
  if( defined($self->{_REDIRECT}) ) {
	print $self->redirect();
  }else{
    if( !defined($CGI->{'.header_printed'}) || $Engine->count() > $CGI->{'.header_printed'} ) {
      if( defined($self->{_SET_COOK} ) ) {
	$self->headers->{'-cookie'} = $self->{_SET_COOK};
      }
      print $CGI->header( $self->headers );
    }else{
	warning $self.'->output() used twice!';
    }
    print @{$self->{_OUTPUT}} if defined($self->{_OUTPUT});
  }
  delete($self->{_OUTPUT});
  return;
}

#******************************************************************************
#* fail - If something wrong
#******************************************************************************
sub fail {
  my $self = shift;
  my $message = shift;
  $self->is_fail(1);
  delete($self->{_OUTPUT}); # Clean all

  # Prepare page
  my $html = '<html><head><meta http-equiv="content-type" '.
	'content="text/html; charset='.CHARSET.'"/><title>'.
	'Error in '.$self->script.'</title></head><body>'.
	"\n<h1>Error in ".$self->script."</h1>\n<h2>".$message."</h2>\n";
  if( $self->can('dumper') ){
	$html .= "<pre>\n".$self->dumper()."</pre>\n";
  }
  $html .= '</body></html>';

  $self->print($html);
  error $message, ( $self->can('dumper') ? $self->dumper() : $self );
  $self->output; # Flush output
}

#******************************************************************************
#* destructor
#******************************************************************************
sub DESTROY {
  my $self = shift;
  info $self.' destroyed ['.$self->{_NUMBER}.']';
}

1;

__END__

