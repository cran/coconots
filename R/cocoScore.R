#' @title Scoring Rule Based Model Assessment Procedure
#' @description The function calculates the log, quadratic and ranked probability scores for assessing relative performance of a fitted model as proposed by Czado et al. (2009).
#' @param coco An object of class coco
#' @param val.num A non-negative real number which is used to stop the calculation
#'  of the score in case of GP models. The default value is 1e-10
#' @param julia if TRUE, the scores are computed with Julia.
#' @return a list containing the log score, quadratic score and ranked probability score.
#' @details Scoring rules assign a numerical score based on the predictive
#'  distribution and the observed data  to measure the quality of probabilistic predictions.
#' They are provided here as a model selection tool and are computed as
#'  averages over the relevant set of (in-sample) predictions. Scoring rules are, generally, negatively oriented
#' penalties that one seeks to minimize. The literature has developed a large number of scoring
#' rules and, unless there is a unique and clearly defined underlying decision problem,
#' there is no automatic choice of a (proper) scoring rule to be used in any given situation.
#' Therefore, the use of a variety of scoring rules may be appropriate to take advantage of
#' specific emphases and strengths. Three proper scoring rules
#' (for a definition of the concept of propriety see Gneiting and Raftery, 2007)
#' which Jung, McCabe and Tremayne (2016) found to be particularly useful are implemented.
#' For more information see the references listed below.
#' @references 
#' Czado, C. and Gneitling, T. and Held, L. (2009) Predictive Model Assessment for Count Data. \emph{Biometrics}, \bold{65}, 4, 1254--1261.
#'
#' Gneiting, T. and Raftery, A. E. (2007) Strictly proper scoring rules, prediction, and estimation. \emph{Journal
#' of the American Statistical Association}, 102:359-378.
#'
#' Jung, Robert C., Brendan P. M. McCabe, and Andrew R. Tremayne. (2016). Model validation and diagnostics. \emph{In Handbook of Discrete
#' Valued Time Series}. Edited by Richard A. Davis, Scott H. Holan, Robert Lund and Nalini Ravishanker. Boca Raton: Chapman and
#' Hall, pp. 189--218.
#'
#' Jung, R. C. and Tremayne, A. R. (2011) Convolution-closed models for count timeseries with applications. \emph{Journal of Time Series Analysis}, \bold{32}, 3, 268--280.
#' @author Manuel Huth
#' @examples
#' lambda <- 1
#' alpha <- 0.4
#' set.seed(12345)
#' data <- cocoSim(order = 1, type = "Poisson", par = c(lambda, alpha), length = 100)
#' #julia_installed = TRUE ensures that the fit object
#' #is compatible with the julia cocoScore implementation 
#' fit <- cocoReg(order = 1, type = "Poisson", data = data)
#'
#' #assessment using scoring rules - R implementation
#' score_r <- cocoScore(fit)
#' @export

