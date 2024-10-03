`rm -r gta3-dst`;
`mkdir gta3-dst`;

# possible not all, as not included "cuts.img"
@human_models=qw/andre army ballas1 ballas2 ballas3 bb bbthin bfori bfost bfybe bfybu bfypro bfyri bfyst bikdrug bikera bikerb bmobar bmocd bmochil bmori bmosec bmost bmotr1 bmyap bmybar bmybe bmyboun bmybu bmycg bmycon bmycr bmydj bmydrug bmymib bmymoun bmypimp bmypol1 bmypol2 bmyri bmyst bmytatt bones cat cdeput cesar claude copgrl1 copgrl2 copgrl3 crogrl1 crogrl2 crogrl3 csher csplay cwfofr cwfohb cwfyfr1 cwfyfr2 cwfyhb cwmofr cwmohb1 cwmohb2 cwmyfr cwmyhb1 cwmyhb2 dnb1 dnb2 dnb3 dnfolc1 dnfolc2 dnfylc dnmolc1 dnmolc2 dnmylc dsher dwayne dwfolc dwfylc1 dwfylc2 dwmolc1 dwmolc2 dwmylc1 dwmylc2 emmet fam1 fam2 fam3 fbi forelli gangrl1 gangrl2 gangrl3 gungrl1 gungrl2 gungrl3 heck1 heck2 hern hfori hfost hfybe hfypro hfyri hfyst hmogar hmori hmost hmybe hmycm hmycr hmydrug hmyri hmyst janitor jethro jizzy kendl laemt1 lafd1 lapd1 lapdm1 lsv1 lsv2 lsv3 lvemt1 lvfd1 lvpd1 lvpdm1 maccer maddogg mafboss maffa maffb male01 mecgrl1 mecgrl2 mecgrl3 mediatr nurgrl1 nurgrl2 nurgrl3 ofori ofost ofyri ofyst ogloc omoboat omokung omonood omori omost omykara omyri omyst paul player poolguy psycho pulaski rose ryder ryder2 ryder3 sbfori sbfost sbfypro sbfyri sbfyst sbfystr sbmocd sbmori sbmost sbmotr1 sbmotr2 sbmotr3 sbmycr sbmyri sbmyst sbmytr3 sbmytr4 sfemt1 sffd1 sfpd1 sfpdm1 sfr1 sfr2 sfr3 sfypro shfypro shmycr sindaco smoke smokev smyst smyst2 sofori sofost sofybu sofyri sofyst somobu somori somost somyap somybu somyri somyst suzie swat sweet swfopro swfori swfost swfotr1 swfyri swfyst swfystr swmocd swmori swmost swmotr1 swmotr2 swmotr3 swmotr4 swmotr5 swmycr swmyhp1 swmyhp2 swmyri swmyst tbone tenpen torino triada triadb triboss truth vbfycrp vbfypro vbfyst2 vbmocd vbmybox vbmycr vbmyelv vhfypro vhfyst vhfyst3 vhmycr vhmyelv vimyelv vla1 vla2 vla3 vmaff1 vmaff2 vmaff3 vmaff4 vwfycrp vwfypr1 vwfypro vwfyst1 vwfywa2 vwfywai vwmotr1 vwmotr2 vwmyap vwmybjd vwmybox vwmycd vwmycr wbdyg1 wbdyg2 wfori wfost wfybe wfybu wfyburg wfyclot wfycrk wfycrp wfyjg wfylg wfypro wfyri wfyro wfysex wfyst wfystew wmoice wmomib wmopj wmoprea wmori wmosci wmost wmotr1 wmotrm1 wmotrm2 wmyammo wmybar wmybe wmybell wmybmx wmyboun wmybp wmybu wmycd1 wmycd2 wmych wmyclot wmycon wmyconb wmycr wmydrug wmygol1 wmygol2 wmyjg wmykara wmylg wmymech wmymoun wmypizz wmyplt wmyri wmyro wmysgrd wmyst wmyva wmyva2 wuzimu zero/;
@player_models=qw/player csplay/;

@humans=sort grep{/dff/i}`find /dev/shm/humans -iname "*dff"`;
foreach(@humans){
if(/([^\/]+)\.dff/){
$models{$1}++;
}
}

@models=sort keys %models;
print join(" ",@models)."\n\n";

#156-157 - main character "player"
#54-55 - cut scene player - "csplay"
splice(@models,55);

$want_model=lc("SHFYPRO");  #prostiture

foreach $model(@models){
print "$want_model -> $model\n";
`cp ./gta3-src/$want_model.txd gta3-dst/$model.txd`;
`cp ./gta3-src/$want_model.dff gta3-dst/$model.dff`;

}