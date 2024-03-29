\name{coconots-package}
\alias{Concolution-closed Models for Count Time Series}
\alias{coconots-package}
\docType{package}
\title{
  Concolution-closed Models for Time Series
}
\description{
  Functions to analyse time series consisting of low counts are provided. The 
  focus in the current version is on practical models that can  capture first 
  and higher-order dependence based on the work of Joe (1996). Both equidispersed 
  and overdispersed marginal distributions of data can be modelled. Regression 
  effects can be included. Fast and efficient procedures for likelihood based 
  inference and probabilistic forecasting are provided as well as useful tools 
  for model validation and diagnostics. 
}
\details{
The package allows simulation of convolution-closed count time series models with the \code{\link{cocoSim}}
function. Model fitting is performed with the \code{\link{cocoReg}} routine. By passing a cocoReg-type object,
the S3 method \code{predict} computes the one-step ahead forecasting distribution. \code{\link{cocoBoot}}, \code{\link{cocoPit}},
\code{\link{cocoScore}}, and \code{\link{cocoResid}} provide routines for model assessment.
The main usage of the package is illustrated within the cocoReg function chapter. For more details
and examples of the functions see the respective sections within this vignette. 

By default, our functions make use of an RCPP implementation. However, users
with a running Julia installation can choose to call Julia in the background
to run their functions by specifiying it in the R function input. This option
is particularly useful for the regression (\code{\link{cocoReg}}), where a complex likelihood function
must be numerically evaluated to obtain parameter estimates. By leveraging
Julia's automatic differentiation capabilities,
our functions can take advantage of numerical gradients,
leading to increased numerical stability and faster convergence.

As we find both, the Julia and RCPP
implementations produce qualitatively similar results in all our tests, we have decided to use the RCPP implementation as
the default option to make our package accessible to non-Julia users.
}
\author{
Maintainer: Manuel Huth <manuel.huth@yahoo.com>
}
\references{
Czado, C., Gneiting, T. and Held, L. (2009) Predictive model assessment for count data. \emph{Biometrics} \bold{65}, 1254--61.

Gneiting, T. and Raftery, A. E. (2007) Strictly proper scoring rules, prediction, and estimation. \emph{Journal
of the American Statistical Association}, 102:359-378.

R.C. Jung, A.R. Tremayne (2006) Coherent forecasting in integer time series models. 
  \emph{International Journal of Forecasting} \bold{22}, 223--238
  
Jung, R. C. and Tremayne, A. R. (2011) Convolution-closed models for count time series with applications. \emph{Journal of Time Series Analysis}, \bold{32}, 3, 268--280.

Jung, Robert C., Brendan P. M. McCabe, and Andrew R. Tremayne. (2016). Model validation and diagnostics. \emph{In Handbook of Discrete
Valued Time Series}. Edited by Richard A. Davis, Scott H. Holan, Robert Lund and Nalini Ravishanker. Boca Raton: Chapman and
Hall, pp. 189--218.

Joe, H. (1996) Time series models with univariate margins in the convolution-closed infinitely divisible class. \emph{Journal of Applied Probability}, 664--677.

Tsay, R. S. (1992) Model checking via parametric bootstraps in time series analysis. \emph{Applied Statistics} \bold{41}, 1--15.

Westgren, A. (1916) Die Veraenderungsgeschwindigkeit der lokalen
Teilchenkonzentration in kollioden Systemen (Erste Mitteilung).
\emph{Arkiv foer Matematik, Astronomi och Fysik}, \bold{11}, 1--24.

}
