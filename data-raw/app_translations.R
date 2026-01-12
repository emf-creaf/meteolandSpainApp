## code to prepare `app_translations` dataset goes here

app_translations <- tibble::tribble(
  ~text_id, ~translation_cat, ~translation_eng, ~translation_spa,
  # tabs translations
  "main_tab_translation", "Mapa diari", "Daily map", "Mapa diario",
  "ts_tab_translation", "Sèries temporals", "Time series", "Series temporales",
  "cv_tab_translation", "Validacions creuades", "Cross validations", "Validaciones cruzadas",
  "tech_specs_tab_translation", "Especificacions tècniques", "Technical specifications", "Especificaciones técnicas",
  # meteo copyright translations
  "meteo_copyright_translation", "Per al càlcul de les interpolacions meteorològiques s'han fet servir dades de les estacions d'AEMET, el Servei Meteorològic de Catalunya, Meteogalícia i la Conselleria de Medi Ambient, Territori i Habitatge de la Xunta de Galícia i la Xarxa d'Informació Agroclimàtica d'Andalusia.", "For the calculation of meteorological interpolations, data from the stations of AEMET, the Servei Meteorològic de Catalunya, Meteogalicia and the Conselleria de Medio Ambiente, Territorio y Vivienda de la Xunta de Galicia and the Red de Información Agroclimática de Andalucia have been used.", "Para el cálculo de las interpolaciones meteorológicas se han usado datos de las estaciones de AEMET, el Servei Meteorològic de Catalunya, Meteogalicia y la Conselleria de Medio Ambiente, Territorio y Vivienda de la Xunta de Galicia y la Red de Información Agroclimática de Andalucia.",
  # variables
  "MeanTemperature", "Temperatura mitjana [°C]", "Mean Temperature [°C]", "Temperatura media [°C]",
  "MinTemperature", "Temperatura mínima [°C]", "Min Temperature [°C]", "Temperatura mínima [°C]",
  "MaxTemperature", "Temperatura màxima [°C]", "Max Temperature [°C]", "Temperatura máxima [°C]",
  "MeanRelativeHumidity", "Humitat relativa mitjana [%]", "Mean Relative Humidity [%]", "Humedad relativa media [%]",
  "MinRelativeHumidity", "Humitat relativa mínima [%]", "Min Relative Humidity [%]", "Humedad relativa mínima [%]",
  "MaxRelativeHumidity", "Humitat relativa màxima [%]", "Max Relative Humidity [%]", "Humedad relativa máxima [%]",
  "Precipitation", "Precipitació [mm]", "Precipitation [mm]", "Precipitación [mm]",
  "Radiation", "Radiació [MJ/m2]", "Radiation [MJ/m2]", "Radiación [MJ/m2]",
  "WindSpeed", "Velocitat del vent [m/s]", "Wind Speed [m/s]", "Velocidad del viento [m/s]",
  "WindDirection", "Direcció del vent [° des del N]", "Wind Direction [° from N]", "Dirección del viento [° desde N]",
  "ThermalAmplitude", "Amplitud Tèrmica [°C]", "Thermal Amplitude [°C]", "Amplitud Térmica [°C]",
  "PET", "PET [mm]", "PET [mm]", "PET [mm]",
  "RangeTemperature", "Rang de Temperatura [°C]", "Temperature range [°C]", "Rango de Temperatura [°C]",
  "RelativeHumidity", "Humitat relativa [%]", "Relative Humidity [%]", "Humedad relativa [%]",
  "TotalPrecipitation", "Precipitació Total [mm]", "Total Precipitation [mm]", "Precipitación Total [mm]",
  "StationsPrecipitation", "Precipitació Estacions [mm]", "Stations Precipitation [mm]", "Precipitación Estaciones [mm]",
  # cv stats
  "bias", "Setge", "Bias", "Sesgo",
  "relative_bias", "Sesgo relatiu", "Relative bias", "Sesgo relativo",
  "mae", "Error Absolut Mitjà", "Mean Absolute Error (MAE)", "Error Absoluto Medio (MAE)",
  "r2", "R quadrat", "R squared", "R cuadrado",
  "n_stations", "Nombre d'estacions", "Number of stations", "Número de estaciones",
  # user_inputs
  "map_controls", "Mapa", "Map controls", "Mapa",
  "user_var", "Variable:", "Variable:", "Variable:",
  "user_date", "Data:", "Date:", "Fecha:",
  "user_agg", "Agregació:", "Aggregation:", "Agregación:",
  "ts_controls", "Sèries temporals", "Time series controls", "Series temporales",
  "user_ts_type", "Calcular per coordenades", "Calculate for coordinates", "Calcular para coordenadas",
  "user_province", "Provincies", "Provinces", "Provincias",
  "user_region", "Comarques", "Counties", "Comarcas",
  "user_municipality", "Municipis", "Municipalities", "Municipios",
  "user_ts_agg", "Selecciona una provincia o regió:", "Select a province or county:", "Selecciona una provincia o comarca:",
  "user_longitude", "Longitud", "Longitude", "Longitud",
  "user_latitude", "Latitud", "Latitude", "Latitud",
  "user_longitude_help", "La longitud ha d'estar entre -9.5 i 4", "Longitude must be between -9.5 and 4", "La longitud debe estar entre -9.5 y 4",
  "user_latitude_help", "La latitud ha d'estar entre 35.5 i 44", "Latitude must be between 35.5 and 44", "La latitud debe estar entre 35.5 y 44",
  "user_ts_calculate", "Calcular sèries temporals", "Calculate time series", "Calcular series temporales",
  "user_ts_refresh", "Recalcular sèries temporals", "Refresh time series", "Recalcular series temporales",
  "user_ts_refresh_calculating", "Calculant, això pot portar un temps...", "Calculating, this can take a while...", "Calculando, esto puede llevar un tiempo...",
  "user_info", "Info:", "Info:", "Info:",
  "user_info_p1", "El mapa té una resolució de 2 km²", "Map has a resolution of 2 km²", "El mapa tiene una resolucion de 2 km²",
  "user_info_p2", "Les sèries temporals es calculen a una resolució de 500 m²", "Time series are calculated at a 500 m² resolution", "Las series temporales se calculan a una resolución de 500 m²",
  "cv_controls", "Validacions creuades", "Cross Validations controls", "Validaciones cruzadas",
  # aggregation
  "cont", "Cap", "None", "Ninguna",
  "comarca", "Comarques", "Counties", "Comarcas",
  "provincia", "Provincies", "Provinces", "Provincias",
  "municipio", "Municipis", "Municipalities", "Municipios",
  # download outputs
  "download_maps_title", "Descarrega de mapas", "Maps download", "Descarga de mapas",
  "download_maps_text", "Els mapes diaris a 500 m² estan disponibles en el repositori de dades públiques de l'EMF.", "Daily maps at 500 m² resolution are available at the public EMF data repository.", "Los mapas diarios a resolucion de 500 m² están disponibles en el repositorio de datos públicos de la EMF.",
  "download_maps_link", "Repositori de mapes", "Map files repository", "Repositorio de mapas",
  "download_ts_title", "Descarrega de sèries temporals", "Time series download", "Descarga de series temporales",
  "download_ts_text", "Un cop calculada, la sèrie temporal es pot descarregar en format text (arxiu csv).", "Once calculated, time series can be downloaded in text format (csv file).", "Una vez calculada, la serie temporal se puede descargar en formato texto (archivo csv).",
  "download_ts_button", "Descarrega csv", "Dowload csv", "Descarga csv",
  # map outputs
  "map_tooltip", "Coordenades seleccionades", "Selected coordinates", "Coordenadas seleccionadas",
  # cv ui
  "cv_date", "Data:", "Date:", "Fecha:",
  "cv_var", "Variable:", "Variable:", "Variable:",
  # waiting messages
  "getting_data_for", "Obtenint dades per", "Getting data for", "Obteniendo datos para",
  "please_wait", "Per favor, espere...", "Please wait...", "Por favor, espere...",
  # alerts
  "alert_no_data_text", "per a la combinació de data i variable seleccionada", "for the selected combination of date and variable", "para la combinación de fecha y variable seleccionada",
  "alert_no_data_title", "Sense dades", "No data", "Sin datos",
  "alert_dismiss", "Tancar", "Dismiss", "Cerrar",
  # emty string
  "", "", "", ""
)

