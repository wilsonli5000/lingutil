#!/usr/bin/perl
#
#  Copyright (c) 2009 Ondrej Dusek
#  All rights reserved.
# 
#  Redistribution and use in source and binary forms, with or without modification, 
#  are permitted provided that the following conditions are met:
#  Redistributions of source code must retain the above copyright notice, this list 
#  of conditions and the following disclaimer.
#  Redistributions in binary form must reproduce the above copyright notice, this 
#  list of conditions and the following disclaimer in the documentation and/or other 
#  materials provided with the distribution.
#  Neither the name of Ondrej Dusek nor the names of their contributors may be
#  used to endorse or promote products derived from this software without specific 
#  prior written permission.
# 
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
#  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
#  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
#  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
#  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
#  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
#  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
#  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
#  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
#  OF THE POSSIBILITY OF SUCH DAMAGE.
#

#
# This script collects abbreviation statistics -- i.e. finds words which, even if 
# followed by a space, do not end a sentence. Must be therefore used on some already
# tokenized data with one sentence at a line.
#
# Usage: ./sentrain.pl [file1] [file2] > statistics
# If no file name is given on the command line, the script reads standard input.

use utf8;

binmode( STDIN, ":utf8" );
binmode( STDOUT, ":utf8" );

# projede 1 soubor
# po radcich ulozeni vsech zkratek
sub process_file {

    my $file = $_[0];

    while( <$file> ){

	@wds = split( ' ', $_ );

	for( $i = 0; $i < @wds; ++$i ){

	    # zkratka je neco uprostred radku, za cim zacina veta, tj. zadna
	    # close punctuation apod.
	    if ( $i > 0 && $i < @wds - 1 && !( $wds[$i] cmp "." )
		    && $wds[$i+1] =~ m/^[\p{Letter}\p{Number}]/ ){

		$data{ $wds[$i-1] }++;
	    }
	}
    }
}

# argumenty: soubory se vstupem! 
if ( @ARGV ){
    while( @ARGV ){
	
	open( INPUT, $ARGV[0] );
	binmode( INPUT, ":utf8" );
	process_file( \*INPUT );
	shift( @ARGV );
    }
}
else {
    process_file( \*STDIN );
}

# vytisteni statistik ve formatu "slovo pocet\n"
foreach $value (keys %data){
    print $value . " " . $data{ $value } . "\n";
}
