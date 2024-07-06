# Источники данных

В данном проекте используются следующие опорные точки Йошкар-Олы:
* `47.8127483039572,56.6681590038049,47.9432109504415,56.598671290742` - весь город с запасом
* `47.8292312174411,56.6056570359103,47.932228043613,56.6585299815102` - город по минимуму
* `56.6601552312463,47.8209433423879` - центр региона + 30 километров радиус
* `56.63109683633924,47.88093660864732` - наш центр города + 3 километра радиус

## Карта высот ALOS AW3D30
* Датасет: https://www.eorc.jaxa.jp/ALOS/en/aw3d30/data/index.htm
* Страница загрузки: https://www.eorc.jaxa.jp/ALOS/en/aw3d30/data/html_v2404/n050e030_n080e060.htm
* Тыкнуть на 56х47: https://www.eorc.jaxa.jp/ALOS/en/aw3d30/data/html_v2404/dl/download_v2404.htm?N055E045_N056E047
* Карта доступна после регистрации, логин - `ninila7297@kinsef.com`, пароль - название датасета
* Опционально делаем пост-процессинг и сносим домики: https://www.youtube.com/watch?v=LoF2nJbo-n8

## Карта высот ALOS Palsar

* Идем на поисковик https://search.asf.alaska.edu/
* Выбираем датасет "ALOS Palsar", появится предложение кликнуть на карте чтобы начать рисовать
* Зумим карту до Йошкар-Олы и кликаем где-то в сторонке, натягиваем прямоугольник на весь регион
* Забираем, к примеру, `ALPSRP186381130` внутри есть [ALPSRP186381130-RTC_HI_RES](https://datapool.asf.alaska.edu/RTC_HI_RES/A3/AP_18638_FBD_F1130_RT1.zip)
* Может попросить регистрацию для скачивания

## Карта высот Copernicus

* Идем https://spacedata.copernicus.eu/collections/copernicus-digital-elevation-model - тут инструкция
* Наш датасет: https://prism-dem-open.copernicus.eu/pd-desk-open-access/prismDownload/COP-DEM_GLO-90-DGED__2023_1/Copernicus_DSM_30_N56_00_E047_00.tar

## Карта высот ASTER

TODO: fixme

## Карта высот STRM1 (1 arc-second)

TODO: fixme

## Данные OSM

* Тырим весь приволжский федеральный округ: `wget https://download.geofabrik.de/russia/volga-fed-district-latest.osm.pbf`
* Отрезаем город Йошкар-Ола с некоторым запасом: `osmium extract -v --progress -s simple -b 47.8127483039572,56.6681590038049,47.9432109504415,56.598671290742 volga-fed-district-latest.osm.pbf -o yoshkar-ola-max.pbf`. Это нужно, чтобы было удобнее работать с файлом на 2 мегабайта, а не файлом на 650 мегабайт. Операция занимает некоторое время, 1.5 гигабайта оперативы и на выходе PBF-файл, как и на входе.
* Конвертируем PBF во что-то съедобное, например в текст: `osmium export -f text -o yoshkar-ola-max.txt -O -e -v --progress yoshkar-ola-max.pbf`
* Конвертируем PBF в привычный OSM.XML: `osmium cat -o yoshkar-ola-max.osm -O yoshkar-ola-max.pbf`

## Данные TMS (GoogleMaps, Bing, ESRI, OSM Mapnik и т.д.)

* Открываем SAS.Planet, исходные карты должны быть уже установлены
* Идем в Операции -> Операции с выделенной областью -> По координатам ![Скриншот](./import-sasplanet-1-dialog.png)
* Вводим координаты нужной области ![Скриншот](./import-sasplanet-2-coords.png)
* Выбираем вкладку `Экспорт` и выставляем опции как на скриншоте: ![Скриншот](./import-sasplanet-3-levels.png)
* Забираем получившийся `yoshkar-ola-googlemaps.zip`, внутри будут тайлики в формате TMS

## Данные о растительности (не обязательно)

* Тырим Landsat 8
* Sentinel 1-2

## Данные о домах

* https://xn--80aq1a.xn--p1aee.xn--p1ai/ (https://аис.фрт.рф/)
* Тыкнуть "открытые данные", потом "регионы"
* Тыкнуть "Реестр домов по Республике Марий Эл"

## Типовые серии домов

* https://www.kvmeter.ru/information/homes_series/

## Панорамы улиц Google StreetView / Яндекс STV-Шары / Mapillary

TODO: fixme
