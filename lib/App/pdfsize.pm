package App::pdfsize;

use strict;
use warnings;

use App::imgsize ();
use Exporter qw(import);
use File::Temp;
use IPC::System::Options -log=>1, 'system';

# AUTHORITY
# DATE
# DIST
# VERSION

our @EXPORT_OK = qw(pdfsize);

our %SPEC;

$SPEC{pdfsize} = {
    v => 1.1,
    summary => 'Show dimensions of PDF files',
    description => <<'MARKDOWN',

This is basically just a thin wrapper for <prog:imgsize>. It extracts the first
page of a PDF (currently using <prog:pdftk>: `pdftk IN.pdf cat 1 output
/tmp/SOMEOUT.pdf`), then convert the 1-page PDF to JPEG using ImageMagick's
<prog:convert> utility, then run *imgsize* on the JPEG.

MARKDOWN
    args => {
        %{ $App::imgsize::SPEC{imgsize}{args} },
    },
    examples => [
        {
            args => {filenames => ['foo.pdf']},
            result => [200, "OK", '640x480'],
            test => 0,
        },
        {
            args => {filenames => ['foo.pdf'], detail=>1},
            result => [200, "OK", [
                {filename => '/tmp/foo.pdf.jpg', filesize => 23844, width => 640, height => 480, res_name => "VGA"},
            ], $res_meta],
            test => 0,
        },
    ],
    links => [
        {url=>'prog:imgsize'},
    ],
    deps => {
        all => [
            {prog=>'pdftk'},
            {prog=>'convert'},
            {prog=>'imgsize'},
        ],
    },
};
sub pdfsize {
    my %args = @_;

    my @jpg_filenames;
    for my $filename (@{ delete $args{filenames} }) {
        unless (-f $filename) {
            warn "No such file or not a file: $filename, skipped\n";
            next;
        }

        my ($temp1_fh, $temp1_filename) = File::Temp::tempfile("XXXXXXXX", SUFFIX=>".pdf");
        my ($temp2_fh, $temp2_filename) = File::Temp::tempfile("XXXXXXXX", SUFFIX=>".jpg");

        system "pdftk", $filename, "cat", 1, "output", $temp1_filename;
        if ($?) {
            warn "Can't extract first page using pdftk $filename: $!";
            next;
        }

        system "convert", $temp1_filename, $temp2_filename;
        if ($?) {
            warn "Can't convert $temp1_filename to $temp2_filename: $!";
            next;
        }

        push @jpg_filenames, $temp2_filename;
    }

    App::imgsize::imgsize(%args, filenames => \@jpg_filenames);
}

1;
#ABSTRACT:

=head1 SYNOPSIS

 # Use via pdfsize CLI script

=cut
