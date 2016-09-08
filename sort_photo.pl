#!/usr/bin/perl

use strict;
#use locale;
use encoding 'cp866';
use Encode;
use Cwd;
use File::Basename;

# Globals

my $measure_file_name = 'D:\HiFlow\Report\11000\measures.txt';
my $photo_src_root = 'D:\HiFlow\backup\DCIM';
my $photo_dst_root = 'D:\HiFlow\Report\11000';
my $photo_prefix = '(IMGP|DSCF)';
our $all_files_supposed = 0;
our $all_files_actually = 0;
our $measures_processed = 0;
our $measures_with_no_files = 0;

# дата проведения замеров, если undef, при парсинге записи, значит есть ошибка в списке замеров.
my $last_measure_date;

sub photo_basedir {
#	print "Extracting base: $_[0]\n";
	our $dir_number = $_[0];
	my $dir;
	chdir $photo_src_root;
	unless (opendir $dir, $photo_src_root) {
		print "Can't open photo src dir: $!\n";
		return undef();
	}
	while (my $file = readdir $dir) {
#		print "There are files: $file\n";
		if (-d $file && $file =~ /^$dir_number/) {
			my $res = $photo_src_root.'\\'.$file;
#			print "Result is: $res\n";
			return $res;
		}
	}
	return undef();
}

sub is_in_range {
	# call with 'filename' (only) then 'range_min' and then 'range_max' to
	if ($_[0] >= $_[1] && $_[0] <= $_[2]) { return 1 }
	else { return undef() }
}

sub get_file_bynum {
	# call with 'path for search' && 'file_num'
	return (get_files_in_range ($_[0], $_[1], $_[1]));
}

sub get_files_in_range {
	# call with 'path for search' && 'range_min' && 'range_max';
	print "Find files of range in dir: $_[0]\n";
	print "Range is: $_[1] \ $_[2]\n";
	my $lr = $_[1];
	my $hr = $_[2];
	my $path = photo_basedir($_[0]);
#	print "Trying to change the dir to: $path\n";
	unless (chdir $path) {
			print "Can't change to dir $path, because of: $!\n";
			return undef();
		}
	my $dir;
	unless (opendir $dir, $path) {
			print "Can't open directory $path, because of: $!\n";
			return undef();
		}
	my @files = ();
	while (my $file = readdir $dir) {
		if (-f $file) {
			$file =~ /^$photo_prefix(\d+)\..*/;
			if ($_[1] == $_[2]) {
				if ($2 == $_[1]) { 
					push @files, ("$path\\$file")
				};
			} elsif ($2 >= $lr && $2 <= $hr) {
				push @files, ("$path\\$file");
			}
		}
	}
	print "Files of: @files\n";
	return @files;
}

# Loading Measure Data

my $measure_file;
unless (-e $measure_file_name) {
	print "Файл измерений не существует\n"; 
	exit;
}
#print "Открываю файл: $measure_file_name\n";
unless (open $measure_file, "<", $measure_file_name) {
	print "Не могу открыть файл с измерениями: $!\nОстаётся только выйти\n";
	exit;
}
my $mline;
while ($mline = <$measure_file>) {
	chomp $mline;
	our $is_date = undef;
	our $was_error_in_def = undef;
	if ($mline =~ /^\d+\.\d+\.\d+$/) {
		$last_measure_date = $mline;
		$is_date = 1;
		next;
	}
	# Photo directory number;
	my $pdir_number;
	# Photo start & end number (photo numbers range)
	my ($psnumber, $penumber);
	# Line fields
	my @fields = split(/\s+/, $mline);
	my $fieldcnt = @fields;
	# Measure number
	my $measure_number = shift @fields;
	our $field;
	our @files = (); # holds full paths to files that's enumerated in measure line
	our $files_supposed = 0;
	our $files_actually = 0;
	while ($field = shift @fields) {
	# Parse the field
		chomp $field;
		if ($field =~ /^(\d+)-(\d+)$/) {
			$pdir_number = $1;
			$psnumber = $2;
			$all_files_supposed += ++$files_supposed;
			#print "1 files supposed: $files_supposed\n";
			#print "all files supposed: $all_files_supposed\n";
			my @temp = get_file_bynum ($pdir_number, $psnumber);
			if (@temp) {
				$files_actually += @temp;
				push @files, @temp;
			}
		} elsif ($field =~ /^\d+$/) {
			if ($pdir_number eq '') {
				print "Неизвестен номер каталога\nПродолжаю со сделующей записи\n";
				next;
			}
			$psnumber = $field;
			$all_files_supposed += ++$files_supposed;
			#print "2 files supposed: $files_supposed\n";
			#print "all files supposed: $all_files_supposed\n";
			my @temp = get_file_bynum ($pdir_number, $psnumber);
			if (@temp) {
				$files_actually += @temp;
				push @files, @temp;
			}
		} elsif ($field =~ /^\+(\d+)$/) {
			if ($psnumber eq '') { next }
			if ($psnumber > $1) {
				print "Ошибка в определении списка фотографий для этого замера\n";
				$was_error_in_def = 1;
				next;
			}
			$all_files_supposed += $files_supposed += $1-($psnumber-1);
			#print "3 files supposed: $files_supposed\n";
			#print "all files supposed: $all_files_supposed\n";
			print "Getting files in range: $psnumber > $1\n";
			my @temp = get_files_in_range ($pdir_number, $psnumber, $1);
			if (@temp) {
				$files_actually += @temp;
				push @files, @temp;
			}
		}
	#$all_files_supposed += $files_supposed;
	$all_files_actually += $files_actually;
	}
	++$measures_processed;	

	if (!$files_actually && !$is_date) {
		++$measures_with_no_files;
		print "$measure_number -- Для этого замера вообще не найдено фотографий !!!\n";
		print "-------------------\n";
	} elsif ($files_actually != $files_supposed) {
		#my $files = join("\n\t", @files);
		print "$measure_number - для этого замера предполагалось $files_supposed фотографий, но найдено, только $files_actually\n";
		#print "\tВот список найденых файлов, относящихся к этому замеру:\n\t$files\n";
		#print "\t-------------------\n";
	} elsif ($files_actually == $files_supposed) {
		print "$measure_number - OK\n";
	}

	# Creating directories and sort files along it
	if ($is_date) {
		my $path = "$photo_dst_root\\$mline";
		if (!-d $path) {
			print "Каталог по дате ненайден, создаю его\n";
			`mkdir $path`;
		}
	}
	if ($files_actually) {
		my $path = "$photo_dst_root\\$last_measure_date\\$measure_number";
		if (!-d $path) {
			print "Каталог $path не существует, создаю его\n";
			`mkdir $path`;
		}
		# Now copying all files 
		foreach my $file (@files) {
			my $dst_path = $path."\\".fileparse($file);
			`copy /Y $file $dst_path`;
		}
	}
}

close $measure_file;

print "Всего обработано замеров: $measures_processed\n";
print "Предположительно должно быть фотографий: $all_files_supposed\n";
print "Всего найдено фотографий: $all_files_actually\n";
print "Предположительно не хватает: ".($all_files_supposed - $all_files_actually)." фотографий\n";
print "Всего обработано замеров для которых вообще не найдено фотографий: $measures_with_no_files\n";
