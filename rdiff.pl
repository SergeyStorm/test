#!/usr/bin/perl

use locale;
#use strict;
use Cwd;
use File::Find;
use File::Basename;

my $work_dir;
my $orig_snap;
my $out;
my $in;
my $list;
my %analize_list;

if (@ARGV == 0) {
	print "# Как юзать:\n";
	print "#     rdiff.pl Ключ Путь_к_каталогу_с_файлами  Путь_к_списку_оригинальных_файлов\n";
	print "#  Ключ может принимать значения: analize или diff, для первичного анализа и для поиска отличий, соответственно\n";
	print "#  Отсутствие параметров приводит к выоду этого текста\n";
	print "#  Если указан только путь к каталогу для первичного анализа, то список выводится в STDOUT\n";
	print "#  При указании списка проанализированных файлов рабочая информация первого режима сохраняется в него.\n";
	print "#  Или же, из него берутся входные данные для второго режима.\n";
	exit;
} elsif (@ARGV > 0 && @ARGV < 2) {
	print "# Пожалуйста укажите параметры для работы, как минимум, путь к каталогу для анализа\n";
	exit;
} elsif ($ARGV[0] =~ /analize/i) {
	if (@ARGV > 1) {
		print "# Режим первичного анализа\n";
		if ($ARGV[2] eq '') {
			print "# Файл списка не указан, использую STDOUT\n";
			$out = STDOUT;
		} else {
			$out = $ARGV[2];
			print "# Для вывода списка исползую файл: $out\n";
		}
		$work_dir = $ARGV[1];
		generate_list();
	}
} elsif ($ARGV[0] =~ /diff/i) {
	if (@ARGV > 1) {
		print "# Режим поиска отличий\n";
		if ($ARGV[2] eq '') {
			print "# Файл списка не указан, не могу продолжать работу\n";
			exit;
		} else {
			$in = $ARGV[2];
		}
		$work_dir = $ARGV[1];
		$orig_snap = $ARGV[2];
		generate_diff();
	}
}

sub process_file {
	if (!-d $File::Find::name && $File::Find::name ne '.' && $File::Find::name ne '..') {
		my $local_path = $File::Find::name;
		$local_path =~ s/$work_dir//;
		$local_path =~ s/\"/\\\"/;
		#$local_path = '"'.$local_path.'"';
		my ($sum) = split(/ /, `md5sum $File::Find::name`);
		if ($out eq 'HASH') {
			$analize_list{$local_path} = $sum;
			print '#';
		} else {
			print $out "$sum\t$local_path\n";
		}
	}
}

sub generate_list () {
	if (-e $work_dir && -d $work_dir) {
		print "# Видимо, всё в порядке, открываю каталог: $work_dir\n";
	} else {
		print "# Каталог $work_dir не существует или не является каталогом\n";
		exit;
	}
	if ($out ne 'STDOUT' && $out ne 'HASH') {
		unless (open $out, ">", $out) {
			print "# Не могу открыть файло для сохранения списка\n";
			exit;
		}
	}
	find \&process_file, $work_dir;
	unless ($out eq 'STDOUT') {
		close $out;
	}
	print "\n";
}

sub generate_diff () {
	# Просим сохранять список хешированных файлов в хэш :)
	$out = 'HASH';
	# Генерируем список;
	generate_list();
	# Теперь загрузим список, который нам указали
	print "# Открываю файл: $in\n";
	unless (open INFILE, "<", $in) {
		print "# Не могу открыть файл списка :(\n$in\n";
		exit;
	}
	my %in_list;
	my @diff_list;
	my $line;
	while ($line = <INFILE>) {
		chomp $line;
		unless ($line =~ /^#/) {
			my ($sum, $path) = split(/\t/, $line);
			$in_list{$path} = $sum;
		}
	}
	close INFILE;
	my $recs = scalar keys %in_list;
	print "# Прочитано $recs записей\n";
	if ($work_dir !~ /\/$/) { $work_dir .= '/' }
	foreach my $key (keys %analize_list) {
		#print "Source: $in_list{$key}\n";
		#print "Input:  $analize_list{$key}\n";
		if ($analize_list{$key} ne $in_list{$key}) {
			push @diff_list, ("$key");
		}
	}
	my $diffs = scalar @diff_list;
	if ($diffs > 0) {
		print "# Всего найдено отличающихся файлов: $diffs\n";
		my $name = basename $work_dir;
		chomp $name;
		my $arch_name = "/tmp/$name.tar.bz2";
		print "# Я их, пожалуй, затарю в $arch_name\n";
		my $files = join (' ', @diff_list);
		print "# Вот он список отличающихся файлов\n";
		print "@diff_list\n";
		`cd $work_dir; tar -cjvf $arch_name $files`;
	} else {
		print "# Не найдено ни одного отличающегося файла\n";
	}
	print "# Всё.\n";
}

__END__
