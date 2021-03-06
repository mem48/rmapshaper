#' Aggregate shapes in a polygon or point layer.
#'
#' Aggregates using specified field, or all shapes if no field is given. For point layers,
#' replaces a group of points with their centroid.
#'
#' @param input spatial object to dissolve. One of:
#' \itemize{
#'  \item \code{geo_json} or \code{character} points or polygons;
#'  \item \code{geo_list} points or polygons;
#'  \item \code{SpatialPolygons}, or \code{SpatialPoints}
#'  }
#' @param snap Snap together vertices within a small distance threshold to fix
#'   small coordinate misalignment in adjacent polygons. Default \code{TRUE}.
#' @param field the field to dissolve on
#' @param sum_fields fields to sum
#' @param copy_fields fields to copy. The first instance of each field will be
#'   copied to the aggregated feature.
#' @param force_FC should the output be forced to be a \code{FeatureCollection} even
#' if there are no attributes? Default \code{TRUE}.
#'  \code{FeatureCollections} are more compatible with \code{rgdal::readOGR} and
#'  \code{geojsonio::geojson_sp}. If \code{FALSE} and there are no attributes associated with
#'  the geometries, a \code{GeometryCollection} will be output. Ignored for \code{Spatial}
#'  objects, as the output is always the same class as the input.
#'
#' @return the same class as the input
#'
#' @examples
#' library(geojsonio)
#' library(sp)
#' 
#' poly <- structure('{"type":"FeatureCollection",
#'   "features":[
#'   {"type":"Feature",
#'   "properties":{"a": 1, "b": 2},
#'   "geometry":{"type":"Polygon","coordinates":[[
#'   [102,2],[102,3],[103,3],[103,2],[102,2]
#'   ]]}}
#'   ,{"type":"Feature",
#'   "properties":{"a": 5, "b": 3},
#'   "geometry":{"type":"Polygon","coordinates":[[
#'   [100,0],[100,1],[101,1],[101,0],[100,0]
#'   ]]}}]}', class = c("json", "geo_json"))
#' poly <- geojson_sp(poly)
#' plot(poly)
#' length(poly)
#' poly@data
#' 
#' # Dissolve the polygon
#' out <- ms_dissolve(poly)
#' plot(out)
#' length(out)
#' out@data
#' 
#' # Dissolve and summing columns
#' out <- ms_dissolve(poly, sum_fields = c("a", "b"))
#' plot(out)
#' out@data
#'
#' @export
ms_dissolve <- function(input, field = NULL, sum_fields = NULL, copy_fields = NULL, snap = TRUE, force_FC = TRUE) {
  UseMethod("ms_dissolve")
}

#' @export
ms_dissolve.character <- function(input, field = NULL, sum_fields = NULL, copy_fields = NULL, snap = TRUE, force_FC = TRUE) {
  input <- check_character_input(input)

  call <- make_dissolve_call(field = field, sum_fields = sum_fields,
                             copy_fields = copy_fields, snap = snap)

  apply_mapshaper_commands(data = input, command = call, force_FC = force_FC)

}

#' @export
ms_dissolve.geo_json <- function(input, field = NULL, sum_fields = NULL, copy_fields = NULL, snap = TRUE, force_FC = TRUE) {

  call <- make_dissolve_call(field = field, sum_fields = sum_fields,
                             copy_fields = copy_fields, snap = snap)

  apply_mapshaper_commands(data = input, command = call, force_FC = force_FC)
}

#' @export
ms_dissolve.geo_list <- function(input, field = NULL, sum_fields = NULL, copy_fields = NULL, snap = TRUE, force_FC = TRUE) {

  call <- make_dissolve_call(field = field, sum_fields = sum_fields,
                             copy_fields = copy_fields, snap = snap)

  geojson <- geojsonio::geojson_json(input)

  ret <- apply_mapshaper_commands(data = geojson, command = call, force_FC = force_FC)

  geojsonio::geojson_list(ret)
}

#' @export
ms_dissolve.SpatialPolygons <- function(input, field = NULL, sum_fields = NULL, copy_fields = NULL, snap = TRUE, force_FC = TRUE) {
 dissolve_sp(input = input, field = field, sum_fields = sum_fields, copy_fields = copy_fields, snap = snap)
}

#' @export
ms_dissolve.SpatialPoints <- function(input, field = NULL, sum_fields = NULL, copy_fields = NULL, snap = TRUE, force_FC = TRUE) {
  dissolve_sp(input = input, field = field, sum_fields = sum_fields, copy_fields = copy_fields, snap = snap)
}

make_dissolve_call <- function(field, sum_fields, copy_fields, snap) {

  if (is.null(sum_fields)) {
    sum_fields_string <- NULL
  } else {
    sum_fields_string <- paste0("sum-fields=", paste0(sum_fields, collapse = ","))
  }

  if (is.null(copy_fields)) {
    copy_fields_string <- NULL
  } else {
    copy_fields_string <- paste0("copy-fields=", paste0(copy_fields, collapse = ","))
  }

  if (snap) snap <- "snap" else snap <- NULL

  call <- list(snap, "-dissolve", field, sum_fields_string, copy_fields_string)

  call
}

dissolve_sp <- function(input, field, sum_fields, copy_fields, snap) {

  call <- make_dissolve_call(field = field, sum_fields = sum_fields,
                             copy_fields = copy_fields, snap = snap)

  ms_sp(input = input, call = call)
}
