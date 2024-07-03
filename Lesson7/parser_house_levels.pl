
@files=`find -iname "index.html"`;

foreach $filename(@files){
chomp($filename);

$slashcount=($filename=~tr/\//\//);
if($slashcount!=4){next;}

open(dd,$filename);
read(dd,$file,-s(dd));
close(dd);

$levels=-1;
$addr="Nowhere";

foreach(split(/list__field\">/s,$file)){

if(/div class=\"list__field__name\">Наибольшее количество этажей[^>]+>\s*<div class=\"list__field__value\">\s*(.+?)<span/s){
$levels=$1;
$levels=~s/<[^>]+>//gs;
$levels=~s/\D+//gs;
}

if(/div class=\"list__field__name\">Адрес[^>]+>\s*<div class=\"list__field__value\">\s*(.+?)<span/s){
$addr=$1;
$addr=~s/<[^>]+>//gs;
}

}


if($levels<1){next;}

#424019, Респ Марий Эл, г Йошкар-Ола, ул Анникова, д. 12В
$addr=~s/(^\d{6}, )?Респ\.? Марий Эл, г\.? Йошкар-Ола, //gs;
$addr=~s/(^| )(ул\.?|улица|пр-кт\.?|проспект|проезд|пл\.?|площадь|наб\.?|набережная|пер\.?|переулок|тракт|бульвар)\s+//gs;
$addr=~s/, д\.\s+(\d+)/, house \1/gs;

print "$addr=$levels\n";

}


