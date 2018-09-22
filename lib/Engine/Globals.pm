#
# $Header: /var/lib/cvsd/root/game/lib/Engine/Globals.pm,v 1.1.1.1 2007/02/05 14:42:05 wws Exp $
#
package Engine::Globals;

require Exporter;
@ISA=qw{Exporter};
@EXPORT=qw{SILENT ERROR WARNING TRACE INFO};
@EXPORT_OK=qw{SILENT ERROR WARNING TRACE INFO};

# Debug levels
	use constant	SILENT	=> 0;
	use constant	ERROR	=> 1;
	use constant	WARNING	=> 2;
	use constant	TRACE => 3;
	use constant	INFO => 4;

1;
__END__
