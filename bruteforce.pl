#!/usr/bin/perl -w

our $debug = 0;

my $alphabet_src = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
my @alphabet = unpack("C*", $alphabet_src);
my $alph_length = scalar @alphabet;
my $pass_length = 3;
my $pass_vars = $alph_length ** $pass_length;
print "Alphabet length is: $alph_length\n";
print "Total number of combinations is: $pass_vars\n";

# Вычисляем, в какую степень числа $1, умещается число $2
sub get_power_of {
	if ($debug >= 1) { print "==> function powerof has reached:\n" }
	my ($base, $num) = @_;
	if ($debug >= 2) { print "\tInput arguments: Base of number $num is $base.\n" }
	my $res = 0;
	my $power = 0;
	while ($res < $num) {
		++$power;
		$res = $base ** $power;
		if ($debug >= 3) { print "\t\tExponentiation result for power $power is $res.\n" }		
	}
	my $func_res = undef;
	if ($power != 0) { $func_res = $power }
	if ($debug >= 2) {
		if (defined $func_res) {
			print "\tThe number $num is in the power of $power for base $base.\n";
		} else {
			print "\tThe power of base $base is undefined.\n";
		}
	}
	if ($debug >= 1) { print "==> function powerof has ended.\n" }
	return $func_res;
}

# кодируем число $1 в текущую систему счисления
sub get_numeral_of {
	if ($debug >= 1) { print "==> function get_number_of has reached\n" }
	my $src_num = $_[0];
	my $divisor = $alph_length;
	my $result = $src_num;
	if ($debug >= 2) { print "\tInput parameters are: Source number: $src_num, Divisor: $divisor\n" }
	if ($debug >= 3) { print "\t\tAlphabet is: $alphabet_src\n" }
	my $step = 0;
	my $output;
	while ($result >= $divisor) {
		my $result_ = int ($result / $divisor);
		$remainder = $result % $divisor;
		$result = $result_;
		$char = chr $alphabet[$remainder];
		if ($debug >= 3) { print "\t\tStep $step: Current result is: $result, remainder is: $remainder ($char)\n" }
		$output .= $char;
		++$step;
	}
	$remainder = $result % $divisor;
	my $last_char = chr $alphabet[$remainder];
	if ($debug >= 3) { print "\t\tStep $step: Current result is: $result, remainder is: $remainder ($last_char)\n" }
	$output .= $last_char;
	$output = reverse $output;
	if ($debug >= 2) { print "\tResult of function is: $output\n" }
	if ($debug >= 1) { print "==> function get_numeral_of has ended\n" }
	return $output;
}

sub app_insign {
	# Добавляем незначащие символы слева
	if (length $_[0] < $pass_length) {
		my $prefix = chr $alphabet[0];
		$prefix x= $pass_length - length $_[0];
		$_[0] = $prefix.$_[0];
	}
	return $_[0];
}

#my $inpar = 17576;
#get_power_of ($alph_length, $inpar);
#get_numeral_of($inpar);

sub bruteforce {
	my $perc_const = 100 / $pass_vars;
	
	for (my $i=0; $i < $pass_vars; $i++) {
		my $prgs = $perc_const * $i;
		my $code = get_numeral_of($i);
		my $int_prgs = int($prgs);
		$code = app_insign($code);
		print "\r$code on step $i + $int_prgs%";
	}
}

#bruteforce;

my $index = 0;
while (my $line = <STDIN>) {
	if ($line =~ /next/i) {
		#if ($debug >= 0) { print "\tNext code requested\n" }
		if ($index <= ($pass_vars-1)) {
			my $code = app_insign(get_numeral_of($index));
			print "$code\n";
			++$index;
		} else {
			print "#end\n";
			last;
		}
	} elsif ($line =~ /stop/i) {
		#if ($debug >= 0) { print "\tBreak requested\n" }
		last;
	}
}
