# Примитивный просмотрщик GEOJSON

Значит сетапим Осмиум как-то так:

```
root# apt-cache search osmium # ищем осмиум
root# apt-get install osmium-tool # ставим осмиум
```

Теперь тырим данные:
```
wget https://download.geofabrik.de/russia/volga-fed-district-latest.osm.pbf
osmium extract -v --progress -s simple -b 47.8292312174411,56.6056570359103,47.932228043613,56.6585299815102 volga-fed-district-latest.osm.pbf -o out_test.pbf
osmium export --overwrite -o map.js --output-format geojson -e --progress out_test.pbf
```

Что тырим:
* `47.8127483039572,56.6681590038049,47.9432109504415,56.598671290742` - весь город с запасом
* `47.8292312174411,56.6056570359103,47.932228043613,56.6585299815102` - город по минимуму
* `56.6601552312463,47.8209433423879` - центр региона + 30 километров радиус
* `56.63109683633924,47.88093660864732` - наш центр города + 3 километра радиус

Ну и загружаем `viewer.html`, рядом кладем `map.js` и пытаемся понять, что же мы нарисовали
