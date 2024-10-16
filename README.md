# City Generation tools for GTA: San Andreas

Итак, ты однажды проснулся и решил, что тебе сильно-сильно хочется засунуть свой родной город в игру San Andreas? А может быть ты мечтал об этом еще лет 20 назад, когда игра только вышла, или даже это желание с тобой еще со времен GTA 1? Добро пожаловать в этот репозиторий, где мы совместными усилиями попробуем запилить что-то такое. Наш уютный дискорд-сервер: https://discord.gg/7mjxJqfWwP

Хочу сделать серию видео (говно)-уроков по глобальному моддингу San Andreas. Понятия не имею, будет ли это интересно кому-то или нет.

Пока план такой:
* Очистить скрипты и просто родиться в пустой карте
* Очистить карту и родиться на плоскости
* Залить в игру карту Google Maps с требуемой местностью
* Залить в игру данные STRM с данными о рельефе
* Перенести геометрию из OpenStreetMaps, включая дороги и дома
* Сгенерировать валидный water.dat с корректной водой
* Сделать тул для расстановки освещения (???), генерация столбов освещения
* Сделать тул для рисования маршрутов трафика, поездов и педов
* Сделать тул(ы) для рисования биомов, травы, мусора в городе
* Расставить по городу пожарные части, полицию, больницы

# Чо хочу от вас:

Собираю команду для написания подобных уроков, может быть менторов, да или хотя бы команду поддержки с воплями "да, сделай, мы хотим учиться!" или "иди в дурку, подлечись". Если я это безобразие начну в одиночку, то рискую достаточно быстро забросить и переключиться на какие-то другие проекты. А если начну, то всему этому меня тоже должен кто-то научить, потому в одно рыло я это не сделаю.

# Коротко о себе:

Умею в Сишечку, имею представления о Cleo, в виртуалке стоит SunnyBuilder3, могу писать скрипты для 3dsmax, если сильно надо, то и полноценные плагины. Умею парсить OpenStreetMaps из `Planet.pbf` и вообще работать с геоданными. Страдаю от депрессии, нежелания жить и от желания делать такие странные и никому ненужные проекты, мимолетом приходящие мне в голову. Сейчас вымучиваю свой проект фотомода https://github.com/LudmilaPetrovna/panorama-gtasa и программирую его онлайн, показывая все свои страдания: https://www.youtube.com/watch?v=ln0MwaiEq4w или https://www.youtube.com/watch?v=oPA9a1h6NeU

Не уверен, что тут много людей увидят этот пост, потому приветствуются посылания меня в более подходящие места, где обитает более целевая аудитория и ее больше. Ну и другие посылания тоже приветствуются. Приветствуется все, кроме игнора.

# Чо надо делать:

Зачитать и понять документы по градостроению, чтобы создать модели для процедурной генерации городов этой страны:

* ГОСТ 32947-2014 Опоры стационарного электрического освещения
* ГОСТ Р 58653-2019 Дороги автомобильные общего пользования. Пересечения и примыкания. Технические требования
* ГОСТ 33475-2015 Дороги автомобильные общего пользования
* ГОСТ Р 51256-2018 - https://meganorm.ru/Data/663/66396.pdf

Примечание — Дорожная разметка является одним из видов технических средств организации дорож ного движения. [ГОСТ 32953, пункт 3.1.1]


# Полезные ссылки

* https://github.com/domlysz/BlenderGIS - перенесет за секунды карты из Google Maps в Blender
* https://github.com/vvoovv/blosm - перенесет OSM за секунды в Blender, много хороших идей
* https://wiki.openstreetmap.org/wiki/RU:Blender - работа с OSM из Блендера
* https://wiki.openstreetmap.org/wiki/RU:Blender-osm - примеры
* https://www.youtube.com/watch?v=z2_SODMTwhM - очень красивый генератор Recreating NYC with CityBLD | NEW UE5 Procedural City Generator
* https://www.youtube.com/watch?v=31DplKsnjWM - как из гуглопанорам сделать свои модельки в несколько кликов (From Google Maps to Blender, my way)
* https://www.youtube.com/watch?v=Jhc0dzImJI8 - моделирование целого города по фоткам (I made long term solution for Buildings)
* https://3dwarehouse.sketchup.com/user/0250916802162283287306459/Vladimir-P?hl=hu - коллекция моделек
* https://habr.com/ru/articles/713984/ Первая открытая 3D модель Зеленограда (фотограмметрия из коптерного видео)
