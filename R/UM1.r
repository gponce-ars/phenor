#' Unified M1 model as defined in
#' Basler et al. 2016 (Agr. For. Meteorlogy)
#'
#' @param data: a nested list of data
#' @param par: a vector of parameter values, this is functions specific
#' @keywords phenology, model
#' @export
#' @examples
#'
#' \dontrun{
#' estimate = UM1(data = data, par = par)
#'}

UM1  = function(par, data){

  # exit the routine as some parameters are missing
  if (length(par) != 8){
    stop("model parameter(s) out of range (too many, too few)")
  }

  # extract the parameter values from the
  # par argument
  t0 = round(par[1])
  T_base = par[2]
  T_opt = par[3]
  T_min = par[4]
  T_max = par[5]
  f = par[6]
  w = par[7]
  C_req = par[8]

  # chilling accumulation
  Rc = matrix(0,nrow(data$Ti),ncol(data$Ti))
  Rc[data$Ti < T_opt & data$Ti >= T_min] =
    (data$Ti[data$Ti < T_opt & data$Ti >= T_min] - T_min)/(T_opt - T_min)
  Rc[data$Ti < T_max & data$Ti >= T_opt] =
    (data$Ti[data$Ti < T_max & data$Ti >= T_opt] - T_opt)/(T_max - T_opt)
  Rc[1:t0,] = 0

  # bell shaped temperature response
  Sc = apply(Rc, 2, cumsum)

  # chilling requirement has to be met before
  # accumulation starts (binary choice)
  k = as.numeric(Sc >= C_req)

  # forcing
  Rf = data$Ti - T_base
  Rf[Rf < 0] = 0
  Rf = ((data$Li / 24) ^ k) * Rf
  Rf[1:t0,] = 0
  Sf = apply(Rf, 2, cumsum)

  # DOY meeting F_crit, subtract the forcing matrix
  # from the F_crit matrix in order to speed things up
  # only the location of transition from - to + is
  # claculated to estimate the transition dates
  Sfc = Sf - (w * exp(f * Sc))

  doy = apply(Sfc, 2, function(x){
    doy = data$doy[which(x > 0)[1]]
    doy[is.na(doy)] = 9999
    return(doy)
  })

  # set export format, either a rasterLayer
  # or a vector
  if(is.null(data$site)){
    r = raster(nrows = data$georeferencing$size[1],
               ncols = data$georeferencing$size[2])
    extent(r) = data$georeferencing$extent
    proj4string(r) = CRS(data$georeferencing$projection)
    r[] = doy
    r[r==9999] = NA
    return(r)
  } else {
    return(doy)
  }
}
