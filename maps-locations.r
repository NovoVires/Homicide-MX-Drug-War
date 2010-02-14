#* You'll need to download a map of Mexico from the [ICESI](http://www.icesi.org.mx/estadisticas/estadisticas_encuestasTablas.asp)
#* You'll also need to download two maps of Mexico at the state and county level from the [INEGI](http://mapserver.inegi.org.mx/data/mgm/). #You'll need to register to do download them
#They have to be version 3.1.1 or they won't work
# �reas Geoestad�sticas Estatales y Zonas Pendientes por Asignar (6.47 Mb)
# �reas Geoestad�sticas Municipales y Zonas Pendientes por Asignar (30.6 Mb)

#Change to were you downloaded the map from the ICESI
map.of.mexico <- "../../../maps/Mexico.shp"

#Change to the location of the INEGI maps
mexico.map.ct.file <- "../../../maps/3.1.1/MUNICIPIOS.shp"
mexico.map.st.file <- "../../../maps/3.1.1/ESTADOS.shp"
