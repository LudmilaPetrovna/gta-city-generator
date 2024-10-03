`rm -r gta3-dst`;
`mkdir gta3-dst`;

$want_model="rhino";
@models=qw/landstal bravura buffalo linerun peren sentinel firetruk trash stretch manana infernus voodoo pony mule cheetah ambulan moonbeam esperant taxi washing bobcat mrwhoop bfinject premier enforcer securica banshee bus rhino barracks hotknife previon coach cabbie stallion rumpo rcbandit romero packer admiral turismo flatbed yankee caddy solair topfun glendale oceanic patriot hermes sabre zr350 walton regina comet burrito camper baggage dozer rancher fbiranch virgo greenwoo hotring sandking blistac boxville benson mesa hotrina hotrinb bloodra rnchlure supergt elegant journey petro rdtrain nebula majestic buccanee cement towtruck fortune cadrona fbitruck willard forklift tractor combine feltzer remingtn slamvan blade vincent bullet clover sadler firela hustler intruder primo tampa sunrise merit utility yosemite windsor uranus jester sultan stratum elegy rctiger flash tahoma savanna bandito kart mower sweeper broadway tornado dft30 huntley stafford newsvan tug emperor euros hotdog club rccam copcarla copcarsf copcarvg copcarru picador swatvan alpha phoenix glenshit sadlshit boxburg/;

#push(@models,qw/pizzaboy pcj600 faggio freeway sanchez bike mtbike fcr900 nrg500 copbike bf400 wayfarer/);
#push(@models,qw/bmx bike mtbike/);
push(@models,qw/artict1 artict2 petrotr artict3 bagboxa bagboxb tugstair farmtr1 utiltr1/);
push(@models,qw/tram rdtrain freight streak freiflat streakc freibox/);


foreach $model(@models){
print "$want_model -> $model\n";
`cp ./gta3-src/$want_model.txd gta3-dst/$model.txd`;
`cp ./gta3-src/$want_model.dff gta3-dst/$model.dff`;

}
