open(dd,">BankSlot.dat");
print dd pack("S",45);

$pad="\x00" x 4804;
for($q=0;$q<45;$q++){
print dd pack("IIii",0,20471934,-1,-1).$pad;
}
