// Configuration
print("JAVASCRIPT PROGRAM\n")
conn=new Mongo();
db=conn.getDB("test");

var tiempo_inicio=0;
var tiempo_fin=0;
var tiempo_total=0;

// Consultando Registros
tiempo_inicio=microtime_float();
print ("Realizando Consulta......");
var params={id_capitulo:{$in:['80','70','60','50','40','20']}};
var doc=db.mongo_declaraimp2013.find(params);
tiempo_fin=microtime_float();
tiempo_total=tiempo_fin - tiempo_inicio;
print (" TIME: "+ tiempo_total+"\n");

// Contando registros con la funcion count de mongo
tiempo_inicio=microtime_float();
print ("Ejecutando count() mongo......");
print(" TOTAL RECORDS: "+doc.count());
tiempo_fin = microtime_float();
tiempo_total = tiempo_fin - tiempo_inicio;
print (" TIME: "+ tiempo_total+"\n");

// Explicando consulta de mongo
tiempo_inicio=microtime_float();
print ("Realizando explain() mongo......");
//printjson(doc.explain());
tiempo_fin = microtime_float();
tiempo_total = tiempo_fin - tiempo_inicio;
print (" TIME: "+ tiempo_total+"\n");

// Contando registros recorriendo el cursor mongo
tiempo_inicio=microtime_float();
print ("Contando registros con JS......");
var i=0;
while(doc.hasNext())
{
  doc.next();
  i++;
}
print(" TOTAL RECORDS: "+i);
tiempo_fin = microtime_float();
tiempo_total = tiempo_fin - tiempo_inicio;
print (" TIME: "+ tiempo_total+"\n");

function microtime_float()
{
    var time = microtime();
	var arr = time.split(" ");
    return (parseFloat(arr[0]) + parseFloat(arr[1]));
}

function microtime(get_as_float) {
  //  discuss at: http://phpjs.org/functions/microtime/
  // original by: Paulo Freitas
  //   example 1: timeStamp = microtime(true);
  //   example 1: timeStamp > 1000000000 && timeStamp < 2000000000
  //   returns 1: true

  var now = new Date().getTime() / 1000;
  var s = parseInt(now, 10);

  return (get_as_float) ? now : (Math.round((now - s) * 1000) / 1000) + ' ' + s;
}
