#!/usr/bin/perl
# Date: 20100826
# By: Jovanny Saravia
# Purpose: Active Records Genearator, taking info from Database
# Field sintaxis for table (def_regexps):
#   Language_code:ExpReg_code:Common_value:Description
#   i.e: 1:2:3:Campo descriptivo de dispositivo
# --------------------
# TODO: Generar arreglo de expresiones regulares para vistas
# --------------------
# 20100830: Adding visuable and editable values, reading info from dbFields.def
# 20100927: Adding commong fields, reading info from dbFields.def
# 20130509: saravia - CHG Se capturan las relaciones de tablas hacia otras BD
# 20130509: saravia - CHG Se deshabilita el llamado a la funcion &visible
# 20130509: saravia - CHG En la tabla debe ir solo el nombre de la tabla y no la BD
# 20130517: fabian - ENG Se adiciona el parametro -s para que tenga en cuenta bd
# 20131008 BUG fabian se adiciona la condicion de opcional '?' al ultimo espacio de la expresion regular. Si ultimo campo no contaba con mas propiedades sino el nombre del campo y el tipo, el programa no tomaba este campo.
# --------------------
require "/data/apache/e-management/v1/cgi/solutions.lib";
&parsing;
$prev="user";
$cur="player";
$prevDir="/data/apache/e-sports/protected/pages/users";
$curDir="/data/apache/e-sports/protected/pages/players";
$recordDir="/data/apache/e-management/protected/database";
$matchfiles="*";
&DBConnect;

sub definitions {
    # Regular Expresions Definitions
    $statement="SELECT id,name,`regexp`,type FROM emanagement.def_regexps";
    &execute;
    while (($id,$name,$regexp,$type)=$sth->fetchrow_array) {
	$regexpdef{$id}{'id'}=$id;
	$regexpdef{$id}{'name'}=$name;
	$regexpdef{$id}{'regexp'}=$regexp;
	$regexpdef{$id}{'type'}=$type;
    }
    # Language Definitions
    $statement="SELECT id,en,sp FROM emanagement.def_field_comments";
    &execute;
    while (($id,$en,$sp)=$sth->fetchrow_array) {
	$langdef{$id}{'id'}=$id;
	$langdef{$id}{'en'}=$en;
	$langdef{$id}{'sp'}=$sp;
	# array user in fieldLocator
	$fieldlocator{$en}{'id'}=$id;
	$fieldlocator{$en}{'en'}=$en;
	$fieldlocator{$en}{'sp'}=$sp;
    }    
}