cocoScore <- function(coco, val.num = 1e-10, julia=FALSE) {
  
  
  if (!is.null(coco$julia_reg) & julia){
    addJuliaFunctions()
    coco_score <- JuliaConnectoR::juliaGet( JuliaConnectoR::juliaCall("compute_scores", coco$julia_reg))
    return(list("log.score" = coco_score$values[[1]], "quad.score" = coco_score$values[[2]],
                 "rps.score" = coco_score$values[[3]],
                "aic" = 2*length(coco$par) - 2 * coco$likelihood,
                "bic" = length(coco$par) * log(length(coco$ts)) - 2 * coco$likelihood))
  } else {
  T <- length(coco$ts)
  par <- coco$par
  seas <- c(1, 2) #will be used as argument in future versions
  data <- coco$ts

  if ( is.null(coco$cov) ){


  #Poisson 1
  if ( (coco$type == "Poisson") & (coco$order == 1) ){
    par <- c(par, 0)
    log.score <- 0
    quad.score <- 0
    rps.score <- 0

    for (t in (seas[1]+1):T) {
      #log score
      log.score <- log.score - log(dGP1(data[t], data[t-seas[1]], par))

      #quadratic score
      norm.p <- 0
      help.stop <- 0

      j <- 0
      while (help.stop < (1-val.num) )  {
        help <- dGP1(j,data[t-seas[1]], par)
        help.stop <- pGP1(j,data[t-seas[1]], par)
        norm.p <- norm.p + help^2
        j <- j+1
      }
      quad.score <- quad.score - 2 * dGP1(data[t], data[t-seas[1]], par) + norm.p

      #ranked probability score
      sum <- 0
      help <- 0
      j <- 0
      while (help < (1-val.num) ){
        ind <- 0
        if (j >= data[t]) {
          ind <- 1
        }
        help <- pGP1(j, data[t-seas[1]], par)
        sum <- sum + (help - ind)^2
        j <- j + 1
      }
      rps.score <- rps.score + sum
    }# end t

    log.score <- log.score / (T-seas[1])
    quad.score <- quad.score / (T-seas[1])
    rps.score <- rps.score / (T-seas[1])

  }# Poisson 1


  #GP1
  if ( (coco$type == "GP") & (coco$order == 1) ){

    log.score <- 0
    quad.score <- 0
    rps.score <- 0

    for (t in (seas[1]+1):T) {
      #log score
      log.score <- log.score -log(dGP1(data[t], data[t-seas[1]], par))

      #quadratic score
      norm.p <- 0
      help.stop <- 0

      j <- 0
      while (help.stop < (1-val.num) )  {
        help <- dGP1(j,data[t-seas[1]], par)
        help.stop <- pGP1(j,data[t-seas[1]], par)
        norm.p <- norm.p + help^2
        j <- j+1
      }
      quad.score <- quad.score - 2* dGP1(data[t], data[t-seas[1]], par) + norm.p

      #ranked probability score
      sum <- 0
      help <- 0
      j <- 0
      while (help < (1-val.num) ){
        ind <- 0
        if (j >= data[t]) {
          ind <- 1
        }
        help <- pGP1(j, data[t-seas[1]], par)
        sum <- sum + (help - ind)^2
        j <- j + 1
      }
      rps.score <- rps.score + sum
  }# end t
    log.score <- log.score / (T-seas[1])
    quad.score <- quad.score / (T-seas[1])
    rps.score <- rps.score / (T-seas[1])
  }# GP1

  #Poisson 2
  if ( (coco$type == "Poisson") & (coco$order == 2) ){
    par <- c(par, 0)
    log.score <- 0
    quad.score <- 0
    rps.score <- 0

    for (t in (seas[2]+1):T) {
      #log score
      log.score <- log.score -log(dGP2(data[t], data[t-seas[1]], data[t-seas[2]], par))

      #quadratic score
      norm.p <- 0
      help.stop <- 0

      j <- 0
      while (help.stop < (1-val.num) )  {
        help <- dGP2(j,data[t-seas[1]], data[t-seas[2]], par)
        help.stop <- pGP2(j,data[t-seas[1]], data[t-seas[2]], par)
        norm.p <- norm.p + help^2
        j <- j+1
      }
      quad.score <- quad.score - 2* dGP2(data[t], data[t-seas[1]], data[t-seas[2]], par) + norm.p

      #ranked probability score
      sum <- 0
      help <- 0
      j <- 0
      while (help < (1-val.num) ){
        ind <- 0
        if (j >= data[t]) {
          ind <- 1
        }
        help <- pGP2(j, data[t-seas[1]],data[t-seas[2]], par)
        sum <- sum + (help - ind)^2
        j <- j + 1
      }
      rps.score <- rps.score + sum
    }# end t
    log.score <- log.score / (T-seas[2])
    quad.score <- quad.score / (T-seas[2])
    rps.score <- rps.score / (T-seas[2])
  }# Poisson 2

  #GP2
  if ( (coco$type == "GP") & (coco$order == 2) ){

    log.score <- 0
    quad.score <- 0
    rps.score <- 0

    for (t in (seas[2]+1):T) {
      #log score
      log.score <- log.score -log(dGP2(data[t], data[t-seas[1]], data[t-seas[2]], par))

      #quadratic score
      norm.p <- 0
      help.stop <- 0

      j <- 0
      while (help.stop < (1-val.num) )  {
        help <- dGP2(j,data[t-seas[1]], data[t-seas[2]], par)
        help.stop <- pGP2(j,data[t-seas[1]], data[t-seas[2]], par)
        norm.p <- norm.p + help^2
        j <- j+1
      }
      quad.score <- quad.score - 2* dGP2(data[t], data[t-seas[1]], data[t-seas[2]], par) + norm.p

      #ranked probability score
      sum <- 0
      help <- 0
      j <- 0
      while (help < (1-val.num) ){
        ind <- 0
        if (j >= data[t]) {
          ind <- 1
        }
        help <- pGP2(j, data[t-seas[1]],data[t-seas[2]], par)
        sum <- sum + (help - ind)^2
        j <- j + 1
      }
      rps.score <- rps.score + sum
    }# end t
    log.score <- log.score / (T-seas[2])
    quad.score <- quad.score / (T-seas[2])
    rps.score <- rps.score / (T-seas[2])
  }# GP2

  list_out <- list("log.score" = log.score, "quad.score" = quad.score, "rps.score" = rps.score)
}


##covariates
  if ( !is.null(coco$cov) ){
    xreg <- coco$cov


    #Poisson 1
    if ( (coco$type == "Poisson") & (coco$order == 1) ){
      betas <- par[-c(1)]
      lambdas <- exp(as.matrix(xreg) %*% betas)

      log.score <- 0
      quad.score <- 0
      rps.score <- 0

      for (t in (seas[1]+1):T) {
        #log score
        par <- c(lambdas[t], coco$par[1], 0)
        log.score <- log.score -log(dGP1(data[t], data[t-seas[1]], par))

        #quadratic score
        norm.p <- 0
        help.stop <- 0

        j <- 0
        while (help.stop < (1-val.num) )  {
          help <- dGP1(j,data[t-seas[1]], par)
          help.stop <- pGP1(j,data[t-seas[1]], par)
          norm.p <- norm.p + help^2
          j <- j+1
        }
        quad.score <- quad.score - 2* dGP1(data[t], data[t-seas[1]], par) + norm.p

        #ranked probability score
        sum <- 0
        help <- 0
        j <- 0
        while (help < (1-val.num) ){
          ind <- 0
          if (j >= data[t]) {
            ind <- 1
          }
          help <- pGP1(j, data[t-seas[1]], par)
          sum <- sum + (help - ind)^2
          j <- j + 1
        }
        rps.score <- rps.score + sum
      }# end t
      log.score <- log.score / (T-seas[1])
      quad.score <- quad.score / (T-seas[1])
      rps.score <- rps.score / (T-seas[1])
    }# Poisson 1


    #GP1

    if ( (coco$type == "GP") & (coco$order == 1) ){
      betas <- par[-c(1,2)]
      lambdas <- exp(as.matrix(xreg) %*% betas)
      log.score <- 0
      quad.score <- 0
      rps.score <- 0

      for (t in (seas[1]+1):T) {
        #log score
        par <- c(lambdas[t], coco$par[1], coco$par[2])
        log.score <- log.score -log(dGP1(data[t], data[t-seas[1]], par))

        #quadratic score
        norm.p <- 0
        help.stop <- 0

        j <- 0
        while (help.stop < (1-val.num) )  {

          help <- dGP1(j,data[t-seas[1]], par)
          help.stop <- pGP1(j,data[t-seas[1]], par)
          norm.p <- norm.p + help^2
          j <- j+1
        }
        quad.score <- quad.score - 2 * dGP1(data[t], data[t-seas[1]], par) + norm.p


        #ranked probability score
        sum <- 0
        help <- 0
        j <- 0
        while (help < (1-val.num) ){
          ind <- 0
          if (j >= data[t]) {
            ind <- 1
          }
          help <- pGP1(j, data[t-seas[1]], par)
          sum <- sum + (help - ind)^2
          j <- j + 1
        }
        rps.score <- rps.score + sum
      }# end t
      log.score <- log.score / (T-seas[1])
      quad.score <- quad.score / (T-seas[1])
      rps.score <- rps.score / (T-seas[1])
    }# GP1

    #Poisson 2
    if ( (coco$type == "Poisson") & (coco$order == 2) ){
      betas <- par[-c(1,2,3)]
      lambdas <- exp(as.matrix(xreg) %*% betas)
      log.score <- 0
      quad.score <- 0
      rps.score <- 0

      for (t in (seas[2]+1):T) {
        #log score
        par <- c(lambdas[t], coco$par[1], coco$par[2], coco$par[3], 0)
        log.score <- log.score -log(dGP2(data[t], data[t-seas[1]], data[t-seas[2]], par))

        #quadratic score
        norm.p <- 0
        help.stop <- 0

        j <- 0
        while (help.stop < (1-val.num) )  {
          help <- dGP2(j,data[t-seas[1]], data[t-seas[2]], par)
          help.stop <- pGP2(j,data[t-seas[1]], data[t-seas[2]], par)
          norm.p <- norm.p + help^2
          j <- j+1
        }
        quad.score <- quad.score - 2* dGP2(data[t], data[t-seas[1]], data[t-seas[2]], par) + norm.p

        #ranked probability score
        sum <- 0
        help <- 0
        j <- 0
        while (help < (1-val.num) ){
          ind <- 0
          if (j >= data[t]) {
            ind <- 1
          }
          help <- pGP2(j, data[t-seas[1]],data[t-seas[2]], par)
          sum <- sum + (help - ind)^2
          j <- j + 1
        }
        rps.score <- rps.score + sum
      }# end t
      log.score <- log.score / (T-seas[2])
      quad.score <- quad.score / (T-seas[2])
      rps.score <- rps.score / (T-seas[2])
    }# Poisson 2

    #GP2
    if ( (coco$type == "GP") & (coco$order == 2) ){
      betas <- par[-c(1,2,3,4)]
      lambdas <- exp(as.matrix(xreg) %*% betas)
      log.score <- 0
      quad.score <- 0
      rps.score <- 0

      for (t in (seas[2]+1):T) {
        #log score
        par <- c(lambdas[t], coco$par[1], coco$par[2], coco$par[3], coco$par[4])
        log.score <- log.score - log(dGP2(data[t], data[t-seas[1]], data[t-seas[2]], par))

        #quadratic score
        norm.p <- 0
        help.stop <- 0

        j <- 0
        while (help.stop < (1-val.num) )  {
          help <- dGP2(j,data[t-seas[1]], data[t-seas[2]], par)
          help.stop <- pGP2(j,data[t-seas[1]], data[t-seas[2]], par)
          norm.p <- norm.p + help^2
          j <- j+1
        }
        quad.score <- quad.score - 2* dGP2(data[t], data[t-seas[1]], data[t-seas[2]], par) + norm.p

        #ranked probability score
        sum <- 0
        help <- 0
        j <- 0
        while (help < (1-val.num) ){
          ind <- 0
          if (j >= data[t]) {
            ind <- 1
          }
          help <- pGP2(j, data[t-seas[1]],data[t-seas[2]], par)
          sum <- sum + (help - ind)^2
          j <- j + 1
        }
        rps.score <- rps.score + sum
      }# end t
      log.score <- log.score / (T-seas[2])
      quad.score <- quad.score / (T-seas[2])
      rps.score <- rps.score / (T-seas[2])
    }# GP2

    list_out <- list("log.score" = log.score, "quad.score" = quad.score, "rps.score" = rps.score)
  }
  }#end julia if
  
  list_out["bic"] <- length(coco$par) * log(length(coco$ts)) - 2 * coco$likelihood
  list_out["aic"] <- 2*length(coco$par) - 2 * coco$likelihood
  return(list_out)

}# end function
