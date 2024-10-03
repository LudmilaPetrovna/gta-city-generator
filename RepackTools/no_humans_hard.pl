@humans=`find /dev/shm/humans -iname "*dff"`;
$want_model=lc("SHFYPRO");  #prostiture

foreach(@humans){
if(/([^\/]+)\.dff/){
$model=$1;
print "$want_model -> $model\n";
`cp ./gta3-src/$want_model.txd gta3-dst/$model.txd`;
`cp ./gta3-src/$want_model.dff gta3-dst/$model.dff`;
}

}