sub main {
    # Parsing
    #&parsing;
    # Field Comment definitions
    &definitions;
    print "-----------------\n";
    if ($table) {
	$item=$table;
	$option="table";
    } elsif ($view) {
	$item=$view;
	$option="view";
    }
    # read relations between tables or views in core_hierarchy structure
    $hierarchy=&hierarchies($item);
    print "processing : $item\n";
    $recordname="$item"."Record";$recordname=ucfirst($recordname);
    # 1. Reading table/view definitions (ToDo)
    # 2. verifiying table/view
    if ($table) {
	$statement="SHOW TABLES LIKE '$item'";
    } elsif ($view) {
	$statement="describe $item";
    }
    $code=&execute;
    # print "CODE: $code\n";
    if ($code == -1) {
	print " $option specified <$item> doesnt exist. Please verify\n";
	return;
    }
    # for tables or views that exist is necessary to take the info from DB
    # ToDo: for views comments are not captured, it can be done using: 'show full fields from <table>'
    if ($table) {
	$statement="show create $option $item";
    } elsif ($view) {
	$statement="show full fields from $item";	
    }
    $code=&execute;
    if ($code >= 1) {
	# ok: Nothing to do
	# view result
#| Field  | Type        | Collation         | Null | Key | Default | Extra | Privileges                      | Comment                          |
#| id     | int(11)     | NULL              | NO   |     | 0       |       | select,insert,update,references | Id,Id:identificador              |
#	$result="field:$res[0],type:$res[1],comment:$res[2]";
    } elsif ($code==1) {
	# table result
    } elsif ($code != 1) {
	print " error taking info on <$item>, code <$code>. Please verify\n";
	return;
    }
    $contf=$contfk=$contu=0;
    while (@res=$sth->fetchrow_array) {
	if ($table) {
	    $result=$res[1];
	} elsif ($view) {
	    $result="$res[0]<s>$res[1]<s>$res[8]";
	}
	@lines=split(/\n/,$result);
	foreach $line (@lines) {
	    # Table Capture
	    # capturing fields
	    # `snmpwr` varchar(50) COLLATE utf8_spanish_ci NOT NULL ... COMMENT 'Nombre del dispositivo en la red'
	    # Fields commented
	    if ($line=~/^\s+\`(\w+)\`\s+(\S+)\s.*COMMENT \'(.*)\'/) {
		$contf++;
		($field,$type,$en,$sp,$regexp)=&validateId($1,$2,$3);
		# condition to determine if a field is required
		# NOT NULL: Required (r)
		# NULL    : Not Required (n)
		$required=0;
		if ($line=~/NOT NULL/){
		    $required=1;
		} elsif ($line=~/NULL/){
		    $required=0;
		}
		$fields{$contf}{'name'}=$field;$fields{$contf}{'type'}=$type;
		if ($field) {
		    if ($required) {
			$fields{$contf}{'required'}='r';
		    } else {
			$fields{$contf}{'required'}='n';
		    }
		    $fields{$contf}{'regexp'}=$regexp;
		    $fields{$contf}{'comment_en'}=$en;
		    $fields{$contf}{'comment_sp'}=$sp;
		} else {
		    print " warn: field <$3> commented, wrong sintaxis (you should separate with colon(,), i.e: <english,spanish:Description>\n";
#####		    next;
		}
		# Fields uncommented
		# 20131008 BUG fabian se adiciona la condicion de opcional '?' al ultimo espacio de la expresion regular. 
		# 	Si ultimo campo no contaba con mas propiedades sino el nombre del campo y el tipo, el programa no tomaba este campo.
	    } elsif ($line=~/^\s+\`(\w+)\`\s+(\S+)\s?/) {
		$contf++;
		$field=$1;$type=$2;
		($en,$sp)=&fieldLocator($field);
		print " warn: field <$field> must be commented\n";
		# condition to determine if a field is required
		# NOT NULL: Required (r)
		# NULL    : Not Required (n)
		$required=0;
		if ($line=~/NOT NULL/){
		    $required=1;
		} elsif ($line=~/NULL/){
		    $required=0;
		}
		$fields{$contf}{'name'}=$field;$fields{$contf}{'type'}=$type;
		$fields{$contf}{'comment_en'}=$en;
		$fields{$contf}{'comment_sp'}=$sp;
		if ($field) {
		    if ($required) {
			$fields{$contf}{'required'}='r';
		    } else {
			$fields{$contf}{'required'}='n';
		    }
		}
#####		next;
		# Unique Keys
		#   UNIQUE KEY `dnsname` (`dnsname`),
		#   UNIQUE KEY `range` (`range`,`record`)
	    } elsif ($line=~/^\s+UNIQUE\s+KEY\s+\`(\w+)\`\s+\(\`(.*)\`\)/) {
		$contu++;
		$ukey=$2;
		$ukey=~s/\`//g;
		$unique{$contu}{'name'}="$ukey";
		print " UNIQUE: $unique{$contu}{'name'}\n";
		# capturing foreign keys
		# CONSTRAINT `network_devices_ibfk_1` FOREIGN KEY (`rack`) REFERENCES `core_racks` (`id`) ON UPDATE CASCADE,
		# 20130509: saravia - CHG Se capturan las relaciones de tablas hacia otras BD - inicio
	    } elsif ($line=~/^\s+CONSTRAINT\s+\`\w+\`\s+FOREIGN KEY\s+\(\`(\w+)\`\)\s+REFERENCES\s+\`(\w+)\`(\.\`(\w+)\`)?\s+\(\`(\w+)\`\)\s+/) {
		$contfk++;
		$fk{$contfk}{'local'}=$1;
		$fk{$contfk}{'table'}=$2;
		$fk{$contfk}{'table'}.=".$4" if $4;
		$fk{$contfk}{'remote'}=$5;
		# 20130509: saravia - CHG Se capturan las relaciones de tablas hacia otras BD - fin
		# View Capture
		#<CREATE ALGORITHM=UNDEFINED DEFINER=`admin`@`%` SQL SECURITY DEFINER VIEW `view_cmdb_vrf_records` AS select `vrfs`.`id` AS `id`,`rds`.`value` AS `value`,`vrfs`.`range` AS `range`,`vrfs`.`record` AS `record`,`vrfs`.`name` AS `name`,`cli`.`id` AS `client`,`vrfs`.`status` AS `status` from (((`cmdb_rds` `rds` join `core_clients` `cli` on((`cli`.`id` = `rds`.`client`))) join `cmdb_rd_ranges` `ranges` on((`ranges`.`rd` = `rds`.`id`))) join `cmdb_vrfs` `vrfs` on((`vrfs`.`range` = `ranges`.`id`))) where (`rds`.`record_status` = 1) order by `rds`.`value`,`vrfs`.`record`>	    
	    } elsif ($line=~/SQL SECURITY DEFINER VIEW `$view` AS select (.*) from/) {
		# after capture field colon separated, are splitted
		$vl=$1;$vl=~s/[\`]//g;
		@vfields=split(/,/,$vl);
		$contf=0;
		foreach $vf (@vfields) {
		    $contf++;
		    # views could contain ASC in order statement, this should be avoided in split command
		    $vf=~s/ASC/A_S_C/g;
		    ($ref,$field)=split(/AS/,$vf);
		    $field=~s/\s//g;
		    $fields{$contf}{'name'}=$field;
		}
	    #line: id<s>int(11)<s>Id,Id:identificador
	    } elsif ($line=~/^(\w+)<s>(.*)<s>(.*)/) {
			$contf++;
			($field,$type,$en,$sp,$regexp)=&validateId($1,$2,$3);
			$fields{$contf}{'name'}=$field;
			$fields{$contf}{'type'}=$type;
			if ($field) {
			    $fields{$contf}{'regexp'}=$regexp;
			    $fields{$contf}{'comment_en'}=$en;
			    $fields{$contf}{'comment_sp'}=$sp;
			} else {
			    print " warn: field <$3> commented, wrong sintaxis (you should separate with colon(,), i.e: <english,spanish:Description>\n";
	#####		    next;
			}
	    } else {
	       print "line: <$line>\n" if $debug;
	    }
	}
    }
    # open active record file
    $rfile="$recordDir/$recordname.php";
    open(RECORD,">$rfile");
    &ar_definition;
    &ar_fields;
    &ar_unique if $table;
    &ar_relations if $table;
    &ar_finder;
    # read visible fields
    # 20130509: saravia - CHG Se deshabilita el llamado a la funcion &visible - inicio
    ($visible1,$visible2,$editable,$common,$insertable)=&visible($item);
    # 20130509: saravia - CHG Se deshabilita el llamado a la funcion &visible - fin
    # write all fields
    print RECORD $allfields;# if $table;
    # write regexp functions
    print RECORD $regularexp; #if $table;
    # write language functions
    print RECORD $english;# if $table;
    print RECORD $spanish;# if $table;
    # write visible fields
    print RECORD $visible1 if $visible1;
    print RECORD $visible2 if $visible2;
    # write editable fields
    print RECORD $editable if $editable;
    # write common fields
    print RECORD $common if $common;
    # write editable fields
    print RECORD $insertable if $insertable;
    # write hiearchy relations
    print RECORD $hierarchy if $hierarchy;
    # close active record file
    print RECORD "
\}
?>";
    close(RECORD);
    print "end\n";
    print "  generated file: $rfile\n";
}

sub visible {
    my $table=shift;
    my $dbfields="/data/admin/scripts/dbFields.def";
    my @fields;
    my ($field,$visible1,$visible2,$common,$action,$item,$result,$tmp1,$tmp2,$colwidth)='';
    my $editable="\n   public static function editablefields()\n   {\n      return (array(";
    my $insertable="\n   public static function insertfields()\n   {\n      return (array(";
    my ($conte,$contv,$contc)=0;
    my @results=`grep $table $dbfields`;
    foreach $result (@results) {
	chomp($result);
	next unless $result;
	($action,$item,$result)=split(/:/,$result);
	@fields=split(/,/,$result);
	foreach $field (@fields) {
	    next unless $field;
#	    print "FIELD: $field\n";
#	    print "ACTION: $action\n";
#	    print "cont: <$conte> <$contv> <$contc>\n";
	    if ($action eq 'E') {
		($tmp1,$tmp2,$tmp3)=split(/\|/,$field);
		$tmp3=~s/\./,/g;
#		$editable.="\n   public static function editablefields()\n   {\n      return (array(" unless ($conte);
		$editable.="," if $conte;
		$tmp2=ucfirst($tmp2);
		$editable.="'$tmp1'=>array('table'=>'$tmp2','fields'=>'$tmp3')";
		# 'rd'=>'RD'
		$conte++;
	    } elsif ($action eq 'V') {
		$visible1.="\n   public static function visiblefields()\n   {\n      return (array(" unless ($contv);
		$visible2.="\n   public static function visibleWidthfields()\n   {\n      return (array(" unless ($contv);
		$visible1.="," if $contv;
		$visible2.="," if $contv;
		$visible1.="'$field'";
		# Definicion de ancho de columnas
		$colwidth=&columnWidht($TYPE{$field});
		$visible2.="'$field'=>'$colwidth'";
		$contv++;
	    } elsif ($action eq 'C') {
		($tmp1,$tmp2)=split(/\|/,$field);
		$tmp2=~s/\./\',\'/g;
		$common.="\n   public static function commonfields()\n   {\n      return (array(" unless ($contc);
		$common.="," if $contc;
		$common.="'fields'=>array('$tmp2'),'type'=>'$tmp1'";
		$contc++;
	    } elsif ($action eq 'I') {
		# To be defined
	    }
	}
    }
    $visible1.="))\;\n   }\n" if $visible1;
    $visible2.="))\;\n   }\n" if $visible2;
    $editable.="))\;\n   }\n" if $editable;
    $common.="))\;\n   }\n" if $common;
    $insertable.="))\;\n   }\n" if $insertable;
    return ($visible1,$visible2,$editable,$common,$insertable);
}

sub hierarchies {
    my $table=shift;
    my ($childName,$childType,$parentField,$chilField,$parentClick,$recordHandle,$filterValue,$type,$num_rows,$hierarchy)='';
    $statement="SELECT hb2.name,hbt.name,h.parent_relation_field,h.child_relation_field,h.parent_click_field,h.record_handle,h.filter_value,h.type
FROM emanagement.core_hierarchy_branches hb1
INNER JOIN emanagement.core_hierarchies h ON hb1.id=h.parent AND hb1.name='$table'
INNER JOIN emanagement.core_hierarchy_branches hb2 ON hb2.id=h.child
INNER JOIN emanagement.core_hierarchy_branch_types hbt ON hbt.id=hb2.type";
    &execute;
    $num_rows=$sth->rows;
    if ($num_rows) {
	print " were found $num_rows hiearchy relations\n";
	$hierarchy="\n   public static function actionsfields()
   {
      return (array(";  
	my $cont=0;
	while (($childName,$childType,$parentField,$chilField,$parentClick,$recordHandle,$filterValue,$type)=$sth->fetchrow_array) {
	    print " hierarchy relations: $table($parentField) --> $childType: $childName($chilField)\n";
	    $childName=ucfirst($childName);
	    $hierarchy.="," if $cont;
	    $hierarchy.="'$parentClick'=>array('$childName','$childType','$parentField','$chilField','$recordHandle','$filterValue','$type')";
	    $cont++;
	}
	$hierarchy.="))\;\n   }\n";
    }
    return $hierarchy;
}

sub ar_definition {
    print RECORD "<?php
// file generate automatically $date, please dont edit\n
class $recordname extends TActiveRecord
\{
   // $option definition
   const TABLE='$database\.$item'\;\n
   // Fields definition\n";
}

sub ar_fields {
    # print regexp fields
    # regexp
    $regularexp="\n   public static function regularexpre() 
   {
      return (array(";
    # print language fields
    # english
    $english="\n   public static function fields_en() 
   {
      return (array(";
    # spanish
    $spanish="\n   public static function fields_sp()
   {
      return (array(";  
    # all fields
    $allfields="\n   public static function allfields()
   {
      return (array(";
    $cont=0;
    foreach $key (sort {$a <=> $b} %fields) {
	$cont++;
	next unless ($fields{$cont}{name});
	print " Fields:\n" if ($cont==1);
	# print "  KEY: $key";
	print "  NAME: $fields{$cont}{name}";
	if ($fields{$cont}{type}) {
	    print " TYPE: $fields{$cont}{type}";
	    # se define en %type el tipo de valor para cada campo
	    $TYPE{$fields{$cont}{name}}=$fields{$cont}{type};
	}
	print " EN: $fields{$cont}{comment_en}" if ($fields{$cont}{comment_en});
	print " SP: $fields{$cont}{comment_sp}" if ($fields{$cont}{comment_sp});
	print "\n";
	# write public fields
	print RECORD "   public \$$fields{$cont}{name}\;\n";
	# pre-write language functions
	if ($cont==1) {
	    $regularexp.="'$fields{$cont}{name}'=>array('$fields{$cont}{required}','$fields{$cont}{regexp}')";
	    $english.="'$fields{$cont}{name}'=>'$fields{$cont}{comment_en}'";
	    $spanish.="'$fields{$cont}{name}'=>'$fields{$cont}{comment_sp}'";
	    $allfields.="'$fields{$cont}{name}'";
	} else {
	    $regularexp.=",'$fields{$cont}{name}'=>array('$fields{$cont}{required}','$fields{$cont}{regexp}')";
	    $english.=",'$fields{$cont}{name}'=>'$fields{$cont}{comment_en}'";
	    $spanish.=",'$fields{$cont}{name}'=>'$fields{$cont}{comment_sp}'";
	    $allfields.=",'$fields{$cont}{name}'";
	}
    }
    $regularexp.="))\;\n   }\n";
    $english.="))\;\n   }\n";
    $spanish.="))\;\n   }\n";
    $allfields.="))\;\n   }\n";
}

sub ar_unique {
    # print unique keys
    $cont=0;
    foreach $key (%unique) {
	$cont++;
	next unless ($unique{$cont}{name});
	if ($cont==1) {
	    $uniquefields="\n   // Unique Keys Function\n   public static function unicskeys()\n   {\n      return (array(";
	    $uniquefields.="'$unique{$cont}{name}'";
	    $flagunique=1;
	} else {
	    $uniquefields.=",'$unique{$cont}{name}'";
	}
    }
    if ($flagunique) {
	$uniquefields.="))\;\n   }\n";
	print RECORD $uniquefields;
    }
}

sub ar_relations {
    # print foreign keys (relations)
    @relations=();
    $cont=0;
    foreach $key (sort {$a <=> $b} %fk) {
	$cont++;
	next unless ($fk{$cont}{table});
	# 20130509: saravia - CHG En la tabla debe ir solo el nombre de la tabla y no la BD - inicio
	if ($fk{$cont}{table}=~/\w+\.(\w+)/) {
	    $fk{$cont}{table}=$1;
	}
	# 20130509: saravia - CHG En la tabla debe ir solo el nombre de la tabla y no la BD - fin
	$remotetable=ucfirst($fk{$cont}{table});	
	if ($cont==1) {
	    print " Relations:\n";
	    print RECORD "\n   public static \$RELATIONS=array\n";
	    print RECORD "   (\n";
	    $flagrelations=1;
	    $fieldsfks="\n   // Field to print for relationated table\n   public static function fieldsfks()\n   {\n      return (array(";
	    # ToDo: depending on table field name must be changed (exceptions handle)
	    $fieldsfks.="'$fk{$cont}{local}'=>'name'";
	    $activerecordrelations="\n   // Active Records relationated\n   public static function relationsbetweenAr()\n   {\n      return (array(";
	    $activerecordrelations.="'$fk{$cont}{local}'=>'".$remotetable."Record'";
	} else {
	    $fieldsfks.=",'$fk{$cont}{local}'=>'name'";
	    $activerecordrelations.=",'$fk{$cont}{local}'=>'".$remotetable."Record'";
	}
	print "  LOCAL: $fk{$cont}{local}";
	print " TABLE: $fk{$cont}{table}";
	print " REMOTE: $fk{$cont}{remote}";
	print "\n";
	# write relations
	push(@tablerelations,$fk{$cont}{local});
	#$name=ucfirst($fk{$cont}{local});
	$name=$fk{$cont}{local};
	print RECORD "      '$name' => array(self::BELONGS_TO, '$remotetable"."Record', '$fk{$cont}{local}'),\n";
	# store relations in array @relations
	$fksrelation="with$name()";
	push(@relations,$fksrelation);
    }
    if ($flagrelations) {
	$fieldsfks.="))\;\n   }\n";
	$activerecordrelations.="))\;\n   }\n";
	print RECORD "   )\;\n";
    }
}

sub ar_finder {
    # write finder generic class
    print RECORD "
   public static function finder(\$className=__CLASS__)
   {
      return parent::finder(\$className);
   }\n";
    # write finderfks generic class
    @relationsfk=@relations;
    push(@relationsfk,'findAll()');
    $relations=join('->',@relationsfk);
    print RECORD "
   public static function finderfks()
   {
      return ("."$recordname"."::finder()->$relations);
   }\n";
    # write finderfks criteria class
    @relationsfkc=@relations;
    push(@relationsfkc,'findAll($criteria)');
    $relations=join('->',@relationsfkc);
    print RECORD "
   public static function finderfkscriteria(\$condicion,\$arregloparams)
   {    
      \$criteria=new TActiveRecordCriteria;
      \$criteria->Condition = \$condicion;
      foreach (\$arregloparams as \$campo=>\$valor)
         \$criteria->Parameters[\$campo]=\$valor;
      return ("."$recordname"."::finder()->$relations);
   }\n";
    # write field to lookup in others tables
    if ($flagrelations) {
	print RECORD $fieldsfks;
	print RECORD $activerecordrelations;
    }
}

sub validateId {
    my ($field,$type,$comment)=@_;
    $en='empty';
    $sp='vacio';
    $regexp='none';
    $tmpcomment='';
    $langId,$regexpId,$commonId='';
    ($langId,$regexpId,$commonId)=split(/:/,$comment) if ($comment=~/:/);
    unless ($langId) {
	# If not ID was found for languages, it will be matched by field name
	($en,$sp)=&fieldLocator($field);
	print " warn: field <$field> has not language ID defined in <$comment>, i.e: <1:1:1:ID information>\n" if ($en eq 'empty' or $sp eq 'vacio');
	return ($field,$type,$en,$sp,$regexp);
    }
    unless ($regexpId) {
	print " warn: field <$field> has not Regular Expression ID defined in <$comment>, i.e: <1:1:1:ID information>\n";
	return ($field,$type,$en,$sp,$regexp);
    }
    if ($commonId eq '') {
	($en,$sp)=&fieldLocator($field);
	print " warn: field <$field> has not Common ID defined in <$comment>, i.e: <1:1:1:ID information>\n" if ($en eq 'empty' or $sp eq 'vacio');
	return ($field,$type,$en,$sp,$regexp);
    }
    # Language Definitions
    $en=$langdef{$langId}{en} if ($langdef{$langId}{en});
    $sp=$langdef{$langId}{sp} if $langdef{$langId}{sp};
    # Regular Express Definitions
    $regexp=$regexpdef{$regexpId}{regexp} if $regexpdef{$regexpId}{regexp};
    if ($en && $sp) {
	return ($field,$type,$en,$sp,$regexp);
    } else {
	return ($field,$type,$en,$sp,$regexp);
    }
}

sub fieldLocator {
    my $field=shift;
    $field=ucfirst($field);
    if (exists($fieldlocator{$field}{'en'})) {
	return ($fieldlocator{$field}{en},$fieldlocator{$field}{sp});
    } else {
	return ($field,$field);
    }
}

sub columnWidht {
    my $type=shift;
    my $width='';
    if ($type=~/varchar\((\d+)\)/) {
	$width=250;
    } else {
	$width=60;
    }
}
sub parsing {
    $args="";
    $database="emanagement";
    $flagtable=$flagview=$flagdb=0;
    &usage unless (@ARGV);

    foreach $arg (@ARGV) 
    {
	if ($tablearg) {
	    $tablearg=0;
	    if ($arg=~/^(\w+)$/) {
		$table=$1;
		$args.=" $arg";
	    } else {
		&usage;
	    }
	} elsif ($viewarg) {
	    $viewarg=0;
	    if ($arg=~/^(\w+)$/) {
		$view=$1;
		$args.=" $arg";
	    } else {
		&usage;
	    }	    
	}
	elsif($flagdb){
	   $flagdb=0;
	   $database=$arg;
	} 
	elsif ($arg eq '-d') {
            $debug=1;
        } elsif ($arg eq '-v') {
	    $flagview=1;	    
	    $viewarg=1;
	    $args.=" $arg";	    
        } elsif ($arg eq '-t') {
	    $flagtable=1;
	    $tablearg=1;
	    $args.=" $arg";
        }
	elsif ($arg eq '-s')
	{
	    $flagdb=1;
	    $args.=" $arg";
	} 
	else {
            &usage;
	}
    }

    if ($flagtable) {
	&usage("please choose a table") unless $table;
    } elsif ($flagview) {
	&usage("please choose a view") unless $view;
    }
    else {
	&usage("please choose a table or view");
    }

    if ($flagdb) {
	&usage("please write the database name");
    } 
}

sub usage {
    my $msg = shift;
    print "\n$msg\n" if $msg;
    
    print "
usage: activerecords.pl [options]

      Options:
      -d     debug
      -t     table name
      -v     view name
      -s     database name

";
    exit;
}
