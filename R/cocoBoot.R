#' @title Bootstrap Based Model Assessment Procedure
#' @description Model checking procedure emphasising reproducibility in fitted models, as proposed by Tsay (1992).
#' @param coco An object of class coco
#' @param numb.lags Number of lags for which to compute sample autocorrelations (default: 21).
#' @param rep.Bootstrap Number of bootstrap replicates to use (default: 1000)
#' @param conf.alpha \eqn{100(1-\code{conf.alpha})\%} probability interval for the acceptance envelopes (default: 0.05)
#' @param julia  if TRUE, the bootstrap is run with \proglang{julia} (default: FALSE)
#' @param julia_seed Seed for the \proglang{julia} implementation. Only used if \proglang{julia} equals TRUE
#' @return an object of class cocoBoot. It contains the bootstrapped confidence intervals
#' of the autocorrelations and information on the model specifications.
#' @details Bootstrap-generated acceptance envelopes for the autocorrelation function provides an overall evaluation by comparing it with the sample autocorrelation function in a joint plot. 
#' @importFrom forecast Acf
#' @importFrom matrixStats rowQuantiles
#' @references 
#' Tsay, R. S. (1992) Model checking via parametric bootstraps in time series analysis. \emph{Applied Statistics} \bold{41}, 1--15.
#' @examples
#' lambda <- 1
#' alpha <- 0.4
#' set.seed(12345)
#' data <- cocoSim(order = 1, type = "Poisson", par = c(lambda, alpha), length = 100)
#' fit <- cocoReg(order = 1, type = "Poisson", data = data)
#'
#' # bootstrap model assessment - R implementation
#' boot_r <- cocoBoot(fit, rep.Bootstrap=400)
#' plot(boot_r)
#' @export

