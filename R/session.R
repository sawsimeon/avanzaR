#' Avanza Session object
#'
#' Create and inspect an Avanza session. The session stores credentials and
#' cookies required for subsequent API calls. Credentials should be supplied
#' via function parameters or environment variables (AVANZA_USER, AVANZA_PASS,
#' AVANZA_TOTP).
#'
#' @param username Character, Avanza username. If NULL the AVANZA_USER env var is used.
#' @param password Character, Avanza password. If NULL the AVANZA_PASS env var is used.
#' @param totp_secret Character, base32 TOTP secret. If NULL the AVANZA_TOTP env var is used.
#' @return An object of class `AvanzaSession` (S3) containing `username`, `cookies`
#'   and `created` timestamp.
#' @examples
#' \dontrun{
#' session <- avanza_session(username = Sys.getenv(\"AVANZA_USER\"),
#'                           password = Sys.getenv(\"AVANZA_PASS\"),
#'                           totp_secret = Sys.getenv(\"AVANZA_TOTP\"))
#' print(session)
#' }
#' @export
avanza_session <- function(username = NULL, password = NULL, totp_secret = NULL) {
  username <- username %||% Sys.getenv("AVANZA_USER", "")
  password <- password %||% Sys.getenv("AVANZA_PASS", "")
  totp_secret <- totp_secret %||% Sys.getenv("AVANZA_TOTP", "")

  if (identical(username, "") || identical(password, "")) {
    stop("username and password must be provided either as arguments or via AVANZA_USER / AVANZA_PASS environment variables", call. = FALSE)
  }

  session <- list(
    username = username,
    password = password,
    totp_secret = totp_secret,
    cookies = list(),
    created = lubridate::now()
  )
  class(session) <- "AvanzaSession"
  session
}

#' Print AvanzaSession
#'
#' @param x AvanzaSession object
#' @param ... Additional args (ignored)
#' @export
print.AvanzaSession <- function(x, ...) {
  cat("<AvanzaSession>\n")
  cat("  username: ", x$username, "\n", sep = "")
  cat("  created:  ", format(x$created), "\n", sep = "")
  cat("  cookies:  ", length(x$cookies), " stored\n", sep = "")
  invisible(x)
}

# helper: infix null-or operator
`%||%` <- function(a, b) if (!is.null(a) && !(is.character(a) && a == "")) a else b
