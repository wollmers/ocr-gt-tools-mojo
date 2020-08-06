package Wocr::Corr;
use Mojo::Base 'Mojolicious::Controller';

# https://perlmaven.com/how-to-remove-copy-or-rename-a-file-with-perl
# unlink $file or warn "Could not unlink $file: $!";
use File::Copy qw(move);

use XML::Twig;

my $xml                = {};
my $Page_imageFilename = '';

sub index {
    my $self = shift;

    my $line = $self->param('line');

    my $next_corr_line = '';

    #'corr_dir' => '/Users/helmut/github/ocr-hw/ocr-gt-AustrianNewspapers-scripts/corr/',
    my $corr_dir = $self->stash->{'config'}->{'ocr'}->{'corr_dir'};

    opendir(my $dir_dh, "$corr_dir") || die "Can't opendir $corr_dir: $!";
    my @files
        = sort grep { /^[^._]/ && /\.gt\.txt$/i && -f "$corr_dir/$_" } readdir($dir_dh);
    closedir $dir_dh;

    unless ($line) {
        if (@files >= 1) {
            $line = $files[0];
        }
    }
FILE: for my $file (@files) {
        if ($file && $file ne $line) {
            $next_corr_line = $file;
            last FILE;
        }
    }

    #/Users/helmut/github/ocr-gt/AustrianNewspapers/
    my $ocr_basedir = $self->stash->{'config'}->{'ocr'}->{'basedir'};

    my $page = $line;
    $page =~ s/\.(jpg|tif).*$//i;

    my $book = $page;
    $book =~ s/_\d+$//;    # remove page number

    my $pagedir = '';
    my $lines   = {};

    my $text  = '###not found###';
    my $image = '###not found###';

    $self->stash('_next_line'   => $next_corr_line);
    $self->stash('_book'        => $book);
    $self->stash('_text'        => $text);
    $self->stash('_image'       => $image);
    $self->stash('_pagedir'     => $pagedir);
    $self->stash('_page'        => $page);
    $self->stash('_line'        => $line);
    $self->stash('_ocr_basedir' => $ocr_basedir);

    my $page_image = '';
    for my $dir (keys %{$self->stash->{'config'}->{'ocr'}->{'pages'}}) {
        my $dir_name
            = $ocr_basedir . $self->stash->{'config'}->{'ocr'}->{'pages'}->{$dir};

        if (-f "$dir_name/$page.xml") {
            parse_xml("$dir_name/$page.xml", $lines);
            $pagedir    = $self->stash->{'config'}->{'ocr'}->{'lines'}->{$dir} . "/$page";
            $page_image = $Page_imageFilename;
        }
    } ## end for my $dir (keys %{$self...})

    my $line_number;
    my $line_count = 0;

    # /Users/helmut/github/ocr-gt/AustrianNewspapers/
    #     gt/eval/  ONB_aze_18950706_4/ONB_aze_18950706_4.jpg_tl_1.gt.txt
    # $xml->{$RegionRefIndexed_index}->{$readingOrder} = $TextLine_id;
    for my $RegionRefIndexed_index (sort { $a <=> $b } keys %{$xml}) {
        for my $readingOrder (sort { $a <=> $b } keys %{$xml->{$RegionRefIndexed_index}})
        {
            $line_count++;
            my $TextLine_id    = $xml->{$RegionRefIndexed_index}->{$readingOrder};
            my $text_line_file = $page_image . '_' . $TextLine_id . '.gt.txt';
            $lines->{$line_count} = $text_line_file;
            if ($text_line_file eq $line) { $line_number = $line_count; }
        }
    } ## end for my $RegionRefIndexed_index...

    $image = '/' . $pagedir . '/' . $line;
    $image =~ s/gt\.txt/png/;
    $self->app->log->debug("image: [$image]");
    $self->stash('_image' => $image);

    my $textfile = $ocr_basedir . $image;
    $textfile =~ s/\.png$/.gt.txt/;

    open(my $in, "<:encoding(UTF-8)", $textfile)
        or $self->app->log->debug("cannot open $textfile: $!");

    my $text = <$in>;
    chomp $text;
    close($in);

    $self->stash('_text'         => $text);
    $self->stash('_image_before' => '');
    $self->stash('_line_before'  => '');
    $self->stash('_image_after'  => '');
    $self->stash('_line_after'   => '');

    if (exists $lines->{$line_number - 1}) {
        my $line_before = $lines->{$line_number - 1};

        $self->stash('_line_before' => $line_before);
        my $image_before = '/' . $pagedir . '/' . $line_before;
        $image_before =~ s/gt\.txt/png/;
        $self->stash('_image_before' => $image_before);
    }
    if (exists $lines->{$line_number + 1}) {
        my $line_after = $lines->{$line_number + 1};

        $self->stash('_line_after' => $line_after);
        my $image_after = '/' . $pagedir . '/' . $line_after;
        $image_after =~ s/gt\.txt/png/;
        $self->stash('_image_after' => $image_after);
    }


    # /Users/helmut/github/ocr-gt/AustrianNewspapers/ gt/eval/
    #     ONB_aze_18950706_4/ONB_aze_18950706_4.jpg_tl_1.gt.txt
    #                        ONB_aze_18950706_4.jpg_tl_1.png


    $self->render_not_found unless $self->render(template => "corr_line");
} ## end sub index

# ONB_aze_18950706_1.jpg_line_1545026835683_1.png
# ONB_aze_18950706_1.jpg_line_1545026835683_1.gt.txt

