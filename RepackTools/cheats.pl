use Digest::CRC "crc32";
$key=reverse uc("jcnruad");
$crc=crc32($key)^0xFFFFFFFF;
printf("0x%08X\n",$crc);

