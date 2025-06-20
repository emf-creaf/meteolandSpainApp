---
title: "Especificaciones técnicas"
output: html_document
---

### Introducción

La aplicación **Meteoland App** intenta proporcionar estimaciones de meteorología diaria para toda España, cubriendo el último año natural, basándose en datos de estaciones meteorológicas. Este servicio está pensado para apoyar estudios en el ámbito forestal que requieran información climática diaria, complementando los datos que puedan ofrecer dichas instituciones. Es importante recordar que los datos proporcionados incluyen interpolaciones y cálculos basados ​​en modelos, por lo que los valores resultantes pueden contener diferencias notables respecto a mediciones.

### Fuentes de datos

Las interpolaciones ofrecidas en esta aplicación se realizan a partir de mediciones obtenidas en estaciones meteorológicas de la [Agencia Estatal de Meteorología (AEMET)](http://www.aemet.es), el [Servicio Meteorológico de Cataluña (SMC)](http://www.meteo.cat), [MeteoGalicia]/https://www. [Red de Información Agroclimática de Andalucía (RIA)](https://www.juntadeandalucia.es/agriculturaypesca/ifapa/riaweb/web/).
Para utilizar los datos proporcionados por la aplicación es necesario hacer constar en los documentos resultantes (artículos o informes) estas fuentes de datos.

Los datos de topografía han sido obtenidos del modelo digital de evaluación (MDT25) proporcionado por el [Centro Nacional de Información Geográfica](https://centrodedescargas.cnig.es/CentroDescargas/modelos-digitales-elevaciones).

### Metodología de estimación de variables meteorológicas

Existen numerosas aproximaciones para la interpolación y estimación de datos meteorológicos. La aplicación **Meteoland App** se basa en el [paquete de R del mismo nombre (De Cáceres *et al.* 2018)](https://cran.r-project.org/package=meteoland), que implementa con unas pocas modificaciones los algoritmos de interpolación y estimación desarrollados en EEUU para el dataset DAYMET; & Running 1999). Ofrecemos aquí una descripción abreviada de la metodología. Esta aproximación se basa en establecer pesos para las estaciones en función decreciente de su distancia al punto de interpolación objetivo. La función utilizada es una exponencial negativa que depende de dos parámetros (Thornton *et al.* 1997): un parámetro $\alpha$ que modula la forma de la función, haciéndola más o menos abrupto, y un parámetro $N$ que indica un número medio de estaciones a incluir en los datos utilizados para. Según la densidad de estaciones y el parámetro $N$, el algoritmo determina una distancia de truncamiento que hace que aquellas estaciones que se encuentren a mayores distancias no sean tenidas en cuenta.

A partir de la aproximación general, es necesario tener en cuenta las diferencias metodológicas por variables concretas:

+ *Temperatura* - La interpolación de la temperatura incluye una corrección por las diferencias de elevación entre las estaciones meteorológicas y el punto objetivo. Especificamente, se emplea una regresión ponderada para averiguar la relación entre las diferencias de elevación entre las estaciones utilizadas y sus diferencias de temperatura. Esta relación y diferencias de elevación entre el punto objetivo y las estaciones se utilizan después para corregir la estimación de temperatura para el punto objetivo. El mismo procedimiento se utiliza para la temperatura máxima, mínima y media.
+ *Humedad relativa* - La interpolación de la humedad se realiza sobre la temperatura de rocío (sin tener en cuenta ninguna corrección por diferencias de elevación) y después se calculan las humedades relativas media, mínima y máxima a partir de la estimación de temperatura.
+ *Precipitación* - La interpolación de la precipitación es más compleja, dada la necesidad de predecir tanto la ocurrencia de precipitación como la cantidad. Para ello, se define primero un predictor binomial de la ocurrencia de precipitación a partir de la ocurrencia en las estaciones. Para aquellos puntos objetivo donde se determina que existe precipitación, la rutina de interpolación predice la cantidad de precipitación de forma similar a la temperatura, es decir teniendo en cuenta la diferencia de elevación entre las estaciones y cada punto objetivo.
+ *Viento* - La interpolación del viento se realiza de dos maneras según la información disponible. Si sólo se dispone de velocidades medias diarias, pero no de direcciones, la interpolación se realiza mediante el procedimiento general, pero si se dispone de direcciones se calculan promedios polares utilizando los pesos mencionados.

Es importante tener en cuenta que existen variables que no son interpoladas, sino que son calculadas *a posteriori* a partir de las interpolaciones de las variables anteriores:

+ *Radiación* - La radiación solar incidente diaria se calcula en dos pasos. En primer lugar se determina una radiación solar potencial teniendo en cuenta la declinación solar así como la latitud, orientación y pendiente del punto objetivo (Granier & Ohmura 1968), integrando la radiación instantánea entre el amanecer y la puesta de sol. A continuación, se estima la radiación solar incidente corrigiendo la radiación potencial según la transmitancia de la atmósfera, siguiendo la aproximación de Thornton & Running (1999).
+ *Evapotranspiración potencial* - Una vez todas las variables mencionadas anteriormente están disponibles, se calcula la evapotranspiración potencial de referencia diaria para el punto objetivo según la aproximación de Penman (1948).


### Estimación para los últimos 365 días

La aplicación **Meteoland App** ofrece la posibilidad de estimar datos de meteorología para los últimos 365 días hasta la fecha de ayer. La interpolación/cálculo de datos del año en curso se realiza a partir de datos obtenidos a diario mediante el paquete de R `meteospain`. Esto implica que los datos de las estaciones no han pasado todos los controles de calidad pertinentes y pueden contener errores. La resolución espacial ofrecida es de 500 m^2.

### Parámetrización y evaluación

Tal y como se ha mencionado anteriormente, la metodología de interpolación necesita especificar los parámetros $\alpha$ y $N$ para cada variable a interpolar (en el caso de la precipitación son dos pares). Estos parámetros han sido estimados mediante calibraciones para cada día del año en curso, determinando aquellos parámetros que minimizaban el error de estimación sobre las propias estaciones de base. Las validaciones de estas calibraciones se pueden consultar en la pestaña "Validaciones cruzadas". Como puede observarse en las validaciones, el área a interpolar se ha dividido en cuadrantes que contuvieran al menos 45 estaciones meteorológicas, para evitar zonas sin cobertura.

### Bibliografia

+ De Caceres M, Martin-StPaul N, Turco M, Cabon A, Granda V (2018) Estimating daily meteorological data and downscaling climate models over landscapes. Environmental Modelling and Software 108: 186-196.
+ Garnier, B.J., Ohmura, A., 1968. A method of calculating the direct shortwave radiation income of slopes. J. Appl. Meteorol. 7, 796–800.
+ Penman, H.L., 1948. Natural evaporation from open water, bare soil and grass. Proc. R. Soc. London. Ser. A. Math. Phys. Sci. 193, 129–145.
+ Thornton, P.E., Running, S.W., 1999. An improved algorithm for estimating incident daily solar radiation from measurements of temperature, humidity, and precipitation. Agric. For. Meteorol. 93, 211–228. https://doi.org/10.1016/S0168-1923(98) 00126-9.
+ Thornton, P.E., Running, S.W., White, M. A., 1997. Generating surfaces of daily meteorological variables over large regions of complex terrain. J. Hydrol. 190, 214–251. https://doi.org/10.1016/S0022-1694(96)03128-9.
