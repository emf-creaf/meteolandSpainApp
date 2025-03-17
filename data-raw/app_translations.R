## code to prepare `app_translations` dataset goes here

app_translations <- tibble::tribble(
  ~text_id, ~translation_cat, ~translation_eng, ~translation_spa,
  # tabs translations
  "main_tab_translation", "Explora", "Explore", "Explora",
  "download_tab_translation", "Descarrega", "Download", "Descarga",
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
  # user_inputs
  "user_var_date_title", "Mapa", "Map controls", "Mapa",
  "user_var", "Variable:", "Variable:", "Variable:",
  "user_date", "Data:", "Date:", "Fecha:",
  "user_ts_title", "Sèries temporals", "Time series controls", "Series temporales",
  "user_longitude", "Longitud", "Longitude", "Longitud",
  "user_latitude", "Latitud", "Latitude", "Latitud",
  "user_longitude_help", "La longitud ha d'estar entre -9.5 i 4", "Longitude must be between -9.5 and 4", "La longitud debe estar entre -9.5 y 4",
  "user_latitude_help", "La latitud ha d'estar entre 35.5 i 44", "Latitude must be between 35.5 and 44", "La latitud debe estar entre 35.5 y 44",
  "user_ts_calculate", "Calcular sèries temporals", "Calculate time series", "Calcular series temporales",
  "user_ts_refresh", "Recalcular sèries temporals", "Refresh time series", "Recalcular series temporales",
  "user_ts_refresh_calculating", "Calculant, això pot portar un temps...", "Calculating, this can take a while...", "Calculando, esto puede llevar un tiempo...",
  # download outputs
  "download_maps_title", "Descarrega de mapas", "Maps download", "Descarga de mapas",
  "download_maps_text", "", "PLACEHOLDER for download maps text", "",
  "download_maps_link", "", "PLACEHOLDER", "",
  "download_ts_title", "Descarrega de sèries temporals", "Time series download", "Descarga de series temporales",
  "download_ts_text", "", "PLACEHOLDER for timeseries text", "",
  "download_ts_button", "", "PLACEHOLDER", "",
  # map outputs
  "map_tooltip", "Coordenades seleccionades", "Selected coordinates", "Coordenadas seleccionadas",
  # waiting messages
  "getting_data_for", "Obtenint dades per", "Getting data for", "Obteniendo datos para",
  "please_wait", "Per favor, espere...", "Please wait...", "Por favor, espere...",
  # emty string
  "", "", "", ""
)

# internal data for package
usethis::use_data(
  # app_translations
  app_translations,

  internal = TRUE, overwrite = TRUE
)
