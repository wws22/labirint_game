#
# $Header: /var/lib/cvsd/root/game/lib/config.pm,v 1.3 2007/02/21 20:16:46 wws Exp $
#
package config;

require Exporter;

@ISA=qw{Exporter};
@EXPORT=qw{DEBUG LOGFILE LOGSTACK CHARSET TEMPLATES_DIR PORT QUEUE_LENGTH};
@EXPORT_OK=qw{DEBUG LOGFILE LOGSTACK CHARSET TEMPLATES_DIR PORT QUEUE_LENGTH};

use Engine::Globals;

use constant DEBUG => ERROR;	# Debug level (SILENT, ERROR, WARNING, TRACE, INFO)
use constant LOGFILE => 'logs/app_log';     # Log file name | '*STDOUT' | '*STDERR'
				# *STDERR by default if( '' or undef )
use constant LOGSTACK => 500;   # Length of trace stack. 0 - Trace is off
use constant CHARSET  => 'utf-8'; # Default charset
use constant TEMPLATES_DIR => 'templates';
use constant PORT => 5000;
use constant QUEUE_LENGTH => 10;

1;
__END__