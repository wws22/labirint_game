#!/usr/local/bin/perl
#print "HTTP/1.0 200 OK\n";
$cooky=$ENV{'HTTP_COOKIE'};
$cooky=~s/(\s*)//g;
@cookieArray=split(/;/, $cooky);
foreach  $i (@cookieArray) {
	($CookieArrayRowFirst, $CookieArrayRowSecond)=split(/=/, $i);
	$COOKIE{$CookieArrayRowFirst}=$CookieArrayRowSecond;
}
$COOKIE{'samcookie'}=$COOKIE{'samcookie'}+1;
print "Set-cookie: samcookie = $COOKIE{'samcookie'}\n";
print "Content-Type: text/html\n\n";
 
print "<html><head><title>New Page 2</title>";
print "<meta name=\"GENERATOR\" content=\"Microsoft FrontPage 3.0\">";
print "</head><body><p align=\"center\">&nbsp;</p>\n";
print "<p align=\"center\"><big><big><font color=\"#FF0000\">\n";
print "WELCOME TO PERL!</font></big></big></p>";
print "<p>";
print "$PATH_INFO";
print "</p>";
foreach my $envkey (%ENV)
{
	print "<p>$envkey</p>";
}

read(STDIN, $poststring , $ENV{'CONTENT_LENGTH'});
print "$poststring";
print "<p align=\"center\">&nbsp;</p>";
print "</body></html>";
__END__