# source other data-raw scripts needed
source("data-raw/cv_assets.R")

# province names
province_dict <- arrow::s3_bucket(
  "meteoland-spain-app-pngs",
  access_key = Sys.getenv("AWS_ACCESS_KEY_ID"),
  secret_key = Sys.getenv("AWS_SECRET_ACCESS_KEY"),
  scheme = "https",
  endpoint_override = Sys.getenv("AWS_S3_ENDPOINT"),
  region = ""
) |>
  arrow::open_dataset(
    factory_options = list(
      selector_ignore_prefixes = c(
        "daily_interpolated_meteo_cvs",
        "daily_interpolated_meteo_bitmaps",
        "daily_interpolated_meteo_timeseries_comarca",
        "daily_interpolated_meteo_timeseries_municipio"
      )
    )
  ) |>
  dplyr::select(name, province_code) |>
  dplyr::distinct() |>
  dplyr::arrange(name) |>
  dplyr::collect()

province_metadata <- province_dict |>
  dplyr::mutate(
    metadata = paste(name, province_code, "provincia", sep = "_")
  ) |>
  dplyr::pull(metadata)

region_metadata <- arrow::s3_bucket(
  "meteoland-spain-app-pngs",
  access_key = Sys.getenv("AWS_ACCESS_KEY_ID"),
  secret_key = Sys.getenv("AWS_SECRET_ACCESS_KEY"),
  scheme = "https",
  endpoint_override = Sys.getenv("AWS_S3_ENDPOINT"),
  region = ""
) |>
  arrow::open_dataset(
    factory_options = list(
      selector_ignore_prefixes = c(
        "daily_interpolated_meteo_cvs",
        "daily_interpolated_meteo_bitmaps",
        "daily_interpolated_meteo_timeseries_provincia",
        "daily_interpolated_meteo_timeseries_municipio"
      )
    )
  ) |>
  dplyr::select(name, province_code) |>
  dplyr::distinct() |>
  dplyr::arrange(name) |>
  dplyr::mutate(
    metadata = paste(name, province_code, "comarca", sep = "_")
  ) |>
  dplyr::pull(metadata, as_vector = TRUE)

