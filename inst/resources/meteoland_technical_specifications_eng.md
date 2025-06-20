---
title: "Technical specifications"
output: html_document
---
### Introduction

The **Meteoland App** application attempts to provide daily weather estimates for all of Spain, covering the last calendar year, based on data from weather stations. This service is designed to support studies in the forestry field that require daily climate information, complementing the data that the aforementioned institutions can offer. It is important to remember that the data provided includes interpolations and calculations based on models, so the resulting values ​​may contain notable differences with respect to measurements.

### Data sources

The interpolations offered in this application are made from measurements obtained in meteorological stations of the [Agencia Estatal de Meteorologia (AEMET)](http://www.aemet.es), the [Servei Meteorologico de Catalunya (SMC)](http://www.meteo.cat), [MeteoGalicia](https://www.meteogalicia.gal/web/inicio.action) and the [Red de Información Agroclimática de Andalucía (RIA)](https://www.juntadeandalucia.es/agriculturaypesca/ifapa/riaweb/web/).
To use the data provided by the application, it is necessary to include these data sources in the resulting documents (articles or reports).

The topography data have been obtained from the digital evaluation model (MDT25) provided by the [National Geographic Information Center](https://centrodedescargas.cnig.es/CentroDescargas/modelos-digitales-elevaciones).

### Methodology for estimating meteorological variables

There are numerous approaches for interpolation and estimation of meteorological data. The **Meteoland App** application is based on the [R package of the same name (De Cáceres *et al.* 2018)](https://cran.r-project.org/package=meteoland), which implements with a few modifications the interpolation and estimation algorithms developed in the USA for the DAYMET dataset (Thornton *et al.* 1997; Thornton & Running 1999). We provide here a brief description of the methodology. This approach is based on establishing weights for the stations as a decreasing function of their distance from the target interpolation point. The function used is a negative exponential that depends on two parameters (Thornton *et al.* 1997): a parameter $\alpha$ that modulates the shape of the function, making it more or less steep, and a parameter $N$ that indicates an average number of stations to include in the data used for interpolation. Depending on the station density and the parameter $N$, the algorithm determines a truncation distance that causes those stations that are at greater distances to be ignored.

Starting from the general approximation, it is necessary to take into account the methodological differences for specific variables:

+ *Temperature* - The temperature interpolation includes a correction for the elevation differences between the meteorological stations and the target point. Specifically, a weighted regression is used to find out the relationship between the elevation differences between the stations used and their temperature differences. This relationship and the elevation differences between the target point and the stations are then used to correct the temperature estimate for the target point. The same procedure is used for the maximum, minimum, and average temperatures.
+ *Relative Humidity* - Humidity interpolation is performed on the dew point temperature (without taking into account any correction for elevation differences) and then the average, minimum, and maximum relative humidities are calculated from the temperature estimate.
+ *Precipitation* - Precipitation interpolation is more complex, given the need to predict both the occurrence of precipitation and the amount. To do this, a binomial predictor of precipitation occurrence is first defined from the occurrence at the stations. For those target points where precipitation is determined to be present, the interpolation routine predicts the amount of precipitation in a similar way to temperature, i.e. taking into account the elevation difference between the stations and each target point.
+ *Wind* - Wind interpolation is performed in two ways depending on the available information. If only daily average speeds are available, but no directions, the interpolation is performed using the general procedure, but if directions are available, polar averages are calculated using the aforementioned weights.

It is important to note that there are variables that are not interpolated, but are calculated *a posteriori* from the interpolations of the previous variables:

+ *Radiation* - The daily incident solar radiation is calculated in two steps. First, a potential solar radiation is determined taking into account the solar declination as well as the latitude, orientation and slope of the target point (Granier & Ohmura 1968), integrating the instantaneous radiation between sunrise and sunset. Then, the incident solar radiation is estimated by correcting the potential radiation according to the transmittance of the atmosphere, following the approximation of Thornton & Running (1999).
+ *Potential evapotranspiration* - Once all the variables mentioned above are available, the daily reference potential evapotranspiration is calculated for the target point according to the approximation of Penman (1948).

### Estimation for the last 365 days

The **Meteoland App** application offers the possibility of estimating meteorological data for the last 365 days up to yesterday's date. The interpolation/calculation of data for the current year is performed from data obtained daily using the R package `meteospain`. This implies that the station data have not passed all the relevant quality controls and may contain errors. The spatial resolution offered is 500 m^2.

### Parameterization and evaluation

As mentioned above, the interpolation methodology requires specifying the parameters $\alpha$ and $N$ for each variable to be interpolated (in the case of precipitation, these are two pairs). These parameters have been estimated through calibrations for each day of the current year, determining those parameters that minimized the estimation error on the same base stations. The validations of these calibrations can be consulted in the "Cross Validations" tab. As can be seen in the validations, the area to be interpolated has been divided into quadrants containing at least 45 weather stations, to avoid areas without coverage.

### References

+ De Caceres M, Martin-StPaul N, Turco M, Cabon A, Granda V (2018) Estimating daily meteorological data and downscaling climate models over landscapes. Environmental Modelling and Software 108: 186-196.
+ Garnier, B.J., Ohmura, A., 1968. A method of calculating the direct shortwave radiation income of slopes. J. Appl. Meteorol. 7, 796–800.
+ Penman, H.L., 1948. Natural evaporation from open water, bare soil and grass. Proc. R. Soc. London. Ser. A. Math. Phys. Sci. 193, 129–145.
+ Thornton, P.E., Running, S.W., 1999. An improved algorithm for estimating incident daily solar radiation from measurements of temperature, humidity, and precipitation. Agric. For. Meteorol. 93, 211–228. https://doi.org/10.1016/S0168-1923(98) 00126-9.
+ Thornton, P.E., Running, S.W., White, M. A., 1997. Generating surfaces of daily meteorological variables over large regions of complex terrain. J. Hydrol. 190, 214–251. https://doi.org/10.1016/S0022-1694(96)03128-9.
