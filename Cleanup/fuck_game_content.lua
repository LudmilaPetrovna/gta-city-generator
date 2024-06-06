-- main.scm в этой папке очищен от всего игрового контента, имеет только спавн игрока
local memory = require 'memory'
function main()
	while not isOpcodesAvailable() do wait(1) end 
	-- отключение розыска
    memory.write(0x58DB5F, 0xBD, 1, true)
    memory.fill(0x58DB60, 0x00, 4, true)
    memory.fill(0x58DB64, 0x90, 4, true)

    memory.write(0x72C1B7, 0xEB, 1, true) -- отлючение haze эффекта
    
    memory.fill(0x53C090, 0x90, 5, true) -- отключение реплеев
    memory.fill(0x440833, 0x90, 8, true) -- отключить педов в интерьерах
    memory.write(0x588BE0, 0xC3, 1, true) -- отключить всплывающие подсказки
    memory.fill(0x58FBE9, 0x90, 5, true) -- отключить имена тачек
    setPedDensityMultiplier(0.0) -- отключить спавн педов 
    setCarDensityMultiplier(0.0) -- отключить спавн педов в тачках
    setMaxWantedLevel(0) -- максимальный уровень розыска 0
    setOnlyCreateGangMembers(true) -- отключить войны банд
    setCreateRandomGangMembers(false) -- отключить создание банд на улицах
    enableBurglaryHouses(false) -- отключить вход в дом
    switchRandomTrains(false) -- отключить спавн поездов
    setCreateRandomCops(false) -- отключить полицию
    switchEmergencyServices(false) -- отключить скорую
    switchAmbientPlanes(false) -- отключить летающие самолеты
    memory.write(0x9690A0, 0, 4, true) -- отключить генератор тачек номер 1
    -- отключить генератор тачек номер 2
    memory.fill(0x53C1C1, 0x90, 5, true)
    memory.fill(0x434272, 0x90, 5, true)
    memory.fill(0x561AF0, 0x90, 7, true) -- антипауза (не понял как работает)
    
    -- отключить спавн 537 поезда
    memory.setuint8(0x8D477C, 0x00, true)
    memory.setuint8(0x8D477D, 0x00, true)

    -- TODO написать патч с подменой main.scm

end