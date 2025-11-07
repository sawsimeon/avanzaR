#' Place an order (market or limit)
#'
#' Place a buy or sell order on Avanza. This function maps to the Avanza order
#' placement endpoint. Use with extreme caution — orders placed through this
#' package may be real and result in trades.
#'
#' @param session An `AvanzaSession` object returned by `avanza_auth()` / `avanza_session()`.
#' @param account_id Character, account id to place the order in.
#' @param order_book_id Character, the instrument / orderbook id (e.g. ISIN or id string).
#' @param type Character, either `\"BUY\"` or `\"SELL\"`.
#' @param price Numeric or NULL. If NULL, a market order will be placed.
#' @param volume Integer, number of shares / units to trade.
#' @param valid_until Character or NULL, date string (\"YYYY-MM-DD\") indicating validity. NULL means day-only.
#' @return A list with at least `orderId` and `status` (as in README). This function may throw on HTTP errors.
#' @examples
#' \dontrun{
#' session <- avanza_auth(\"my_user\", \"my_password\", \"JBSWY3DPEHPK3PXP\")
#' order_result <- avanza_order(
#'   session      = session,
#'   account_id   = \"12345678\",
#'   order_book_id = \"199694\",
#'   type         = \"BUY\",
#'   price        = NULL,
#'   volume       = 10,
#'   valid_until  = NULL
#' )
#' }
#' @export
avanza_order <- function(session, account_id, order_book_id, type = c(\"BUY\", \"SELL\"), price = NULL, volume = 1L, valid_until = NULL) {
  stopifnot(inherits(session, \"AvanzaSession\"))
  type <- match.arg(toupper(type), c(\"BUY\", \"SELL\"))

  body <- list(
    accountId = as.character(account_id),
    orderBookId = as.character(order_book_id),
    direction = type,
    volume = as.integer(volume)
  )

  if (!is.null(price)) {
    body$price <- as.numeric(price)
    body$orderType <- \"LIMIT\"
  } else {
    body$orderType <- \"MARKET\"
  }

  if (!is.null(valid_until)) {
    body$validUntil <- as.character(valid_until)
  }

  parsed <- tryCatch(
    avanza_request(session = session, method = \"POST\", path = \"order/place\", body = body),
    error = function(e) rlang::abort(sprintf(\"Order request failed: %s\", conditionMessage(e)))
  )

  # Normalize response
  order_id <- parsed$orderId %||% parsed$id %||% parsed$order_id %||% NA_character_
  status <- parsed$status %||% parsed$result %||% parsed$state %||% NA_character_

  list(orderId = as.character(order_id), status = as.character(status))
}
