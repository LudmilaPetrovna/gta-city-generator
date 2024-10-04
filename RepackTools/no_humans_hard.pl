`rm -r gta3-dst`;
`mkdir gta3-dst`;

`rm -r cutscene-dst`;
`mkdir cutscene-dst`;


# possible not all, as not included "cuts.img"
@human_models=qw/andre army ballas1 ballas2 ballas3 bb bbthin bfori bfost bfybe bfybu bfypro bfyri bfyst bikdrug bikera bikerb bmobar bmocd bmochil bmori bmosec bmost bmotr1 bmyap bmybar bmybe bmyboun bmybu bmycg bmycon bmycr bmydj bmydrug bmymib bmymoun bmypimp bmypol1 bmypol2 bmyri bmyst bmytatt bones cat cdeput cesar claude copgrl1 copgrl2 copgrl3 crogrl1 crogrl2 crogrl3 csher cwfofr cwfohb cwfyfr1 cwfyfr2 cwfyhb cwmofr cwmohb1 cwmohb2 cwmyfr cwmyhb1 cwmyhb2 dnb1 dnb2 dnb3 dnfolc1 dnfolc2 dnfylc dnmolc1 dnmolc2 dnmylc dsher dwayne dwfolc dwfylc1 dwfylc2 dwmolc1 dwmolc2 dwmylc1 dwmylc2 emmet fam1 fam2 fam3 fbi forelli gangrl1 gangrl2 gangrl3 gungrl1 gungrl2 gungrl3 heck1 heck2 hern hfori hfost hfybe hfypro hfyri hfyst hmogar hmori hmost hmybe hmycm hmycr hmydrug hmyri hmyst janitor jethro jizzy kendl laemt1 lafd1 lapd1 lapdm1 lsv1 lsv2 lsv3 lvemt1 lvfd1 lvpd1 lvpdm1 maccer maddogg mafboss maffa maffb male01 mecgrl1 mecgrl2 mecgrl3 mediatr nurgrl1 nurgrl2 nurgrl3 ofori ofost ofyri ofyst ogloc omoboat omokung omonood omori omost omykara omyri omyst paul poolguy psycho pulaski rose ryder ryder2 ryder3 sbfori sbfost sbfypro sbfyri sbfyst sbfystr sbmocd sbmori sbmost sbmotr1 sbmotr2 sbmotr3 sbmycr sbmyri sbmyst sbmytr3 sbmytr4 sfemt1 sffd1 sfpd1 sfpdm1 sfr1 sfr2 sfr3 sfypro shfypro shmycr sindaco smoke smokev smyst smyst2 sofori sofost sofybu sofyri sofyst somobu somori somost somyap somybu somyri somyst suzie swat sweet swfopro swfori swfost swfotr1 swfyri swfyst swfystr swmocd swmori swmost swmotr1 swmotr2 swmotr3 swmotr4 swmotr5 swmycr swmyhp1 swmyhp2 swmyri swmyst tbone tenpen torino triada triadb triboss truth vbfycrp vbfypro vbfyst2 vbmocd vbmybox vbmycr vbmyelv vhfypro vhfyst vhfyst3 vhmycr vhmyelv vimyelv vla1 vla2 vla3 vmaff1 vmaff2 vmaff3 vmaff4 vwfycrp vwfypr1 vwfypro vwfyst1 vwfywa2 vwfywai vwmotr1 vwmotr2 vwmyap vwmybjd vwmybox vwmycd vwmycr wbdyg1 wbdyg2 wfori wfost wfybe wfybu wfyburg wfyclot wfycrk wfycrp wfyjg wfylg wfypro wfyri wfyro wfysex wfyst wfystew wmoice wmomib wmopj wmoprea wmori wmosci wmost wmotr1 wmotrm1 wmotrm2 wmyammo wmybar wmybe wmybell wmybmx wmyboun wmybp wmybu wmycd1 wmycd2 wmych wmyclot wmycon wmyconb wmycr wmydrug wmygol1 wmygol2 wmyjg wmykara wmylg wmymech wmymoun wmypizz wmyplt wmyri wmyro wmysgrd wmyst wmyva wmyva2 wuzimu zero/;
@player_models=qw/player csplay/;

@cutscenes=qw/csbdup csbettina csbfyst csbigbear csbigbear2 csbigbearthin csbjd csblue2 csblue2_2 csblue2_3 csblue2_4 csblue2_5 csblue3 csblue4 csbmybu csbmydj csbogman csbpack csburger1 csburger2 cscatalina cscesar csclaude csconboss csdancea csdanceb csdope csdrug1 csdwayne csemmet csfarlie csgfprox csgrove1 csheadsack csheckler1 csheckler2 cshelper1 cshelper2 cshernandez csho csjanitor csjethro csjizzy csjose cskendl cskentpaul cslilbil csmaccer csmadddogg csmafgoon1_maffa csmafgoon2_maffb csmaria csmech csogloc csoglocburger csom2 csomost csplas1 cspro1 cspulaski cspunter1 cspunter2 csrosenberg csryder cssalvatore cssilverman cssindacco csslut cssmoke cssmokevest cssmokevest2 csstew cssuit2 cssuzie cssweet cstbone cstenpenny cstexan cstexan2 cstony_x cstorino cstriada cstriada2 cstriada3 cstriboss cstruth cswmori cswoozie cszero fam4 fam5 gfriend/;

#@humans=sort grep{/dff/i}`find /dev/shm/humans -iname "*dff"`;
#foreach(@humans){
#if(/([^\/]+)\.dff/){
#$models{$1}++;
#}
#}

#@models=sort keys %models;
#print join(" ",@models)."\n\n";

#156-157 - main character "player"
#54-55 - cut scene player - "csplay"
#splice(@models,55);

$want_model=lc("SHFYPRO");  #prostiture

foreach $model(@human_models){
print "$want_model -> $model\n";
`cp img_unpacked/models/gta3/$want_model.txd gta3-dst/$model.txd`;
`cp img_unpacked/models/gta3/$want_model.dff gta3-dst/$model.dff`;
}


foreach $model(@cutscenes){
print "$want_model -> $model\n";
`cp img_unpacked/models/gta3/$want_model.txd cutscene-dst/$model.txd`;
`cp img_unpacked/models/gta3/$want_model.dff cutscene-dst/$model.dff`;
}


#`perl /dev/shm/packer.pl Dst/Models/gta3.img     img_unpacked/models/gta3/ gta3-dst/`;
#`perl /dev/shm/packer.pl Dst/Models/cutscene.img img_unpacked/models/cutscene cutscene-dst/`;