cocoBoot <- function(coco, numb.lags = 21, rep.Bootstrap = 1000,
                 conf.alpha = 0.05, julia = FALSE, julia_seed = NULL
                 ) {
  start.time <- Sys.time()
  confidence <- 1 - conf.alpha
  if ((confidence <= 0) | (confidence >= 1)) {
    stop("Option confidence must be a real number between 0 and 1")
  }

  if ((numb.lags != round(numb.lags)) | (numb.lags < 1)) {
    stop("The value of numb.lags must be a positive integer")
  }

  if ((rep.Bootstrap != round(rep.Bootstrap)) | (rep.Bootstrap < 1)) {
    stop("The value of rep.Bootstrap must be a positive integer")
  }
  
  data <- coco$ts
  
  if (!is.null(coco$julia_reg) & julia){
    if (!is.null(julia_seed)){
      setJuliaSeed(julia_seed)
    }
    addJuliaFunctions()
    coco_boot <- JuliaConnectoR::juliaGet( JuliaConnectoR::juliaCall("cocoBoot", coco$julia_reg, 1:numb.lags, rep.Bootstrap, 1-confidence))
    #acfdata <- coco_boot$values[[2]]
    ac <- t(coco_boot$values[[1]]) 
    #confidence_bands <- data.frame(cbind(coco_boot$values[[3]], coco_boot$values[[4]]))
    #colnames(confidence_bands) <- c("upper", "lower")
  } else {
    
    seasonality <- c(1,2) #will be used as argument in future versions
  
    conf.alpha <- 1 - confidence
    
    if ( is.null(coco$cov) ) {
      if ((coco$type == "GP") & (coco$order == 2)) {
        par <- coco$par
        lambda <- par[1]
        alpha1 <- par[2]
        alpha2 <- par[3]
        alpha3 <- par[4]
        eta <- par[5]
        U <- 1 / (1 - alpha1 - alpha2 - alpha3)
        xreg <- NULL
      }
  
      if ((coco$type == "Poisson") & (coco$order == 2)) {
        par <- coco$par
        lambda <- par[1]
        alpha1 <- par[2]
        alpha2 <- par[3]
        alpha3 <- par[4]
        U <- 1 / (1 - alpha1 - alpha2 - alpha3)
        xreg <- NULL
      }
  
      if ((coco$type == "GP") & (coco$order == 1)) {
        par <- coco$par
        lambda <- par[1]
        alpha <- par[2]
        eta <- par[3]
        xreg <- NULL
      }
  
      if ((coco$type == "Poisson") & (coco$order == 1)) {
        par <- coco$par
        lambda <- par[1]
        alpha <- par[2]
        xreg <- NULL
      }
    }
  
  
    if ( !is.null(coco$cov) )  {
      if ((coco$type == "Poisson") & (coco$order == 1)) {
        par <- coco$par
        alpha <- par[1]
  
        vec_lambda <- par[-(1)]
        xreg <- coco$cov
        data <- coco$ts
  
        # set up values for lambda
        lambda <- c()
        for (j in 1:length(data)) {
          lambda[j] <- applyLinkFunction(as.numeric(as.vector(xreg[j, ])) %*% vec_lambda, coco$link_function)
        }
      }
  
      if ((coco$type == "GP") & (coco$order == 1)) {
        par <- coco$par
        alpha <- par[1]
        eta <- par[2]
        vec_lambda <- par[-(1:2)]
        xreg <- coco$cov
        data <- coco$ts
  
        lambda <- c()
        for (j in 1:length(data)) {
          lambda[j] <- applyLinkFunction(as.numeric(as.vector(xreg[j, ])) %*% vec_lambda, coco$link_function)
        }
      }
  
      if ((coco$type == "Poisson") & (coco$order == 2)) {
        par <- coco$par
        alpha1 <- par[1]
        alpha2 <- par[2]
        alpha3 <- par[3]
        vec_lambda <- par[-(1:3)]
        xreg <- coco$cov
        data <- coco$ts
        U <- 1 / (1 - alpha1 - alpha2 - alpha3)
  
        lambda <- c()
        for (j in 1:length(data)) {
          lambda[j] <- applyLinkFunction(as.numeric(as.vector(xreg[j, ])) %*% vec_lambda, coco$link_function)
        }
      }
  
      if ((coco$type == "GP") & (coco$order == 2)) {
        par <- coco$par
        alpha1 <- par[1]
        alpha2 <- par[2]
        alpha3 <- par[3]
        eta <- par[4]
  
        vec_lambda <- par[-(1:4)]
        xreg <- coco$cov
        data <- coco$ts
        U <- 1 / (1 - alpha1 - alpha2 - alpha3)
  
        lambda <- c()
        for (j in 1:length(data)) {
          lambda[j] <- applyLinkFunction(as.numeric(as.vector(xreg[j, ])) %*% vec_lambda, coco$link_function)
        }
      }
    }
  
  
    # Parametric Bootstrap
    T <- length(data)
    nlags <- numb.lags
    nB <- rep.Bootstrap
    B <- matrix(NaN, nrow = T, ncol = nB)
    ac <- matrix(NaN, nrow = nlags, ncol = nB)
    conf <- conf.alpha
  
    if ((is.null(coco$cov)) ) {
      for (b in 1:nB) {
        help <- cocoSim(order = coco$order, type = coco$type, par = par, length = (T + 10))[11:(T + 10)]
        B[, b] <- help
        ac[, b] <- forecast::Acf(help, plot = FALSE, lag.max = nlags)$acf[2:(nlags + 1)]
      }
    }
  
  
    if (!is.null(coco$cov)) {
      xreg <- as.matrix(xreg)
      for (b in 1:nB) {
        help <- cocoSim(type = coco$type, order = coco$order, par = par, length = T, xreg = xreg, link_function=coco$link_function)
        B[, b] <- help
        ac[, b] <- forecast::Acf(help, plot = FALSE, lag.max = nlags)$acf[2:(nlags + 1)]
      }
    }
  

  } #end julia
  acfdata <- forecast::Acf(data, plot = FALSE, lag.max = numb.lags)$acf[2:(numb.lags + 1)]
  confidence_bands <- data.frame(matrixStats::rowQuantiles(ac, probs = c((1-confidence)/2, 1-(1-confidence)/2)))
  df_plot <- cbind(acfdata, 1:numb.lags, confidence_bands)
  colnames(df_plot) <- c("y", "x", "lower", "upper")
  

  end.time <- Sys.time()
  time <- end.time - start.time
  list_out <- list(
    "type" = coco$type, "order" = coco$order, "ts" = coco$ts, "cov" = coco$cov, means = acfdata,
    "confidence" = confidence_bands, "duration" = time, "df_plot" = df_plot
  )
  class(list_out) <- "cocoBoot"
  return(list_out)
} # end function
