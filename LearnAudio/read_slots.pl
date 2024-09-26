open(dd,"BankSlot.dat");
read(dd,$num_slots,2);

$num_slots=unpack("S",$num_slots);

$slot_size=4820;

while(!eof(dd)){
read(dd,$slot_data,$slot_size);

($offset,$size,$unk1,$unk2)=unpack("IIii",$slot_data);
print "($offset,$size,$unk1,$unk2)\n";


}