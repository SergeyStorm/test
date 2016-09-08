package SergeyStormFindIndex {
	
	sub new {
		my ($class) = @_;
		my $self = {
			'name' => 'SergeyStormFindIndex'
		};
		return bless $self, $class;
	}

	sub find( $$$ ) {
		my (undef, $value, $array_ref) = @_;
		my $ref_type = ref( $array_ref );
		if ( $ref_type eq 'ARRAY' ) {
			@$array_ref = sort { $a <=> $b } @$array_ref;
			my $nearest_idx;
			# Бесконечно большая минимальная разница
			my $min_diff = "inf";
			# Поиск ближайшего по значению элемента
		MEASURE:
			for my $idx ( 0..@$array_ref-1 ) {
				my $diff = abs( @$array_ref[$idx] - $value );
				# Если нет разницы
				if ( $diff == 0 ) {
					$nearest_idx = $idx;
					last MEASURE;
				# Если разница меньше минимальной
				} elsif ( $diff < $min_diff ) {
					$nearest_idx = $idx;
					$min_diff = $diff;
				# Поскольку по условиям задачи массив отсортирован
				# по возрастанию, прерываем поиск после того как
				# значения начали расти относительно максимально близких.
				} elsif ( $min_diff < "inf" &&  $diff > $min_diff ) {
					last MEASURE;
				}
			}
			return ($nearest_idx, $nearest_idx+1);
		} else {
			print "Параметр не является ссылкой на массив.\n";
			return undef;
		}
		return undef;
	}
};

1;
