# Internal HTTP helper for avanzaR
#'
#' Low-level request helper that performs HTTP requests against the Avanza API.
#' This is kept internal so tests can stub `avanza_request()` easily.
#'
#' @param session AvanzaSession created by `avanza_session()` or `avanza_auth()`.
#' @param method Character, HTTP method (\"GET\", \"POST\", \"PUT\", \"DELETE\").
#' @param path Character, path appended to the base API URL (leading slash optional).
#' @param query Named list of query parameters.
#' @param body R object to be encoded as JSON body.
#' @return Parsed JSON (list) on success.
#' @keywords internal
avanza_request <- function(session, method = c(\"GET\", \"POST\", \"PUT\", \"DELETE\"), path, query = NULL, body = NULL) {
  stopifnot(inherits(session, \"AvanzaSession\"))

  method <- match.arg(toupper(method), c(\"GET\", \"POST\", \"PUT\", \"DELETE\"))
  base_url <- \"https://www.avanza.se/_api\"
  path <- sub(\"^/+\", \"\", path)
  url <- file.path(base_url, path)

  # Build httr2 request
  req <- httr2::request(url)
  # headers commonly required
  req <- httr2::req_headers(req,
                           `User-Agent` = \"avanzaR/0.1.0 (https://github.com/sawsimeon/avanzaR)\",
                           Accept = \"application/json, text/plain, */*\",
                           `Content-Type` = \"application/json\")
  # Attach cookies if present
  if (length(session$cookies) > 0) {
    cookie_header <- paste(vapply(names(session$cookies), function(n) sprintf(\"%s=%s\", n, session$cookies[[n]]), FUN.VALUE = \"\"), collapse = \"; \")
    if (nzchar(cookie_header)) {
      req <- httr2::req_headers(req, Cookie = cookie_header)
    }
  }

  # Query
  if (!is.null(query)) {
    req <- httr2::req_url(req, params = query)
  }

  # Body
  if (!is.null(body)) {
    req <- httr2::req_body_json(req, body = body)
  }

  # Method dispatch
  req <- switch(method,
                \"GET\" = req,
                \"POST\" = httr2::req_method(req, \"POST\"),
                \"PUT\" = httr2::req_method(req, \"PUT\"),
                \"DELETE\" = httr2::req_method(req, \"DELETE\")
  )

  # Simple rate limiting to be kind to the API
  Sys.sleep(0.08)

  # Perform and parse
  resp <- tryCatch(
    httr2::req_perform(req),
    error = function(e) {
      rlang::abort(sprintf(\"HTTP request failed: %s\", conditionMessage(e)))
    }
  )

  # Check status
  httr2::resp_check_status(resp)

  parsed <- tryCatch(
    httr2::resp_body_json(resp, simplifyVector = TRUE),
    error = function(e) {
      rlang::abort(\"Failed to parse JSON response from Avanza API\")
    }
  )

  parsed
}