sub change {
    my $self = shift;

    my $line       = $self->param('line');
    my $text       = $self->param('line-text');
    my $line_after = $self->param('next_line');
    my $image      = $self->param('image');

    #/Users/helmut/github/ocr-gt/AustrianNewspapers/
    my $ocr_basedir = $self->stash->{'config'}->{'ocr'}->{'basedir'};

    my $corr_dir = $self->stash->{'config'}->{'ocr'}->{'corr_dir'};

    $self->app->log->debug("line-text: [$text]");

    # /gt/train/ONB_aze_18950706_1/ONB_aze_18950706_1.jpg_tl_52.png
    # image: ONB_aze_18950706_1.jpg_tl_52.gt.txt

    my $oldfile = $ocr_basedir . $image;
    $oldfile =~ s/\.png$/.gt.txt/;

    open(my $in, "<:encoding(UTF-8)", $oldfile)
        or $self->app->log->debug("cannot open $oldfile: $!");

    my $oldtext = <$in>;
    chomp $oldtext;
    close($in);

    $text =~ s/\t+/ /g;
    $text =~ s/\s\s+/ /g;
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;

    if ($oldtext ne $text) {
        my $bakfile = $oldfile . '.bak';
        move $oldfile, $bakfile;

        open(my $out, ">:encoding(UTF-8)", $oldfile)
            or $self->app->log->debug("cannot open $oldfile: $!");

        print $out $text;
        close($out);
    } ## end if ($oldtext ne $text)

    my $corr_file = $corr_dir . $line;

    #unlink $corr_file or warn "Could not unlink $corr_file: $!";
    unlink $corr_file or $self->app->log->debug("Could not unlink $corr_file: $!");

    $self->app->log->debug("redirect_to: [$line_after]");

    if ($line_after) {
        $self->res->code(307);    # Temporary Redirect
        $self->redirect_to('/corr/' . $line_after);
    }
    else {
        $self->res->code(307);    # Temporary Redirect
        $self->redirect_to('/corr/' . $line);
    }
} ## end sub change

# http://127.0.0.1:3000/gt/train/ONB_aze_18950706_1/ONB_aze_18950706_1.jpg_tl_1.gt.txt
# http://127.0.0.1:3000/gt/train/ONB_aze_18950706_1/ONB_aze_18950706_1.jpg_tl_1.png

sub parse_xml {
    my ($xmlfile, $lines) = @_;
    $xml = {};
    my $twig = XML::Twig->new(

        #remove_cdata => 1,
        TwigHandlers => {'/PcGts/Page' => \&parse_page,},
    );
    eval { $twig->parsefile($xmlfile); };

    if ($@) {

        #print STDERR "XML PARSE ERROR: " . $@;
        die "XML PARSE ERROR: " . $@;
    }
    return ($xml);
} ## end sub parse_xml

#<ReadingOrder>
#      <OrderedGroup id="ro_1567004082174" caption="Regions reading order">
#        <RegionRefIndexed index="0" regionRef="r_1_1"/>

sub parse_page {
    my ($twig, $Page) = @_;

    # /PcGts
    # <Page imageFilename="ONB_ibn_18640702_006.tif"

    #my $Page_imageFilename = $Page->att('imageFilename');
    $Page_imageFilename = $Page->att('imageFilename');

    # <ReadingOrder>
    #    <OrderedGroup id="ro_1567004082174" caption="Regions reading order">
    #      <RegionRefIndexed index="0" regionRef="r_1_1"/>

    my $regions = {};

    my $ReadingOrder = $Page->first_child('ReadingOrder');
    my $OrderedGroup = $ReadingOrder->first_child('OrderedGroup');

    my @RegionRefIndexed = $OrderedGroup->children('RegionRefIndexed');
    for my $RegionRefIndexed (@RegionRefIndexed) {
        my $RegionRefIndexed_index = $RegionRefIndexed->att('index');
        my $regionRef              = $RegionRefIndexed->att('regionRef');
        $xml->{$RegionRefIndexed_index} = {};

        #$xml->{'regions'}->{$regionRef} = $RegionRefIndexed_index;
        $regions->{$regionRef} = $RegionRefIndexed_index;
    }

    # <TextRegion type="paragraph" id="r_1_1" custom="readingOrder {index:0;}">
    #      <Coords points="737,35 836,35 836,79 737,79"/>
    #      <TextLine id="tl_1" primaryLanguage="German" custom="readingOrder {index:0;}">

    my @TextRegions = $Page->children('TextRegion');
    for my $TextRegion (@TextRegions) {
        my $RegionRef              = $TextRegion->att('id');
        my $RegionRefIndexed_index = $regions->{$RegionRef};

        #my $textlines = {}; # collect textlines from line_files

        my @TextLines = $TextRegion->children('TextLine');

        for my $TextLine (@TextLines) {

            my $TextLine_id = $TextLine->att('id');
            my $custom      = $TextLine->att('custom');

            my $readingOrder;
            if ($custom =~ m/readingOrder\s*\{\s*index\s*:\s*(\d+)\s*;\s*\}/) {
                $readingOrder = $1;
                $xml->{$RegionRefIndexed_index}->{$readingOrder} = $TextLine_id;
            }
        } ## end for my $TextLine (@TextLines)
    } ## end for my $TextRegion (@TextRegions)
    return 1;
} ## end sub parse_page

1;
