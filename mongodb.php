<?php
	print("PHP PROGRAM\n");
	# Configuration
	$mongo=new MongoClient();
	$db=$mongo->selectDB("test");
	$colname="mongo_declaraimp2013";
	# Consultando registros 
	$milini = round(microtime(true) * 1000);
	print ("Realizando Consulta......\n");
	$collection=$db->$colname;
	//$conditions=array("id_capitulo"=>array('$in'=>array('30','12','21','90','63')));
	//$conditions=array("id_capitulo"=>array('$in'=>array('50','62','71','09','80')));
	//$conditions=array("id_capitulo"=>array('$in'=>array('70','45','67','33','21')));
	$conditions=array("id_capitulo"=>array('$in'=>array('32','12','07','90','64','35')));
	//$conditions=array("id_capitulo"=>array('$in'=>array('60','61','62','63','64','65')));
	//$conditions=array("id_capitulo"=>array('$in'=>array('70','71','72','73','74','75')));
	//$conditions=array("id_capitulo"=>array('$in'=>array('80','81','82','83','84','85')));

	$cursor=$collection->find($conditions)->limit(30);
	$miltotal=(round(microtime(true) * 1000) - $milini)/1000;
	print (" TIME: $miltotal\n");
	# Contando registros con la funcion count de mongo
	/*$milini = round(microtime(true) * 1000);
	print ("Ejecutando count() mongo......\n");
	print (" TOTAL RECORDS: ".$cursor->count());
	$miltotal=(round(microtime(true) * 1000) - $milini)/1000;
	print (" TIME: $miltotal\n");

	# Explicando consulta de mongo
	$milini = round(microtime(true) * 1000);
	print ("Ejecutando explain() mongo......\n");
	print_r ($cursor->explain());
	$miltotal=(round(microtime(true) * 1000) - $milini)/1000;
	print (" TIME: $miltotal\n");*/

	# Contando registros recorriendo el cursor mongo con foreach
	/*$milini = round(microtime(true) * 1000);
	print("Contando registros con php......\n");
	$limit=10;
	$i=0;
	foreach ($cursor as $cur) $i++;
	$miltotal=(round(microtime(true) * 1000) - $milini)/1000;
	# Printing resume
	print (" TOTAL RECORDS: $i");
	print (" TIME: $miltotal\n");*/

	# Contando registros recorriendo el cursor mongo con hasNext
	$milini = round(microtime(true) * 1000);
	print("Contando registros con php (hasNext)......\n");
	$cursor=$collection->find($conditions);
	$limit=10;
	$i=0;
	while($cursor->hasNext())
	{
		var_dump($cursor->getNext());
		$cursor->next();
		$i++;
	}
	$miltotal=(round(microtime(true) * 1000) - $milini)/1000;

	# Printing resume
	print (" TOTAL RECORDS: $i");
	print (" TIME: $miltotal\n");
	//print ("TIME:".date("i:s",$ttotal)."\n");
	print ("Exit!\n");

?>
