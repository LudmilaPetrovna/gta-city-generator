
=pod
* interfaces:
cld_create() - create new file and shit header in it
cld_VBO(@vertex) - fills new vertex array
cld_normals(@normals) - fills new normals array (must be same size as vertex?)
cld_UV(@UV) - fills texels info
cld_mesh(@verts_and_normals_idx) - fills mesh
cld_finish() - MGIMO FINISH!
=cut

sub cld_create{

open(oo,">test.dae");
print oo <<CODE;
<?xml version="1.0" encoding="utf-8"?>
<COLLADA xmlns="http://www.collada.org/2005/11/COLLADASchema" version="1.4.1">
  <asset>
    <contributor>
      <author></author>
      <authoring_tool>FBX COLLADA exporter</authoring_tool>
      <comments></comments>
    </contributor>
    <created>2024-10-28T10:12:36Z</created>
    <keywords></keywords>
    <modified>2024-10-28T10:12:36Z</modified>
    <revision></revision>
    <subject></subject>
    <title></title>
    <unit meter="1.000000" name="centimeter"></unit>
    <up_axis>Z_UP</up_axis>
  </asset>

  <library_images>
    <image id="BITMAPKARTINOCHKA-image" name="BITMAPKARTINOCHKA">
      <init_from>kartinochka.jpg</init_from>
    </image>
  </library_images>
  <library_materials>
    <material id="MATKARTINOCHKA" name="MATKARTINOCHKA">
      <instance_effect url="#MATKARTINOCHKA-fx"/>
    </material>
  </library_materials>
  <library_effects>
    <effect id="MATKARTINOCHKA-fx" name="MATKARTINOCHKA">
      <profile_COMMON>
        <technique sid="standard">
          <phong>
            <diffuse>
              <texture texture="BITMAPKARTINOCHKA-image" texcoord="CHANNEL0">
              </texture>
            </diffuse>
          </phong>
        </technique>
      </profile_COMMON>
    </effect>
  </library_effects>

  <library_geometries>
    <geometry id="Box001-lib" name="Box001Mesh">
      <mesh>
        <source id="Box001-POSITION">
CODE

}

sub cld_VBO{
my @verts=@_;
my $verts_count=@verts;
my $verts_text=join("\n",map{join(" ",@{$_})}@verts);
my $num_count=$verts_count*3;
print oo <<CODE;
  <float_array id="Box001-POSITION-array" count="$num_count">
$verts_text
</float_array>
          <technique_common>
            <accessor source="#Box001-POSITION-array" count="$verts_count" stride="3">
              <param name="X" type="float"/>
              <param name="Y" type="float"/>
              <param name="Z" type="float"/>
            </accessor>
          </technique_common>
        </source>
CODE
}

sub cld_normals{
my @arr=@_;
my $arr_count=@arr;
my $arr_text=join("\n",map{join(" ",@{$_})}@arr);
my $num_count=$arr_count*3;
print oo <<CODE;
<source id="Box001-Normal0"><float_array id="Box001-Normal0-array" count="$num_count">
$arr_text
</float_array>
          <technique_common>
            <accessor source="#Box001-Normal0-array" count="$arr_count" stride="3">
              <param name="X" type="float"/>
              <param name="Y" type="float"/>
              <param name="Z" type="float"/>
            </accessor>
          </technique_common>
        </source>
CODE
}

sub cld_UV{
my @arr=@_;
my $arr_count=@arr;
my $arr_text=join("\n",map{join(" ",@{$_})}@arr);
my $num_count=$arr_count*2;
print oo <<CODE;
        <source id="Box001-UV0">
          <float_array id="Box001-UV0-array" count="$num_count">
$arr_text
</float_array>
          <technique_common>
            <accessor source="#Box001-UV0-array" count="$arr_count" stride="2">
              <param name="S" type="float"/>
              <param name="T" type="float"/>
            </accessor>
          </technique_common>
        </source>
CODE
}


sub cld_mesh{
my @dat=@_;
my $dat_count=@dat;
my $dat_text=join(" ",@dat);
my $points_count=$dat_count/9;
print oo <<CODE;
        <vertices id="Box001-VERTEX">
          <input semantic="POSITION" source="#Box001-POSITION"/>
        </vertices>
        <triangles count="$points_count" material="MATKARTINOCHKA">
          <input semantic="VERTEX" offset="0" source="#Box001-VERTEX"/>
          <input semantic="NORMAL" offset="1" source="#Box001-Normal0"/>
	  <input semantic="TEXCOORD" offset="2" set="0" source="#Box001-UV0"/>
          <p>$dat_text</p>
        </triangles>
      </mesh>
    </geometry>
  </library_geometries>
CODE
}

sub cld_finish{
print oo <<CODE;

  <library_lights>
    <light id="SceneAmbient" name="SceneAmbient">
      <technique_common>
        <ambient>
          <color>1.000000 1.000000 1.000000</color>
        </ambient>
      </technique_common>
    </light>
  </library_lights>
  <library_visual_scenes>
    <visual_scene id="pizda" name="">
      <node name="Box001" id="Box001" sid="Box001">
        <matrix sid="matrix">0.025400 0.000000 0.000000 -0.000161 0.000000 0.025400 0.000000 0.000118 0.000000 0.000000 0.025400 0.000000 0.000000 0.000000 0.000000 1.000000</matrix>
        <instance_geometry url="#Box001-lib"/>
          <bind_material>
            <technique_common>
              <instance_material symbol="MATKARTINOCHKA" target="#MATKARTINOCHKA"/>
            </technique_common>
          </bind_material>
        <extra>
          <technique profile="FCOLLADA">
            <visibility>1.000000</visibility>
          </technique>
        </extra>
      </node>
      <extra>
        <technique profile="MAX3D">
          <frame_rate>30.000000</frame_rate>
        </technique>
        <technique profile="FCOLLADA">
          <start_time>0.000000</start_time>
          <end_time>3.333333</end_time>
        </technique>
      </extra>
      <node>
        <instance_light url="#SceneAmbient"></instance_light>
      </node>
    </visual_scene>
  </library_visual_scenes>
  <scene>
    <instance_visual_scene url="#pizda"></instance_visual_scene>
  </scene>
</COLLADA>

CODE

close(oo);

}

1
