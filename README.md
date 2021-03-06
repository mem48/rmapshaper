<!-- README.md is generated from README.Rmd. Please edit that file -->
[![Travis-CI Build Status](https://travis-ci.org/ateucher/rmapshaper.svg?branch=master)](https://travis-ci.org/ateucher/rmapshaper) [![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/ateucher/rmapshaper?branch=master&svg=true)](https://ci.appveyor.com/project/ateucher/rmapshaper) [![codecov.io](https://codecov.io/github/ateucher/rmapshaper/coverage.svg?branch=master)](https://codecov.io/github/ateucher/rmapshaper?branch=master)

[![CRAN\_Status\_Badge](http://www.r-pkg.org/badges/version/rmapshaper)](https://cran.r-project.org/package=rmapshaper) [![CRAN Downloads per month](http://cranlogs.r-pkg.org/badges/rmapshaper)](http://cran.rstudio.com/web/packages/rmapshaper/index.html) [![CRAN total downloads](http://cranlogs.r-pkg.org/badges/grand-total/rmapshaper?color=lightgrey)](http://cran.rstudio.com/web/packages/rmapshaper/index.html)

rmapshaper
----------

An R package providing access to the awesome [mapshaper](https://github.com/mbloch/mapshaper/) tool by Matthew Bloch, which has both a [Node.js command-line tool](https://github.com/mbloch/mapshaper/wiki/Introduction-to-the-Command-Line-Tool) as well as an [interactive web tool](http://mapshaper.org/).

I started this package so that I could use mapshaper's [Visvalingam](http://bost.ocks.org/mike/simplify/) simplification method in R. There is, as far as I know, no other R package that performs topologically-aware multi-polygon simplification. (This means that shared boundaries between adjacent polygons are always kept intact, with no gaps or overlaps, even at high levels of simplification).

But mapshaper does much more than simplification, so I am working on wrapping most of the core functionality of mapshaper into R functions.

So far, `rmapshaper` provides the following functions:

-   `ms_simplify` - simplify polygons or lines
-   `ms_clip` - clip an area out of a layer using a polygon layer or a bounding box. Works on polygons, lines, and points
-   `ms_erase` - erase an area from a layer using a polygon layer or a bounding box. Works on polygons, lines, and points
-   `ms_dissolve` - aggregate polygon features, optionally specifying a field to aggregate on. If no field is specified, will merge all polygons into one.
-   `ms_explode` - convert multipart shapes to single part. Works with polygons, lines, and points in geojson format, but currently only with polygons and lines in the `Spatial` classes (not `SpatialMultiPoints` and `SpatialMultiPointsDataFrame`).
-   `ms_lines` - convert polygons to topological boundaries (lines)
-   `ms_innerlines` - convert polygons to shared inner boundaries (lines)
-   `ms_points` - create points from a polygon layer
-   `ms_filter_fields` - Remove fields from the attributes
-   `ms_filter_islands` - Remove small detached polygons

If you run into any bugs or have any feature requests, please file an [issue](https://github.com/ateucher/rmapshaper/issues/)

### Installation

`rmapshaper` is on CRAN. Install the current version with:

``` r
install.packages("rmapshaper")
```

You can install the development version from github with `devtools`:

``` r
## install.packages("devtools")
library(devtools)
install_github("ropensci/geojsonio")
install_github("ateucher/rmapshaper")
```

### Usage

rmapshaper works with geojson strings (character objects of class `geo_json`) and `list` geojson objects of class `geo_list`. These classes are defined in the `geojsonio` package. It also works with `Spatial` classes from the `sp` package.

We will use the `states` dataset from the `geojsonio` package and first turn it into a `geo_json` object:

``` r
library(geojsonio)
#> 
#> We recommend using rgdal v1.1-1 or greater, but we don't require it
#> rgdal::writeOGR in previous versions didn't write
#> multipolygon objects to geojson correctly.
#> See https://stat.ethz.ch/pipermail/r-sig-geo/2015-October/023609.html
#> 
#> Attaching package: 'geojsonio'
#> The following object is masked from 'package:base':
#> 
#>     pretty
library(rmapshaper)
library(sp)

## First convert to json
states_json <- geojson_json(states, geometry = "polygon", group = "group")
#> Assuming 'long' and 'lat' are longitude and latitude, respectively

## For ease of illustration via plotting, we will convert to a `SpatialPolygonsDataFrame`:
states_sp <- geojson_sp(states_json)

## Plot the original
plot(states_sp)
```

![](fig/README-unnamed-chunk-2-1.png)

``` r

## Now simplify using default parameters, then plot the simplified states
states_simp <- ms_simplify(states_sp)
plot(states_simp)
```

![](fig/README-unnamed-chunk-2-2.png)

You can see that even at very high levels of simplification, the mapshaper simplification algorithm preserves the topology, including shared boudaries:

``` r
states_very_simp <- ms_simplify(states_sp, keep = 0.001)
plot(states_very_simp)
```

![](fig/README-unnamed-chunk-3-1.png)

Compare this to the output using `rgeos::gSimplify`, where overlaps and gaps are evident:

``` r
library(rgeos)
#> rgeos version: 0.3-19, (SVN revision 524)
#>  GEOS runtime version: 3.5.0-CAPI-1.9.0 r4084 
#>  Linking to sp version: 1.2-3 
#>  Polygon checking: TRUE
states_gsimp <- gSimplify(states_sp, tol = 1, topologyPreserve = TRUE)
plot(states_gsimp)
```

![](fig/README-unnamed-chunk-4-1.png)

All of the functions are quite fast with `geo_json` character objects and `geo_list` list objects. They are slower with the `Spatial` classes due to internal conversion to/from json. If you are going to do multiple operations on large `Spatial` objects, it's recommended to first convert to json using `geojson_list` or `geojson_json` from the `geojsonio` package. All of the functions have the input object as the first argument, and return the same class of object as the input. As such, they can be chained together. For a totally contrived example, using `states_sp` as created above:

``` r
library(geojsonio)
library(rmapshaper)
library(sp)
library(magrittr)

## First convert 'states' dataframe from geojsonio pkg to json
states_json <- geojson_json(states, lat = "lat", lon = "long", group = "group", 
                            geometry = "polygon")

states_json %>% 
  ms_erase(bbox = c(-107, 36, -101, 42)) %>% # Cut a big hole in the middle
  ms_dissolve() %>% # Dissolve state borders
  ms_simplify(keep_shapes = TRUE, explode = TRUE) %>% # Simplify polygon
  geojson_sp() %>% # Convert to SpatialPolygonsDataFrame
  plot(col = "blue") # plot
```

![](fig/README-unnamed-chunk-5-1.png)

### Thanks

This package uses the [V8](https://cran.r-project.org/package=V8) package to provide an environment in which to run mapshaper's javascript code in R. It relies heavily on all of the great spatial packages that already exist (especially `sp` and `rgdal`), the `geojsonio` package for converting between geo\_list, geo\_json, and `sp` objects, and the `jsonlite` package for converting between json strings and R objects.

Thanks to [timelyportfolio](https://github.com/timelyportfolio) for helping me wrangle the javascript to the point where it works in V8. He also wrote the [mapshaper htmlwidget](https://github.com/timelyportfolio/mapshaper_htmlwidget), which provides access to the mapshaper web inteface, right in your R session. We have plans to combine the two in the future.

### Code of Conduct

Please note that this project is released with a [Contributor Code of Conduct](CONDUCT.md). By participating in this project you agree to abide by its terms.

### LICENSE

MIT
