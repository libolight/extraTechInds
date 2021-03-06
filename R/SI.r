#
#   extraTechInds: extra Technical Indicators of TTR and quantmod
#
#   Copyright (C) 2016  Chen Chaozong
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

#'Stochastic Index
#'
#'@aliases SI
#'@param HLC Object that is coercible to xts or matrix and contains
#'High-Low-Close prices.
#'@param nFastK Number of periods for moving average.
#'@param nFastD ...
#'@param nSlowD ...
#'@param maType A function or a string naming the function to be called.
#'@param bounded ...
#'@param smooth ...
#'@param \dots Other arguments to be passed to the \code{maType} function.
#'@author Chen Chaozong
#'@seealso See \code{\link{EMA}}, \code{\link{SMA}}, etc. for moving average
#'options; and note Warning section.  See \code{\link{ATR}}, which uses true
#'range.  See \code{\link{chaikinVolatility}} for another volatility measure.
#'@keywords ts
#'@export
"SI" <-
function (HLC, nFastK = 14, nFastD = 3, nSlowD = 3, maType, bounded = TRUE, smooth = 1, ...) {
  HLC <- try.xts(HLC, error = as.matrix)
  if (NCOL(HLC) == 3) {
    high <- Hi(HLC)
    low  <- Lo(HLC)
    close<- Cl(HLC)
  }
  else if (NCOL(HLC) == 1) {
    high  <- HLC
    low   <- HLC
    close <- HLC
  }
  else stop("Price series must be either High-Low-Close, or Close")
  if (bounded) {
    hmax <- runMax(high, nFastK)
    lmin <- runMin(low, nFastK)
  }
  else {
    hmax <- runMax(c(high[1], high[-NROW(HLC)]), nFastK)
    lmin <- runMax(c(low[1], low[-NROW(HLC)]), nFastK)
  }
  num <- close - lmin
  den <- hmax - lmin
  if (missing(maType)) {
    maType <- "EMA"
  }
  if (is.list(maType)) {
    maTypeInfo <- sapply(maType, is.list)
    if (!(all(maTypeInfo) && length(maTypeInfo) == 3)) {
      stop("If 'maType' is a list, you must specify\n ",
           "*three* MAs (see Examples section of ?stochastics)")
    }
    if (!is.null(formals(maType[[1]][[1]])$n) && is.null(maType[[1]]$n)) {
      maType[[1]]$n <- nFastD
    }
    if (!is.null(formals(maType[[2]][[1]])$n) && is.null(maType[[2]]$n)) {
      maType[[2]]$n <- nSlowD
    }
    if (!is.null(formals(maType[[3]][[1]])$n) && is.null(maType[[3]]$n)) {
      maType[[3]]$n <- smooth
    }
    numMA <- do.call(maType[[3]][[1]], c(list(num), maType[[3]][-1]))
    denMA <- do.call(maType[[3]][[1]], c(list(den), maType[[3]][-1]))
    fastK <- numMA/denMA
    fastK[is.nan(fastK)] <- 0.5
    fastD <- do.call(maType[[1]][[1]], c(list(fastK), maType[[1]][-1]))
    slowD <- do.call(maType[[2]][[1]], c(list(fastD), maType[[2]][-1]))
  }
  else {
    numMA <- do.call(maType, c(list(num), list(n = smooth)))
    denMA <- do.call(maType, c(list(den), list(n = smooth)))
    fastK <- numMA/denMA
    fastK[is.nan(fastK)] <- 0.5
    fastD <- do.call(maType, c(list(fastK), list(n = nFastD, ...)))
    slowD <- do.call(maType, c(list(fastD), list(n = nSlowD, ...)))
  }
  result <- cbind(fastK, fastD, slowD)
  colnames(result) <- c("fastK", "fastD", "slowD")
  reclass(result, HLC)
}
