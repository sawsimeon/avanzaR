#' Real-time quote for a single instrument
#'
#' Retrieve latest price and basic market data for a single instrument/orderbook.
#' Note: Avanza does not provide an official public API; response shapes may vary.
#'
#' @param session An `AvanzaSession` object.
#' @param id Character, the order book / instrument id (e.g. ISIN or numeric id string).
#' @return A tibble with one row and columns: `last_price`, `change_pct`, `bid`, `ask`,
#'   `volume`, `market_maker`, `highest`, `lowest`.
#' @examples
#' \dontrun{
#' session <- avanza_auth(\"my_user\", \"my_password\", \"JBSWY3DPEHPK3PXP\")
#' quote <- avanza_quote(session, id = \"199694\")
#' }
#' @export
avanza_quote <- function(session, id) {
  stopifnot(inherits(session, "AvanzaSession"))
  if (missing(id) || is.null(id) || !nzchar(as.character(id))) {
    rlang::abort("id (order book / instrument id) must be provided")
  }

  path <- sprintf("market/orderbook/%s/quote", id)

  parsed <- tryCatch(
    avanza_request(session = session, method = "GET", path = path),
    error = function(e) rlang::abort(sprintf("Failed to fetch quote: %s", conditionMessage(e)))
  )

  # Accept multiple response shapes
  q <- parsed$result %||% parsed$data %||% parsed$quote %||% parsed

  last_price <- as.numeric(q$lastPrice %||% q$last_price %||% q$currentPrice %||% NA_real_)
  change_pct <- as.numeric(q$changePercent %||% q$change_pct %||% q$change %||% NA_real_)
  bid <- as.numeric(q$bid %||% q$bestBid %||% NA_real_)
  ask <- as.numeric(q$ask %||% q$bestAsk %||% NA_real_)
  volume <- as.integer(q$volume %||% q$tradedVolume %||% NA_integer_)
  market_maker <- as.character(q$marketMaker %||% q$market_maker %||% "")
  highest <- as.numeric(q$highest %||% q$dayHigh %||% NA_real_)
  lowest <- as.numeric(q$lowest %||% q$dayLow %||% NA_real_)

  dplyr::as_tibble(list(
    last_price = last_price,
    change_pct = change_pct,
    bid = bid,
    ask = ask,
    volume = volume,
    market_maker = market_maker,
    highest = highest,
    lowest = lowest
  ))
}
