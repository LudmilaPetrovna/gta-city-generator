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

Ну и загружаем `viewer.html`, рядом кладем `map.js` и пытаемся понять, что же мы нарисовали