region_names <- glue::glue("{stringr::str_split_i(region_metadata, '_', 1)} ({meteolandSpainApp:::get_province_from_code(stringr::str_split_i(region_metadata, '_', 2))})")

municipality_metadata <- arrow::s3_bucket(
  "meteoland-spain-app-pngs",
  access_key = Sys.getenv("AWS_ACCESS_KEY_ID"),
  secret_key = Sys.getenv("AWS_SECRET_ACCESS_KEY"),
  scheme = "https",
  endpoint_override = Sys.getenv("AWS_S3_ENDPOINT"),
  region = ""
) |>
  arrow::open_dataset(
    factory_options = list(
      selector_ignore_prefixes = c(
        "daily_interpolated_meteo_cvs",
        "daily_interpolated_meteo_bitmaps",
        "daily_interpolated_meteo_timeseries_provincia",
        "daily_interpolated_meteo_timeseries_comarca"
      )
    )
  ) |>
  dplyr::select(name, province_code) |>
  dplyr::distinct() |>
  dplyr::arrange(name) |>
  dplyr::mutate(
    metadata = paste(name, province_code, "municipio", sep = "_")
  ) |>
  dplyr::pull(metadata, as_vector = TRUE)

municipality_names <- glue::glue("{stringr::str_split_i(municipality_metadata, '_', 1)} ({meteolandSpainApp:::get_province_from_code(stringr::str_split_i(municipality_metadata, '_', 2))})")

# internal data for package
usethis::use_data(
  # app_translations
  app_translations,
  # cv json (from cv_assets.R)
  interpolators_geojson,
  # agg names
  province_metadata,
  region_metadata,
  region_names,
  municipality_metadata,
  municipality_names,
  province_dict,
  # opts
  internal = TRUE, overwrite = TRUE
)
