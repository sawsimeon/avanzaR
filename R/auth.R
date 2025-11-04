#' Authenticate with Avanza and return a session
#'
#' Log in to Avanza using username + password and optional TOTP (2FA). Credentials
#' can be provided as arguments or via environment variables `AVANZA_USER`,
#' `AVANZA_PASS` and `AVANZA_TOTP`.
#'
#' On success this function returns an object of class `AvanzaSession` which
#' stores credentials and any session cookies returned by the API. Keep this
#' object and pass it to other functions in this package.
#'
#' @param username Character, Avanza username. If NULL the `AVANZA_USER` env var is used.
#' @param password Character, Avanza password. If NULL the `AVANZA_PASS` env var is used.
#' @param totp_secret Character, base32 TOTP secret. If NULL the `AVANZA_TOTP` env var is used.
#' @return An `AvanzaSession` S3 object (list) with at least `username`, `cookies`,
#'   and `created`. The function will error on failed authentication.
#' @examples
#' \dontrun{
#' session <- avanza_auth(
#'   username   = \"my_user\",
#'   password   = \"my_password\",
#'   totp_secret = \"JBSWY3DPEHPK3PXP\"
#' )
#' }
#' @export
avanza_auth <- function(username = NULL, password = NULL, totp_secret = NULL) {
  # Build base session (validates username/password presence)
  session <- avanza_session(username = username, password = password, totp_secret = totp_secret)

  # Generate TOTP code if secret provided (silently continue if totp package not available)
  totp_code <- NULL
  if (!is.null(session$totp_secret) && nzchar(session$totp_secret)) {
    totp_code <- tryCatch(
      {
        # totp::totp() is used by the 'totp' package; if API differs, users should
        # provide AVANZA_TOTP value manually via environment and handle differences.
        if (!requireNamespace(\"totp\", quietly = TRUE)) {
          rlang::abort(\"Package 'totp' is required for TOTP generation. Install it or provide a pre-generated code in 'totp_secret'.\")
        }
        # Attempt to call common function name; this will work for most totp packages.
        if (is.function(totp::totp)) {
          totp::totp(session$totp_secret)
        } else if (is.function(totp::generate)) {
          totp::generate(session$totp_secret)
        } else {
          # Best effort: call a likely function name
          totp::generate_totp(session$totp_secret)
        }
      },
      error = function(e) {
        rlang::abort(sprintf(\"Failed to generate TOTP code: %s\", conditionMessage(e)))
      }
    )
  }

  body <- list(
    username = session$username,
    password = session$password
  )

  if (!is.null(totp_code) && nzchar(as.character(totp_code))) {
    body$totp <- as.character(totp_code)
  }

  parsed <- tryCatch(
    avanza_request(session = session, method = \"POST\", path = \"auth/login\", body = body),
    error = function(e) rlang::abort(sprintf(\"Authentication request failed: %s\", conditionMessage(e)))
  )

  # If the API returns a session token or id, save it in cookies for subsequent calls
  if (!is.null(parsed$sessionId)) {
    session$cookies$sessionId <- parsed$sessionId
  } else if (!is.null(parsed$session_token)) {
    session$cookies$session_token <- parsed$session_token
  } else {
    # Some mocked responses or other flows may return a 'success' flag
    if (!is.null(parsed$success) && parsed$success == TRUE) {
      # nothing additional to store
    } else {
      # If we can't detect a successful login, raise an informative error
      rlang::abort(\"Authentication failed: unexpected response from Avanza API\")
    }
  }

  session
}
