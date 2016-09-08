#!/usr/bin/perl

our $n = 11;
our $length = $n*$n;

our $field = [];

our %point = (x => $n, y => 1);
our %vector = (x => 0, y => 1);

sub rotate {
    my %vector = (x => $_[0], y => $_[1]);
    my %tvector;
    $tvector{x} = $vector{y} * -1;
    $tvector{y} = $vector{x};
    return %tvector;
}

# Fill margins;

for(my $x=0;$x<=($n+1);$x++) {
    $field->[$x][0] = 0;
    $field->[$x][$n+1] = 0;
    $field->[0][$x] = 0;
    $field->[$n+1][$x] = 0;
}

for (my $step=1;$step<=$length;$step++) {
    $field->[$point{y}][$point{x}] = $step;
    my %tpoint = (x => $point{x}+$vector{x},
		y => $point{y}+$vector{y});
    if (defined $field->[$tpoint{y}][$tpoint{x}]) { %vector = rotate($vector{x}, $vector{y}) }
    $point{x} += $vector{x};
    $point{y} += $vector{y};
}

# print out the field

sub align {
# string, width, space
    if ($_[1] eq 0) { return "#" }
    if (length($_[0]) eq $_[1]) { return $_[0] }
    if (length($_[0]) gt $_[1]) {
		if ($_[1] eq 1) { return "#" }
		if ($_[1] ge 3) { return subsrt($_[0],0,$_[1]-1)."#" }
		if ($_[1] lt 3) { return "#"x$_[1] }
    }
    if (length($_[0]) lt $_[1]) { return $_[0].' 'x($_[1]-length($_[0])) }
}

foreach my $y (@{$field}) {
    my @line = ();
    foreach my $x (@{$y}) {
	my $ch = $x;
	if ($x eq undef) { $ch = '-' }
		push @line, (align($ch, 5));
    }
    $line = join('|', @line);
    print "$line\n";
}
